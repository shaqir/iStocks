//
//  TwelveDataWebSocketClient.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-17.
//
import Foundation
import Combine

// MARK: - Protocol

protocol WebSocketClient {
    func connect()
    func disconnect()
    func subscribe(to symbols: [String])
    func send(_ message: URLSessionWebSocketTask.Message)
    var stockPublisher: AnyPublisher<StockDTO, Never> { get }
}

// MARK: - Connection State Enum

enum WebSocketConnectionState {
    case disconnected, connecting, connected, reconnecting
}

// MARK: - Implementation

final class TwelveDataWebSocketClient: NSObject, WebSocketClient {

    // MARK: - Properties

    private let apiKey = API.apiKey
    private var webSocketTask: URLSessionWebSocketTask?
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)

    private let stockSubject = PassthroughSubject<StockDTO, Never>()
    var stockPublisher: AnyPublisher<StockDTO, Never> {
        stockSubject.eraseToAnyPublisher()
    }

    private(set) var connectionState: WebSocketConnectionState = .disconnected

    private var heartbeatTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempt = 0

    private var subscribedSymbols: Set<String> = []
    private var pendingSymbols: [String] = []
    private var messageQueue: [URLSessionWebSocketTask.Message] = []

    private var isReadyToSubscribe: Bool = false
    private var retryCount = 0
    private let maxRetryCount = 10
    
    private var url: URL {
        URL(string: "wss://ws.twelvedata.com/v1/quotes/price?apikey=\(apiKey)")!
    }

    // MARK: - Lifecycle

    override init() {
        super.init()
    }

    // MARK: - Connection Handling

    func connect() {
        guard connectionState != .connected && connectionState != .connecting else {
            Logger.log("[WebSocket] Already connected or connecting", category: "WebSocket")
            return
        }

        disconnect()
        connectionState = .connecting
        Logger.log("[WebSocket] Connecting to \(url.absoluteString)", category: "WebSocket")

        let request = URLRequest(url: url)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        Logger.log("[WebSocket] Task resumed", category: "WebSocket")

        listen()
        startHeartbeat()
    }

    func disconnect() {
        heartbeatTimer?.invalidate()
        reconnectTimer?.invalidate()

        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil

        subscribedSymbols.removeAll()
        connectionState = .disconnected
        Logger.log("[WebSocket] Disconnected", category: "WebSocket")
    }

    private func reconnect() {
        guard connectionState != .reconnecting else { return }

        connectionState = .reconnecting
        let delay = min(pow(2.0, Double(reconnectAttempt)), 60)
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.reconnectAttempt += 1
            self?.connect()
        }

        Logger.log("[WebSocket] Reconnecting in \(delay) seconds", category: "WebSocket")
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }

    private func sendHeartbeat() {
        guard connectionState == .connected else { return }

        let heartbeat = ["action": "heartbeat"]
        sendJSON(heartbeat)
        Logger.log("[WebSocket] Heartbeat sent", category: "WebSocket")
    }

    private func sendJSON(_ payload: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        send(.data(data))
    }

    // MARK: - Subscription Logic

    func subscribe(to symbols: [String]) {
        let newSymbols = Set(symbols).subtracting(subscribedSymbols)
        guard !newSymbols.isEmpty else { return }

        pendingSymbols.append(contentsOf: newSymbols)
        Logger.log("[WebSocket] Queued symbols: \(newSymbols)", category: "WebSocket")
        
        subscribeToPendingSymbolsIfNeeded()
    }

    private func subscribeToPendingSymbolsIfNeeded() {
        guard !pendingSymbols.isEmpty else { return }

        Logger.log("[WebSocket] Checking if ready to subscribe to pending symbols: \(pendingSymbols)", category: "WebSocket")

        guard connectionState == .connected,
              isReadyToSubscribe else {
            retryCount += 1
            if retryCount > maxRetryCount {
                Logger.log("[WebSocket] [Retry] Max retry attempts reached. Giving up.", category: "WebSocket")
                return
            }

            Logger.log("[WebSocket] [Retry] Not yet connected. Attempt \(retryCount)", category: "WebSocket")

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.subscribeToPendingSymbolsIfNeeded()
            }
            return
        }

        retryCount = 0 // reset

        let symbolsToSubscribe = Set(pendingSymbols)
        pendingSymbols.removeAll()

        Logger.log("[WebSocket] Subscribing to pending symbols now: \(symbolsToSubscribe)", category: "WebSocket")

        performSubscription(to: symbolsToSubscribe)
    }

    // MARK: - Sending Messages

    func send(_ message: URLSessionWebSocketTask.Message) {
        guard connectionState == .connected else {
            messageQueue.append(message)
            return
        }

        webSocketTask?.send(message) { error in
            if let error = error {
                Logger.log("[WebSocket] Send error: \(error)", category: "WebSocket")
            }
        }
    }
    
    private func performSubscription(to symbols: Set<String>) {
        let message: [String: Any] = [
            "action": "subscribe",
            "params": ["symbols": symbols.joined(separator: ",")]
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: message)
            Logger.log("[WebSocket] Sending subscription payload: \(String(data: data, encoding: .utf8) ?? "")", category: "WebSocket")

            webSocketTask?.send(.data(data)) { [weak self] error in
                if let error = error {
                    Logger.log("[WebSocket] Subscription error: \(error)", category: "WebSocket")
                } else {
                    Logger.log("[WebSocket] Subscribed to symbols: \(symbols)", category: "WebSocket")
                    self?.subscribedSymbols.formUnion(symbols)
                }
            }
        } catch {
            Logger.log("[WebSocket] Failed to encode subscription JSON: \(error)", category: "WebSocket")
        }
    }
    
    private func flushMessageQueue() {
        for message in messageQueue {
            send(message)
        }
        messageQueue.removeAll()
    }

    // MARK: - Message Listening

    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let message):
                switch message {
                case .data(let data): self.handleIncoming(data)
                case .string(let text): self.handleIncoming(Data(text.utf8))
                @unknown default:
                    Logger.log("[WebSocket] Unknown message type", category: "WebSocket")
                }

            case .failure(let error):
                Logger.log("[WebSocket] Receive error: \(error)", category: "WebSocket")
                connectionState = .disconnected
                reconnect()
            }

            self.listen() // Continue listening
        }
    }

    private func handleIncoming(_ data: Data) {
        guard let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let event = raw["event"] as? String else {
            Logger.log("[WebSocket] Failed to decode or missing event", category: "WebSocket")
            return
        }

        switch event {
        case "price":
            if let dto = try? JSONDecoder().decode(StockDTO.self, from: data) {
                stockSubject.send(dto)
            }
        case "subscribe-status":
            Logger.log("[WebSocket] Subscribed: \(raw["success"] ?? "")", category: "WebSocket")
        case "heartbeat":
            Logger.log("[WebSocket] Heartbeat acknowledged", category: "WebSocket")
        default:
            Logger.log("[WebSocket] Unknown event: \(event)", category: "WebSocket")
        }
    }

    // MARK: - Reset

    func reset() {
        disconnect()
        pendingSymbols.removeAll()
        subscribedSymbols.removeAll()
        reconnectAttempt = 0
        messageQueue.removeAll()
    }
    
}

// MARK: - URLSessionWebSocketDelegate

extension TwelveDataWebSocketClient: URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {

        Logger.log("[WebSocket] Connected.", category: "WebSocket")
        connectionState = .connected
        reconnectAttempt = 0
        flushMessageQueue()

        // Wait for the task to fully stabilize
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isReadyToSubscribe = true
            Logger.log("[WebSocket] Subscribing to any pending symbols...", category: "WebSocket")
            self?.subscribeToPendingSymbolsIfNeeded()
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        connectionState = .disconnected
        Logger.log("[WebSocket] Closed with code: \(closeCode.rawValue)", category: "WebSocket")

        if closeCode == .goingAway || closeCode == .normalClosure {
            Logger.log("[WebSocket] Graceful disconnect", category: "WebSocket")
        } else {
            reconnect()
        }
    }
}
