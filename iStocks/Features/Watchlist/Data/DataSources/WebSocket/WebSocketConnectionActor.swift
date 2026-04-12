//
//  WebSocketConnectionActor.swift
//  iStocks
//
//  Created by Sakir Saiyed
//
//  Actor-isolated WebSocket connection state, replacing manual thread-safety
//  conventions with compiler-enforced isolation.
//
//  Migration (Swift 6.2): FinnhubWebSocketClient previously managed all mutable
//  state (connectionState, symbols, messageQueue) in a nonisolated class, relying
//  on the URLSession delegateQueue being .main for thread safety. This actor
//  extracts that state so the compiler guarantees no data races — the class
//  retains only the NSObject inheritance needed for URLSessionWebSocketDelegate.

import Foundation

/// Owns all mutable WebSocket connection state behind actor isolation.
///
/// Design rationale:
/// - Actors can't inherit from NSObject, so we can't make the WebSocket client itself an actor
/// - Instead, we extract state into this actor (composition over inheritance)
/// - The WebSocket client becomes a thin coordinator: delegate callbacks → actor → actions
/// - All state reads/writes require `await`, enforced at compile time
actor WebSocketConnectionActor {

    // MARK: - Connection State

    private(set) var connectionState: WebSocketConnectionState = .disconnected
    private(set) var isReadyToSubscribe = false

    // MARK: - Symbol Tracking

    private var subscribedSymbols: Set<String> = []
    private var pendingSymbols: Set<String> = []

    // MARK: - Message Queue (bounded buffer)

    /// Queued messages waiting to be sent once connected.
    /// Uses raw Data instead of URLSessionWebSocketTask.Message (not Sendable).
    private var messageQueue: [Data] = []

    // MARK: - Retry Tracking
    private var subscribeRetryAttempts = 0
    private let maxSubscribeRetryAttempts = 5

    // MARK: - State Machine

    /// Enforces valid WebSocket state transitions. Returns true if transition succeeded.
    ///
    /// Valid transitions:
    /// - disconnected  → connecting
    /// - connecting    → connected | disconnected
    /// - connected     → disconnected | reconnecting
    /// - reconnecting  → connecting | disconnected
    @discardableResult
    func transition(to newState: WebSocketConnectionState) -> Bool {
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
            return false
        }

        connectionState = newState
        return true
    }

    // MARK: - Connection Events

    /// Called when WebSocket successfully connects. Returns symbols to subscribe
    /// and queued messages to flush.
    func markConnected() -> (symbolsToSubscribe: Set<String>, queuedMessages: [Data]) {
        transition(to: .connected)
        isReadyToSubscribe = true

        let symbols = pendingSymbols
        let messages = messageQueue

        // Move pending → subscribed, clear queue
        subscribedSymbols.formUnion(pendingSymbols)
        pendingSymbols.removeAll()
        messageQueue.removeAll()

        return (symbols, messages)
    }

    /// Called when WebSocket disconnects. Preserves pending symbols for reconnect.
    func markDisconnected(clearPending: Bool) {
        transition(to: .disconnected)
        isReadyToSubscribe = false
        subscribedSymbols.removeAll()
        messageQueue.removeAll()
        subscribeRetryAttempts = 0
        if clearPending { pendingSymbols.removeAll() }
    }

    // MARK: - Subscriptions

    /// Registers new symbols for subscription. Returns the new symbols that weren't
    /// already subscribed. If connected, returns them immediately for subscribing;
    /// otherwise they stay pending until the next connect.
    func addSymbols(_ symbols: [String]) -> (
        newSymbols: Set<String>,
        shouldSubscribeNow: Bool,
        needsReconnect: Bool
    ) {
        let newSymbols = Set(symbols).subtracting(subscribedSymbols)
        guard !newSymbols.isEmpty else {
            return ([], false, false)
        }
        pendingSymbols.formUnion(newSymbols)

        let canSubscribeNow = connectionState == .connected && isReadyToSubscribe
        let needsReconnect = connectionState != .connected && connectionState != .connecting

        if canSubscribeNow {
            subscribedSymbols.formUnion(pendingSymbols)
            let toSubscribe = pendingSymbols
            pendingSymbols.removeAll()
            return (toSubscribe, true, false)
        }

        return (newSymbols, false, needsReconnect)
    }

    // MARK: - Message Queue

    /// Enqueues a message for sending. Returns true if enqueued, false if queue is full (backpressure).
    func enqueueMessage(_ data: Data) -> Bool {
        guard messageQueue.count < AppConstants.maxWebSocketMessageQueueSize else {
            AppLogger.warning(
                "WebSocket message queue full — applying backpressure, dropping message",
                category: AppLogger.webSocket
            )
            return false
        }
        messageQueue.append(data)
        return true
    }
}
