//
//  TwelveDataWebSocketClient.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-17.
//

//  Summary:
//  This WebSocket client handles real-time price streaming from Twelve Data WebSocket API.
//
//   Features:
//  - Connects to wss://ws.twelvedata.com/v1/quotes/price
//  - Manages connection lifecycle: connect, disconnect, reconnect
//  - Supports subscription queue and pending retry mechanism
//  - Sends heartbeat every 10s and handles heartbeat events
//  - Decodes price updates, heartbeat, and subscribe-status messages
//  - Uses Combine's `stockPublisher` for downstream updates
//
//   Limitations with Free (Basic) Tier:
//  - Only **1 active WebSocket connection** is allowed
//  - Only up to **8 symbols per connection** (must be **trial-enabled** symbols)
//  - Most equity symbols (e.g., AAPL, TSLA) are NOT available for WebSocket in Basic plan
//  - Use trial symbols like: `BTC/USD`, `ETH/USD`, `EUR/USD`, `USD/JPY`, `AAPL:US` (if enabled)
//    → See: https://twelvedata.com/exchanges?level=basic
//  - If non-trial symbols are used, no `price` events will be sent (silent failure)
//  - Requires proper `"subscribe"` message format with `action` and `params.symbols`
//
//  Debugging Tips:
//  - Always check if `.subscribe-status` is received (success/fail reason)
//  - Manually test symbols in: https://twelvedata.com/documentation#websocket
//  - Consider mocking or REST fallback if WebSocket is inactive or rate-limited
//

import Foundation
import Combine

// MARK: - Protocol

protocol WebSocketClient {
    func connect()
    func disconnect(clearPending: Bool)
    func subscribe(to symbols: [String])
    func send(_ message: URLSessionWebSocketTask.Message)
    var stockPublisher: AnyPublisher<StockPriceDTO, Never> { get }
}

// MARK: - Connection State Enum

enum WebSocketConnectionState {
    case disconnected, connecting, connected, reconnecting
}

enum WebSocketMessage: Decodable {
    case price(StockPriceDTO)
    case heartbeat
    case subscribeStatus(SubscribeStatusDTO)
    
    enum CodingKeys: String, CodingKey {
        case event
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let event = try container.decode(String.self, forKey: .event)
        
        switch event {
        case "price":
            self = .price(try StockPriceDTO(from: decoder))
        case "heartbeat":
            self = .heartbeat
        case "subscribe-status":
            self = .subscribeStatus(try SubscribeStatusDTO(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .event, in: container, debugDescription: "Unknown event type: \(event)")
        }
    }
}

// MARK: - Implementation

final class TwelveDataWebSocketClient: NSObject, WebSocketClient {
    
    static let shared = TwelveDataWebSocketClient()
    private override init() {
        super.init()
        Logger.log("TwelveDataWebSocketClient initialized – instance: \(Unmanaged.passUnretained(self).toOpaque())", category: "WebSocket")
    }
    
    private let apiKey = API.apiKey
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
    private var webSocketTask: URLSessionWebSocketTask?
    
    private let stockSubject = PassthroughSubject<StockPriceDTO, Never>()
    var stockPublisher: AnyPublisher<StockPriceDTO, Never> {
        stockSubject.eraseToAnyPublisher()
    }
    
    private(set) var connectionState: WebSocketConnectionState = .disconnected
    private var heartbeatTimer: Timer?
    private var subscribedSymbols: Set<String> = []
    private var pendingSymbols: Set<String> = []
    private var messageQueue: [URLSessionWebSocketTask.Message] = []
    private var isReadyToSubscribe: Bool = false
    private var subscribeRetryAttempts = 0
    private let maxSubscribeRetryAttempts = 5
    private let reconnectManager = ConnectionRetryManager()
    
    private var url: URL {
        URL(string: "wss://ws.twelvedata.com/v1/quotes/price?apikey=\(apiKey)")!
    }
    
    func connect() {
        guard connectionState != .connected && connectionState != .connecting else {
            Logger.log("[WebSocket] Already connected or connecting", category: "WebSocket")
            return
        }
        
        if connectionState == .reconnecting || connectionState == .disconnected {
            Logger.log("[WebSocket] [Debug] Calling disconnect() from connect()", category: "WebSocket")
            disconnect(clearPending: false)
        }
        
        connectionState = .connecting
        Logger.log("[WebSocket] Connecting to \(url.absoluteString)", category: "WebSocket")
        setupWebSocket()
    }
    
    func disconnect(clearPending: Bool = false) {
        heartbeatTimer?.invalidate()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        resetConnectionState(clearPending: clearPending)
        Logger.log("[WebSocket] disconnect() -> Disconnected", category: "WebSocket")
    }
    
    func reset() {
        disconnect(clearPending: true)
        reconnectManager.reset()
    }
    
    private func resetConnectionState(clearPending: Bool = false) {
        connectionState = .disconnected
        subscribedSymbols.removeAll()
        messageQueue.removeAll()
        isReadyToSubscribe = false
        subscribeRetryAttempts = 0
        if clearPending { pendingSymbols.removeAll() }
    }
    
    private func reconnect() {
        guard connectionState != .reconnecting else { return }
        if reconnectManager.hasReachedMaxAttempts {
            Logger.log("[WebSocket] Max reconnect attempts reached. Giving up.", category: "WebSocket")
            return
        }
        connectionState = .reconnecting
        reconnectManager.scheduleRetry(taskName: "WebSocket Reconnect") { [weak self] in
            self?.connect()
        }
    }
    
    private func retryConnectIfNeeded(triggeredBy: String = "unknown") {
        guard connectionState != .connected && connectionState != .connecting else {
            Logger.log("[WebSocket] retryConnectIfNeeded(): Already connected or connecting", category: "WebSocket")
            return
        }
        Logger.log("[WebSocket] retryConnectIfNeeded() triggered by: \(triggeredBy)", category: "WebSocket")
        reconnect()
    }
    
    private func setupWebSocket() {
        let request = URLRequest(url: url)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()

        Logger.log("[WebSocket] WebSocket task resumed.", category: "WebSocket")
        print("[WebSocket] after resume: \(String(describing: webSocketTask))")
        
        self.listen()
        
        startHeartbeat()
        sendJSON(["action": "ping"])

        // TEMP DEBUG: Manual receive to check if server sends anything
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.webSocketTask?.receive { result in
                switch result {
                case .success(let msg):
                    Logger.log("[Manual Receive] Success: \(msg)", category: "WebSocket")
                case .failure(let err):
                    Logger.log("[Manual Receive] Error: \(err)", category: "WebSocket")
                }
            }
        }
    }
    
    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    private func sendHeartbeat() {
        guard connectionState == .connected else { return }
        sendJSON(["action": "heartbeat"])
        Logger.log("[WebSocket] Heartbeat sent", category: "WebSocket")
    }
    
    private func sendJSON(_ payload: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
        send(.data(data))
    }
    
    func subscribe(to symbols: [String]) {
        let newSymbols = Set(symbols).subtracting(subscribedSymbols)
        guard !newSymbols.isEmpty else { return }
        pendingSymbols.formUnion(newSymbols)
        Logger.log("[WebSocket] Queued new symbols: \(newSymbols)", category: "WebSocket")
        subscribeToPendingSymbolsIfNeeded(triggeredBy: "subscribe(to)")
        retryConnectIfNeeded(triggeredBy: "subscribe(to)")
    }
    
    private func subscribeToPendingSymbolsIfNeeded(triggeredBy: String) {
        guard !pendingSymbols.isEmpty else {
            Logger.log("[WebSocket] No pending symbols to subscribe", category: "WebSocket")
            return
        }
        Logger.log("[WebSocket] Subscription check → Connected: \(connectionState == .connected), Ready: \(isReadyToSubscribe), Pending: \(pendingSymbols)", category: "WebSocket")
        guard connectionState == .connected else { return }
        guard isReadyToSubscribe else { return }
        performSubscription(to: pendingSymbols)
        pendingSymbols.removeAll()
    }
    
    func retryPendingSymbolsRecursive(triggeredBy: String = "manual", delay: TimeInterval = 1.0) {
        guard !pendingSymbols.isEmpty else { return }
        if connectionState == .connected, isReadyToSubscribe {
            subscribeToPendingSymbolsIfNeeded(triggeredBy: "retryRecursive")
            subscribeRetryAttempts = 0
            return
        }
        guard subscribeRetryAttempts < maxSubscribeRetryAttempts else { return }
        subscribeRetryAttempts += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.retryPendingSymbolsRecursive(triggeredBy: "retryRecursive", delay: delay)
        }
    }
    
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
        let message: [String: Any] = ["action": "subscribe", "params": ["symbols": symbols.joined(separator: ",")]]
        do {
            let data = try JSONSerialization.data(withJSONObject: message)
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
    
    private func listen() {
        guard let webSocketTask else {
            Logger.log("[WebSocket] listen() -> No active WebSocketTask", category: "WebSocket")
            return
        }
        Logger.log("[WebSocket] Listening on task: \(webSocketTask)", category: "WebSocket")
        
        webSocketTask.receive { [weak self] result in
            guard let self else { return }
            
            defer {
                        // ALWAYS listen again
                        if self.connectionState == .connected {
                            self.listen()
                        }
                    }
            
            switch result {
            case .success(let message):
                Logger.log("[WebSocket] Received message type: \(message)", category: "WebSocket")
                switch message {
                case .data(let data):
                    self.handleIncoming(data)
                case .string(let text):
                    self.handleIncoming(Data(text.utf8))
                @unknown default:
                    Logger.log("[WebSocket] Unknown message type received", category: "WebSocket")
                }
            case .failure(let error):
                Logger.log("[WebSocket] Receive failed: \(error)", category: "WebSocket")
                self.connectionState = .disconnected
                self.isReadyToSubscribe = false
                self.reconnect()
            }

            // Recurse only if still active
            if self.connectionState == .connected {
                self.listen()
            }
        }
    }
    
    private func handleIncoming(_ data: Data) {
        Logger.log("[WebSocket] RAW incoming message: \(String(data: data, encoding: .utf8) ?? "<invalid>")", category: "WebSocket")
        do {
            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
            switch message {
            case .price(let dto):
                stockSubject.send(dto)
            case .heartbeat:
                Logger.log("[WebSocket] Heartbeat message received", category: "WebSocket")
            case .subscribeStatus(let status):
                Logger.log("[WebSocket] Subscribe status: \(status)", category: "WebSocket")
            }
        } catch {
            Logger.log("[WebSocket] JSON decoding failed: \(error)", category: "WebSocket")
        }
    }
}

extension TwelveDataWebSocketClient: URLSessionWebSocketDelegate {
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Logger.log("[WebSocket] didOpenWithProtocol called", category: "WebSocket")
        connectionState = .connected
        self.isReadyToSubscribe = true
        reconnectManager.reset()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            Logger.log("[WebSocket] Ready to subscribe. Listening and retrying symbols...", category: "WebSocket")
            flushMessageQueue()
            self.subscribeToPendingSymbolsIfNeeded(triggeredBy: "didOpenWithProtocol")
            self.retryPendingSymbolsRecursive()
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        connectionState = .disconnected
        isReadyToSubscribe = false
        reconnect()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Logger.log("[WebSocket] WebSocket task completed with error: \(error.localizedDescription)", category: "WebSocket")
        }
    }
}

// MARK: - Models

struct SubscribeStatusDTO: Decodable {
    let status: String
    let success: [SubscribedSymbol]?
    let fails: [FailedSymbol]?
    
    struct SubscribedSymbol: Decodable {
        let symbol: String
        let exchange: String?
        let type: String?
    }
    
    struct FailedSymbol: Decodable {
        let symbol: String
        let message: String?
    }
}
