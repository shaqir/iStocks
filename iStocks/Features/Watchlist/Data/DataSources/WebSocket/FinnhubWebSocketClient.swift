//
//  FinnhubWebSocketClient.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-27.
//

import Foundation
import Combine

// MARK: - Protocol

nonisolated protocol WebSocketClient {
    func connect()
    func disconnect(clearPending: Bool)
    func subscribe(to symbols: [String])
    var stockPublisher: AnyPublisher<StockFinnPriceDTO, Never> { get }
}

// MARK: - Connection State Enum
nonisolated enum WebSocketConnectionState {
    case disconnected, connecting, connected, reconnecting
}

/// NOTE (Swift 6.2): nonisolated because WebSocket client is a Data layer component
/// managing network I/O — should not be MainActor-isolated.
nonisolated final class FinnhubWebSocketClient: NSObject, WebSocketClient {
    
    override init() {
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }

    // MARK: - Properties
    private var apiKey: String {
        SecureAPIKeyManager.finnhubAPIKey
    }
    private var session: URLSession!  // Initialized in init after super.init
    private var webSocketTask: URLSessionWebSocketTask?
    private let stockSubject = PassthroughSubject<StockFinnPriceDTO, Never>()
    var stockPublisher: AnyPublisher<StockFinnPriceDTO, Never> {
        stockSubject.eraseToAnyPublisher()
    }

    private(set) var connectionState: WebSocketConnectionState = .disconnected
    private var heartbeatTimer: Timer?
    private var subscribedSymbols: Set<String> = []
    private var pendingSymbols: Set<String> = []
    private var messageQueue: [URLSessionWebSocketTask.Message] = []
    private var isReadyToSubscribe = false
    private var subscribeRetryAttempts = 0
    private let maxSubscribeRetryAttempts = 5
    private let reconnectManager = ConnectionRetryManager()

    private var url: URL? {
        var components = URLComponents()
        components.scheme = "wss"
        components.host = "ws.finnhub.io"
        components.queryItems = [URLQueryItem(name: "token", value: apiKey)]
        
        guard let url = components.url else {
            AppLogger.error("Invalid WebSocket URL — check API key configuration", category: AppLogger.webSocket)
            return nil
        }
        return url
    }

    // MARK: - State Machine

    /// Enforces valid WebSocket state transitions. Invalid transitions are logged
    /// and trigger an assertion failure in DEBUG builds.
    ///
    /// Valid transitions:
    /// - disconnected  → connecting
    /// - connecting    → connected | disconnected
    /// - connected     → disconnected | reconnecting
    /// - reconnecting  → connecting | disconnected
    private func transition(to newState: WebSocketConnectionState) {
        let validTransitions: [WebSocketConnectionState: Set<WebSocketConnectionState>] = [
            .disconnected: [.connecting],
            .connecting:   [.connected, .disconnected],
            .connected:    [.disconnected, .reconnecting],
            .reconnecting: [.connecting, .disconnected],
        ]

        guard let allowed = validTransitions[connectionState], allowed.contains(newState) else {
            AppLogger.error(
                "Invalid WebSocket state transition: \(connectionState) → \(newState)",
                category: AppLogger.webSocket
            )
            #if DEBUG
            assertionFailure("Invalid WebSocket state transition: \(connectionState) → \(newState)")
            #endif
            return
        }

        connectionState = newState
    }

    // MARK: - Connection Lifecycle
    func connect() {
        guard connectionState != .connected && connectionState != .connecting else { return }

        guard let url = url else {
            AppLogger.error("Cannot connect: Invalid WebSocket URL", category: AppLogger.webSocket)
            transition(to: .disconnected)
            return
        }

        disconnect(clearPending: false)
        transition(to: .connecting)
        AppLogger.info("Connecting to \(url.absoluteString)", category: AppLogger.webSocket)

        let request = URLRequest(url: url)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        listen()
        startHeartbeat()
    }

    func disconnect(clearPending: Bool = false) {
        heartbeatTimer?.invalidate()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        resetConnectionState(clearPending: clearPending)
    }

    private func resetConnectionState(clearPending: Bool) {
        transition(to: .disconnected)
        isReadyToSubscribe = false
        subscribedSymbols.removeAll()
        messageQueue.removeAll()
        subscribeRetryAttempts = 0
        if clearPending { pendingSymbols.removeAll() }
    }

    private func reconnect() {
        guard connectionState != .reconnecting else { return }
        if reconnectManager.hasReachedMaxAttempts {
            AppLogger.warning("Max reconnect attempts reached", category: AppLogger.webSocket)
            return
        }
        transition(to: .reconnecting)
        reconnectManager.scheduleRetry(taskName: "Finnhub Reconnect") { [weak self] in self?.connect() }
    }

    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: AppConstants.heartbeatIntervalSeconds, repeats: true) { [weak self] _ in
            self?.sendJSON(["type": "heartbeat"])
        }
    }

    // MARK: - Sending Messages
    func send(_ message: URLSessionWebSocketTask.Message) {
        guard connectionState == .connected else {
            guard messageQueue.count < AppConstants.maxWebSocketMessageQueueSize else {
                AppLogger.warning("WebSocket message queue full — applying backpressure, dropping message", category: AppLogger.webSocket)
                return
            }
            messageQueue.append(message)
            return
        }
        webSocketTask?.send(message) { error in
            if let error = error {
                AppLogger.error("Send failed", category: AppLogger.webSocket, error: error)
            }
        }
    }

    private func sendJSON(_ payload: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        send(.data(data))
    }

    // MARK: - Subscriptions
    func subscribe(to symbols: [String]) {
        let newSymbols = Set(symbols).subtracting(subscribedSymbols)
        guard !newSymbols.isEmpty else { return }
        pendingSymbols.formUnion(newSymbols)
        retryConnectIfNeeded(triggeredBy: "subscribe")
        subscribeToPendingSymbolsIfNeeded()
    }

    private func subscribeToPendingSymbolsIfNeeded() {
        guard connectionState == .connected, isReadyToSubscribe, !pendingSymbols.isEmpty else { return }
        for symbol in pendingSymbols {
            sendJSON(["type": "subscribe", "symbol": symbol])
        }
        subscribedSymbols.formUnion(pendingSymbols)
        pendingSymbols.removeAll()
    }

    private func retryConnectIfNeeded(triggeredBy: String) {
        guard connectionState != .connected && connectionState != .connecting else { return }
        reconnect()
    }

    private func flushMessageQueue() {
        messageQueue.forEach { send($0) }
        messageQueue.removeAll()
    }

    // MARK: - Listening
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            defer { self.listen() }

            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self.handleIncoming(data)
                case .string(let text):
                    self.handleIncoming(Data(text.utf8))
                @unknown default:
                    AppLogger.warning("Unknown message format", category: AppLogger.webSocket)
                }
            case .failure(let error):
                AppLogger.error("Receive error", category: AppLogger.webSocket, error: error)
                self.transition(to: .disconnected)
                self.isReadyToSubscribe = false
                self.reconnect()
            }
        }
    }

    private func handleIncoming(_ data: Data) {
        // Debug logging removed - only log errors
        do {
            let message = try JSONDecoder().decode(FinnhubResponseMapper.self, from: data)
            if message.type == "trade", let trades = message.data {
                for trade in trades {
                    let dto = StockFinnPriceDTO(symbol: trade.s, price: trade.p, timestamp: trade.t)
                    stockSubject.send(dto)
                }
            }
        } catch {
            AppLogger.error("JSON decoding failed", category: AppLogger.webSocket, error: error)
        }
    }
}

/// NOTE (Swift 6.2): nonisolated conformance because URLSession delegate callbacks
/// are invoked by URLSession's internal machinery, not from MainActor context.
/// The delegate queue is set to .main in init, so these run on the main thread,
/// but the protocol conformance itself must be nonisolated to satisfy the compiler.
extension FinnhubWebSocketClient: @preconcurrency URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        #if DEBUG
        MainActor.assertIsolated("WebSocket delegate must run on main thread — delegateQueue is .main")
        #endif
        AppLogger.info("Connected", category: AppLogger.webSocket)
        transition(to: .connected)
        isReadyToSubscribe = true
        reconnectManager.reset()
        flushMessageQueue()
        subscribeToPendingSymbolsIfNeeded()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        AppLogger.info("Disconnected", category: AppLogger.webSocket)
        transition(to: .disconnected)
        isReadyToSubscribe = false
        reconnect()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            AppLogger.error("Completed with error", category: AppLogger.webSocket, error: error)
        }
    }
}
