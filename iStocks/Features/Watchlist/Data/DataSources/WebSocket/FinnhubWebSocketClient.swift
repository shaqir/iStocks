//
//  FinnhubWebSocketClient.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-27.
//

import Foundation
import Combine

// MARK: - Protocol

/// NOTE (Swift 6.2): Protocol is async because implementations delegate to actors.
/// Callers bridge via `Task { await client.connect() }` from synchronous contexts.
nonisolated protocol WebSocketClient: Sendable {
    func connect() async
    func disconnect(clearPending: Bool) async
    func subscribe(to symbols: [String]) async
    var stockPublisher: AnyPublisher<StockFinnPriceDTO, Never> { get }
}

// MARK: - Connection State Enum
nonisolated enum WebSocketConnectionState: Sendable {
    case disconnected, connecting, connected, reconnecting
}

/// Finnhub WebSocket client — thin NSObject coordinator over actor-isolated state.
///
/// Migration (Swift 6.2): Previously, this class owned all mutable state (connectionState,
/// subscribedSymbols, pendingSymbols, messageQueue) in a nonisolated class, relying on
/// the URLSession delegateQueue being .main for thread safety. Now:
///
/// - **WebSocketConnectionActor** owns all mutable connection state (compiler-enforced isolation)
/// - **ConnectionRetryManager** (actor) handles retry scheduling via Task.sleep
/// - This class retains NSObject only for URLSessionWebSocketDelegate conformance
/// - State access requires `await`, making thread-safety visible at every call site
///
/// Why not make this class itself an actor?
/// → Actors cannot inherit from NSObject, which is required for URLSessionWebSocketDelegate.
///   This is the standard composition pattern: actor for state, class for delegate conformance.
nonisolated final class FinnhubWebSocketClient: NSObject, WebSocketClient, @unchecked Sendable {

    override init() {
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }

    // MARK: - Properties
    private var apiKey: String {
        SecureAPIKeyManager.finnhubAPIKey
    }
    private var session: URLSession!
    private var webSocketTask: URLSessionWebSocketTask?
    private let stockSubject = PassthroughSubject<StockFinnPriceDTO, Never>()
    var stockPublisher: AnyPublisher<StockFinnPriceDTO, Never> {
        stockSubject.eraseToAnyPublisher()
    }

    /// Actor-isolated connection state — replaces the 8 mutable instance variables
    /// that previously relied on "always call from main queue" for thread safety.
    private let connectionActor = WebSocketConnectionActor()
    private let reconnectManager = ConnectionRetryManager()
    private var heartbeatTask: Task<Void, Never>?

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

    // MARK: - Connection Lifecycle

    func connect() async {
        let state = await connectionActor.connectionState
        guard state != .connected && state != .connecting else { return }

        guard let url = url else {
            AppLogger.error("Cannot connect: Invalid WebSocket URL", category: AppLogger.webSocket)
            await connectionActor.transition(to: .disconnected)
            return
        }

        await disconnectInternal(clearPending: false)
        await connectionActor.transition(to: .connecting)
        AppLogger.info("Connecting to \(url.absoluteString)", category: AppLogger.webSocket)

        let request = URLRequest(url: url)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        listen()
        startHeartbeat()
    }

    func disconnect(clearPending: Bool = false) async {
        await disconnectInternal(clearPending: clearPending)
    }

    private func disconnectInternal(clearPending: Bool) async {
        heartbeatTask?.cancel()
        heartbeatTask = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        await connectionActor.markDisconnected(clearPending: clearPending)
    }

    private func reconnect() async {
        let state = await connectionActor.connectionState
        guard state != .reconnecting else { return }
        let maxed = await reconnectManager.hasReachedMaxAttempts
        if maxed {
            AppLogger.warning("Max reconnect attempts reached", category: AppLogger.webSocket)
            return
        }
        await connectionActor.transition(to: .reconnecting)
        await reconnectManager.scheduleRetry(taskName: "Finnhub Reconnect") { [weak self] in
            await self?.connect()
        }
    }

    /// Heartbeat using structured concurrency — replaces Timer.scheduledTimer.
    ///
    /// Migration note: Timer requires RunLoop and isn't cancellation-aware.
    /// Task.sleep integrates with Swift's cooperative cancellation system.
    private func startHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(AppConstants.heartbeatIntervalSeconds))
                guard !Task.isCancelled else { break }
                self?.sendJSON(["type": "heartbeat"])
            }
        }
    }

    // MARK: - Sending Messages

    func send(_ data: Data) async {
        let state = await connectionActor.connectionState
        guard state == .connected else {
            let _ = await connectionActor.enqueueMessage(data)
            return
        }
        webSocketTask?.send(.data(data)) { error in
            if let error = error {
                AppLogger.error("Send failed", category: AppLogger.webSocket, error: error)
            }
        }
    }

    private func sendJSON(_ payload: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        Task { await send(data) }
    }

    // MARK: - Subscriptions

    func subscribe(to symbols: [String]) async {
        let result = await connectionActor.addSymbols(symbols)

        if result.shouldSubscribeNow {
            for symbol in result.newSymbols {
                sendJSON(["type": "subscribe", "symbol": symbol])
            }
        } else if result.needsReconnect {
            await reconnect()
        }
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
                Task {
                    await self.connectionActor.markDisconnected(clearPending: false)
                    await self.reconnect()
                }
            }
        }
    }

    private func handleIncoming(_ data: Data) {
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

// MARK: - URLSession Delegate

/// Delegate callbacks arrive on .main (delegateQueue set in init), then forward to the actor.
/// (URLSessionWebSocketDelegate is already concurrency-annotated in the current SDK, so no
/// @preconcurrency is needed on the conformance.)
extension FinnhubWebSocketClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        #if DEBUG
        MainActor.assertIsolated("WebSocket delegate must run on main thread — delegateQueue is .main")
        #endif
        AppLogger.info("Connected", category: AppLogger.webSocket)

        Task {
            let (symbolsToSubscribe, queuedMessages) = await connectionActor.markConnected()
            await reconnectManager.reset()

            // Flush queued messages
            for data in queuedMessages {
                await send(data)
            }

            // Subscribe to pending symbols
            for symbol in symbolsToSubscribe {
                sendJSON(["type": "subscribe", "symbol": symbol])
            }
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        AppLogger.info("Disconnected", category: AppLogger.webSocket)
        Task {
            await connectionActor.markDisconnected(clearPending: false)
            await reconnect()
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            AppLogger.error("Completed with error", category: AppLogger.webSocket, error: error)
        }
    }
}
