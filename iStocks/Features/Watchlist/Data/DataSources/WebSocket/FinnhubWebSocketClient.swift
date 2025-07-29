//
//  FinnhubWebSocketClient.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-27.
//

import Foundation
import Combine

// MARK: - Protocol

protocol WebSocketClient {
    func connect()
    func disconnect(clearPending: Bool)
    func subscribe(to symbols: [String])
    var stockPublisher: AnyPublisher<StockFinnPriceDTO, Never> { get }
}

// MARK: - Connection State Enum
enum WebSocketConnectionState {
    case disconnected, connecting, connected, reconnecting
}

final class FinnhubWebSocketClient: NSObject, WebSocketClient {
    
    // MARK: - Singleton
    static let shared = FinnhubWebSocketClient()
    private override init() { super.init() }

    // MARK: - Properties
    private let apiKey = API.apiKey_finnhub
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
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

    private var url: URL {
        URL(string: "wss://ws.finnhub.io?token=\(apiKey)")!
    }

    // MARK: - Connection Lifecycle
    func connect() {
        guard connectionState != .connected && connectionState != .connecting else { return }

        disconnect(clearPending: false)
        connectionState = .connecting
        Logger.log("[WebSocket] Connecting to \(url)", category: "WebSocket")

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
        connectionState = .disconnected
        isReadyToSubscribe = false
        subscribedSymbols.removeAll()
        messageQueue.removeAll()
        subscribeRetryAttempts = 0
        if clearPending { pendingSymbols.removeAll() }
    }

    private func reconnect() {
        guard connectionState != .reconnecting else { return }
        if reconnectManager.hasReachedMaxAttempts {
            Logger.log("[WebSocket] Max reconnect attempts reached", category: "WebSocket")
            return
        }
        connectionState = .reconnecting
        reconnectManager.scheduleRetry(taskName: "Finnhub Reconnect") { [weak self] in self?.connect() }
    }

    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.sendJSON(["type": "heartbeat"])
        }
    }

    // MARK: - Sending Messages
    func send(_ message: URLSessionWebSocketTask.Message) {
        guard connectionState == .connected else {
            messageQueue.append(message)
            return
        }
        webSocketTask?.send(message) { error in
            if let error = error {
                Logger.log("[WebSocket] Send failed: \(error)", category: "WebSocket")
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
                    Logger.log("[WebSocket] Unknown message format", category: "WebSocket")
                }
            case .failure(let error):
                Logger.log("[WebSocket] Receive error: \(error)", category: "WebSocket")
                self.connectionState = .disconnected
                self.isReadyToSubscribe = false
                self.reconnect()
            }
        }
    }

    private func handleIncoming(_ data: Data) {
        Logger.log("[WebSocket] RAW incoming: \(String(data: data, encoding: .utf8) ?? "<invalid>")", category: "WebSocket")
        do {
            let message = try JSONDecoder().decode(FinnhubResponseMapper.self, from: data)
            if message.type == "trade", let trades = message.data {
                for trade in trades {
                    let dto = StockFinnPriceDTO(symbol: trade.s, price: trade.p, timestamp: trade.t)
                    stockSubject.send(dto)
                }
            }
        } catch {
            Logger.log("[WebSocket] JSON decoding failed: \(error)", category: "WebSocket")
        }
    }
}

extension FinnhubWebSocketClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Logger.log("[WebSocket] Connected", category: "WebSocket")
        connectionState = .connected
        isReadyToSubscribe = true
        reconnectManager.reset()
        flushMessageQueue()
        subscribeToPendingSymbolsIfNeeded()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Logger.log("[WebSocket] Disconnected", category: "WebSocket")
        connectionState = .disconnected
        isReadyToSubscribe = false
        reconnect()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Logger.log("[WebSocket] Completed with error: \(error.localizedDescription)", category: "WebSocket")
        }
    }
}
