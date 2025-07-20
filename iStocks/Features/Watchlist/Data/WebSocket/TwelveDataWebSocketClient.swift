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
    
    // MARK: - Properties
    static let shared = TwelveDataWebSocketClient()
    
    private let apiKey = API.apiKey
    private var webSocketTask: URLSessionWebSocketTask?
    private lazy var session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    
    private let stockSubject = PassthroughSubject<StockPriceDTO, Never>()
    var stockPublisher: AnyPublisher<StockPriceDTO, Never> {
        stockSubject.eraseToAnyPublisher()
    }
    
    private(set) var connectionState: WebSocketConnectionState = .disconnected
    
    private var heartbeatTimer: Timer?
    private var reconnectTimer: Timer?
    private var reconnectAttempt = 0
    
    private var subscribedSymbols: Set<String> = []
    private var pendingSymbols: Set<String> = []
    
    private var messageQueue: [URLSessionWebSocketTask.Message] = []
    
    private var isReadyToSubscribe: Bool = false
    
    private var subscribeRetryAttempts = 0
    private let maxSubscribeRetryAttempts = 5
    
    private var url: URL {
        URL(string: "wss://ws.twelvedata.com/v1/quotes/price?apikey=\(apiKey)")!
    }
    
    // MARK: - Lifecycle
    
    private override init() {
        super.init()
        //.only one instance of this client
        Logger.log("TwelveDataWebSocketClient initialized – instance: \(Unmanaged.passUnretained(self).toOpaque())", category: "WebSocket")
    }
    
    // MARK: - Connection Handling
    
    func connect() {
        
        guard connectionState != .connected && connectionState != .connecting else {
            Logger.log("[WebSocket] Already connected or connecting", category: "WebSocket")
            return
        }
        
        if connectionState == .reconnecting || connectionState == .disconnected {
            Logger.log("[WebSocket] [Debug] Calling disconnect() from connect()", category: "WebSocket")
            disconnect() // only clean up if stale
        }
        
        connectionState = .connecting
        
        Logger.log("[WebSocket] Connecting to \(url.absoluteString)", category: "WebSocket")
        
        let request = URLRequest(url: url)
        webSocketTask = session.webSocketTask(with: request)
        
        ///initiate connection
        webSocketTask?.resume()
        
        Logger.log("[WebSocket] Task resumed", category: "WebSocket")
        ///start receiving messages
        
        listen()
        ///send periodic heartbeats every 10s for smooth and stable connection
        startHeartbeat()
    }
    
    func disconnect() {
        heartbeatTimer?.invalidate()
        reconnectTimer?.invalidate()
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        
        subscribedSymbols.removeAll()
        connectionState = .disconnected
        isReadyToSubscribe = false
        Logger.log("[WebSocket] disconnect() -> Disconnected", category: "WebSocket")
    }
    
    private func reconnect() {
        
        if self.reconnectAttempt > 3 {
            Logger.log("Max Reconnect Attempt Reached", category: "WebSocket")
            return
        }
        
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
        
        pendingSymbols.formUnion(newSymbols)
        
        Logger.log("[WebSocket] Queued symbols: \(newSymbols)", category: "WebSocket")
        Logger.log("[WebSocket] Current pendingSymbols after queue: \(pendingSymbols)", category: "WebSocket")
        Logger.log("[WebSocket] pendingSymbols pointer (subscribe): \(Unmanaged.passUnretained(self).toOpaque())", category: "WebSocket")
        
        
        // Attempt subscription only if connection is already ready
        subscribeToPendingSymbolsIfNeeded(triggeredBy: "subscribe(to)")
        
    }
    
    private func subscribeToPendingSymbolsIfNeeded(triggeredBy: String = "unknown") {
        
        Logger.log("[WebSocket] subscribeToPendingSymbolsIfNeeded() called by: \(triggeredBy)", category: "WebSocket")
        Logger.log("[WebSocket] Checking if ready to subscribe to pending symbols: \(pendingSymbols)", category: "WebSocket")
        Logger.log("[WebSocket] pendingSymbols pointer: \(Unmanaged.passUnretained(self).toOpaque())", category: "WebSocket")
        
        guard !pendingSymbols.isEmpty else {
            Logger.log("[WebSocket] No pending symbols to subscribe", category: "WebSocket")
            return
        }
        
        Logger.log("[WebSocket] Checking if ready to subscribe to pending symbols: \(pendingSymbols)", category: "WebSocket")
        Logger.log("ConnectionState: \(connectionState)", category: "WebSocket")
        Logger.log("isReadyToSubscribe: \(isReadyToSubscribe)", category: "WebSocket")
        
        guard connectionState == .connected else {
            Logger.log("[WebSocket] Skipping subscription – still disconnected", category: "WebSocket")
            return
        }
        
        guard isReadyToSubscribe else {
            Logger.log("[WebSocket] Skipping subscription – not yet ready", category: "WebSocket")
            return
        }
        
        // Now safe to copy and clear
        let symbolsToSubscribe = pendingSymbols
        performSubscription(to: symbolsToSubscribe)
        removePendingSymbols()
        
        Logger.log("[WebSocket] Subscribing to pending symbols now: \(symbolsToSubscribe)", category: "WebSocket")
        
    }
    
    func retryPendingSymbolsRecursive(triggeredBy: String = "manual", delay: TimeInterval = 1.0) {
        Logger.log("[WebSocket] Retry attempt \(subscribeRetryAttempts + 1) triggered by: \(triggeredBy)", category: "WebSocket")
        
        // Exit early if no symbols to retry
        guard !pendingSymbols.isEmpty else {
            Logger.log("[WebSocket] No pending symbols left to retry", category: "WebSocket")
            return
        }
        
        // If we're ready, just subscribe now and reset counter
        if connectionState == .connected, isReadyToSubscribe {
            Logger.log("[WebSocket] Ready! Subscribing to pending symbols...", category: "WebSocket")
            subscribeToPendingSymbolsIfNeeded(triggeredBy: "retryRecursive")
            subscribeRetryAttempts = 0
            return
        }
        
        // If we've reached max retry attempts, stop
        if subscribeRetryAttempts >= maxSubscribeRetryAttempts {
            Logger.log("[WebSocket] Max retry attempts reached. Giving up.", category: "WebSocket")
            return
        }
        
        subscribeRetryAttempts += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.retryPendingSymbolsRecursive(triggeredBy: "retryRecursive", delay: delay)
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
                Logger.log("[WebSocket] Send error: \(error)", category: "WebSocket")
            }
        }
    }
    
    private func performSubscription(to symbols: Set<String>) {
        Logger.log("performSubscription() called", category: "WebSocket")
        
        let message: [String: Any] = [
            "action": "subscribe",
            "params": ["symbols": symbols.joined(separator: ",")]
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: message)
            let payload = String(data: data, encoding: .utf8) ?? "<invalid json>"
            Logger.log("[WebSocket] Sending subscription payload: \(payload)", category: "WebSocket")
            
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
    
    private func removePendingSymbols() {
        Logger.log("removePendingSymbols() called", category: "WebSocket")
        pendingSymbols.removeAll()
    }
    
    private func flushMessageQueue() {
        Logger.log("flushingmessagequeue() called")
        for message in messageQueue {
            send(message)
        }
        messageQueue.removeAll()
    }
    
    // MARK: - Message Listening
    
    private func listen() {
        Logger.log("[WebSocket] Listening for next message...", category: "WebSocket")
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let message):
                Logger.log("[WebSocket] Received message: \(message)", category: "WebSocket")
                switch message {
                case .data(let data):
                    Logger.log("[WebSocket] Received data: \(data)", category: "WebSocket")
                    self.handleIncoming(data)
                case .string(let text):
                    Logger.log("[WebSocket] Received string: \(text)", category: "WebSocket")
                    self.handleIncoming(Data(text.utf8))
                @unknown default:
                    Logger.log("[WebSocket] Unknown message type", category: "WebSocket")
                }
                
            case .failure(let error):
                Logger.log("[WebSocket] Receive error: \(error)", category: "WebSocket")
                if self.connectionState == .connected || self.connectionState == .connecting {
                    self.connectionState = .disconnected
                    Logger.log("[WebSocket] Failure -> Disconnected.")
                    isReadyToSubscribe = false
                    self.reconnect()
                } else {
                    Logger.log("[WebSocket] Ignoring failure during non-connected state", category: "WebSocket")
                }
                self.listen() // Always continue listening
            }
            
            self.listen() // Continue listening
        }
    }
    
    private func handleIncoming(_ data: Data) {
        let rawString = String(data: data, encoding: .utf8) ?? "<invalid>"
        Logger.log("[WebSocket] RAW incoming message: \(rawString)", category: "WebSocket")

        do {
            let message = try JSONDecoder().decode(WebSocketMessage.self, from: data)
            switch message {
            case .price(let dto):
                Logger.log("[WebSocket] Price event received: \(dto)", category: "WebSocket")
                stockSubject.send(dto)
            case .heartbeat:
                Logger.log("[WebSocket] Heartbeat", category: "WebSocket")
            case .subscribeStatus(let status):
                Logger.log("[WebSocket] Subscribe status: \(status)", category: "WebSocket")
            }
        } catch {
            Logger.log("[WebSocket] JSON decoding failed: \(error)", category: "WebSocket")
            Logger.log("[WebSocket] Raw message (for manual inspection): \(rawString)", category: "WebSocket")
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            
            self.isReadyToSubscribe = true
            Logger.log("[WebSocket] Subscribing to any pending symbols...", category: "WebSocket")
            self.subscribeToPendingSymbolsIfNeeded(triggeredBy: "didOpenWithProtocol")
            
            // Retry up to 5 times if initial call fails
            self.retryPendingSymbolsRecursive()
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        connectionState = .disconnected
        Logger.log("[WebSocket] Closed with code: \(closeCode.rawValue)", category: "WebSocket")
        
        if closeCode == .goingAway || closeCode == .normalClosure {
            Logger.log("[WebSocket] Graceful disconnect", category: "WebSocket")
        } else {
            isReadyToSubscribe = false
            reconnect()
        }
    }
}


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
