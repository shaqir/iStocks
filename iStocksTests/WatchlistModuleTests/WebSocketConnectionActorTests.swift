//
//  WebSocketConnectionActorTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed
//
//  Pins the WebSocket connection lifecycle: the transitions the client actually
//  performs must be valid, and subscriptions must survive a reconnect.
//  (Invalid transitions trip assertionFailure in DEBUG, so only valid paths are exercised.)
//

import Testing
import Foundation
@testable import iStocks

@Suite("WebSocket connection state machine")
struct WebSocketConnectionActorTests {

    @Test("Transition to the current state is a no-op, not an error")
    func sameStateTransitionIsNoOp() async {
        let actor = WebSocketConnectionActor()

        // connect() resets via markDisconnected before the first connection.
        #expect(await actor.transition(to: .disconnected))
        #expect(await actor.connectionState == .disconnected)
    }

    @Test("First connect follows disconnected → connecting → connected")
    func firstConnectPath() async {
        let actor = WebSocketConnectionActor()

        await actor.markDisconnected(clearPending: false)
        #expect(await actor.transition(to: .connecting))
        _ = await actor.markConnected()

        #expect(await actor.connectionState == .connected)
        #expect(await actor.isReadyToSubscribe)
    }

    @Test("Reconnect after a drop: disconnected → reconnecting → disconnected → connecting")
    func reconnectAfterDropPath() async {
        let actor = WebSocketConnectionActor()
        await actor.transition(to: .connecting)
        _ = await actor.markConnected()

        // Receive failure / server close
        await actor.markDisconnected(clearPending: false)
        #expect(await actor.transition(to: .reconnecting))

        // Retry fires connect(), which resets and connects again
        await actor.markDisconnected(clearPending: false)
        #expect(await actor.transition(to: .connecting))
        _ = await actor.markConnected()
        #expect(await actor.connectionState == .connected)
    }

    @Test("Subscribed symbols are resubscribed after a reconnect")
    func resubscribesAfterReconnect() async {
        let actor = WebSocketConnectionActor()
        await actor.transition(to: .connecting)
        _ = await actor.markConnected()

        let added = await actor.addSymbols(["BINANCE:BTCUSDT"])
        #expect(added.shouldSubscribeNow)

        await actor.markDisconnected(clearPending: false)
        await actor.transition(to: .connecting)
        let (symbolsToSubscribe, _) = await actor.markConnected()

        #expect(symbolsToSubscribe == ["BINANCE:BTCUSDT"])
    }

    @Test("clearPending drops subscriptions so nothing is resubscribed")
    func clearPendingDropsSubscriptions() async {
        let actor = WebSocketConnectionActor()
        await actor.transition(to: .connecting)
        _ = await actor.markConnected()
        _ = await actor.addSymbols(["BINANCE:BTCUSDT"])

        await actor.markDisconnected(clearPending: true)
        await actor.transition(to: .connecting)
        let (symbolsToSubscribe, _) = await actor.markConnected()

        #expect(symbolsToSubscribe.isEmpty)
    }
}
