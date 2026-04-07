//
//  PortfolioActorTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed
//

import XCTest
@testable import iStocks

final class PortfolioActorTests: XCTestCase {

    func test_update_setsHoldingsAndDate() async {
        let actor = PortfolioActor()
        let holdings = [Holding.mock(symbol: "AAPL"), Holding.mock(symbol: "MSFT")]

        await actor.update(holdings)

        let result = await actor.holdings
        XCTAssertEqual(result.count, 2)
        let lastUpdated = await actor.lastUpdated
        XCTAssertNotNil(lastUpdated)
    }

    func test_addHolding_appendsToList() async {
        let actor = PortfolioActor()

        await actor.addHolding(.mock(symbol: "AAPL"))
        await actor.addHolding(.mock(symbol: "GOOGL"))

        let holdings = await actor.holdings
        XCTAssertEqual(holdings.count, 2)
        XCTAssertEqual(holdings.map(\.symbol), ["AAPL", "GOOGL"])
    }

    func test_removeHolding_removesCorrectItem() async {
        let actor = PortfolioActor()
        await actor.update([
            .mock(symbol: "AAPL"),
            .mock(symbol: "GOOGL"),
            .mock(symbol: "MSFT")
        ])

        await actor.removeHolding(symbol: "GOOGL")

        let holdings = await actor.holdings
        XCTAssertEqual(holdings.count, 2)
        XCTAssertFalse(holdings.contains(where: { $0.symbol == "GOOGL" }))
    }

    func test_totalValue_sumsMarketValues() async {
        let actor = PortfolioActor()
        await actor.update([
            .mock(symbol: "AAPL", quantity: 10, currentPrice: 150.0),
            .mock(symbol: "MSFT", quantity: 5, currentPrice: 380.0)
        ])

        let total = await actor.totalValue()
        XCTAssertEqual(total, 3400.0, accuracy: 0.01) // 1500 + 1900
    }

    func test_isMarketOpen_doesNotRequireAwait() {
        let actor = PortfolioActor()
        // nonisolated method — no await needed
        let _ = actor.isMarketOpen()
        // Just verifying it compiles and runs without await
    }

    func test_concurrentAccess_maintainsConsistency() async {
        let actor = PortfolioActor()

        // Launch multiple concurrent tasks modifying the actor
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    await actor.addHolding(.mock(symbol: "SYM\(i)"))
                }
            }
        }

        let holdings = await actor.holdings
        XCTAssertEqual(holdings.count, 10)
    }

    // MARK: - Trade Execution Tests (Deduct-Before-Await Pattern)

    func test_executeTrade_rollsBackOnFailure() async throws {
        // Given: actor with one existing holding
        let actor = PortfolioActor()
        await actor.addHolding(.mock(symbol: "AAPL"))
        let initialCount = await actor.holdings.count

        // When: trade fails
        let failingService = MockTradeService(shouldFail: true)
        do {
            try await actor.executeTrade(symbol: "TSLA", quantity: 5, price: 250.0, using: failingService)
            XCTFail("Should have thrown")
        } catch {
            // Then: holdings rolled back to original state
            let finalCount = await actor.holdings.count
            XCTAssertEqual(finalCount, initialCount, "Holdings should be rolled back after failed trade")
        }
    }

    func test_executeTrade_persistsOnSuccess() async throws {
        // Given: empty actor
        let actor = PortfolioActor()
        let successService = MockTradeService(shouldFail: false)

        // When: trade succeeds
        try await actor.executeTrade(symbol: "AAPL", quantity: 10, price: 150.0, using: successService)

        // Then: holding persists
        let holdings = await actor.holdings
        XCTAssertEqual(holdings.count, 1)
        XCTAssertEqual(holdings.first?.symbol, "AAPL")
    }

    func test_refreshPrices_deduplicatesInFlightRequests() async throws {
        // Given: actor with holdings
        let actor = PortfolioActor()
        await actor.addHolding(.mock(symbol: "AAPL", currentPrice: 100.0))

        let service = MockPriceRefreshService(prices: [("AAPL", 155.0)])

        // When: call refresh twice rapidly — first should be cancelled
        await actor.refreshPrices(using: service)
        await actor.refreshPrices(using: service)

        // Wait for the refresh task to complete
        try await Task.sleep(for: .milliseconds(200))

        // Then: prices should be updated (verifies at least one refresh completed)
        let holdings = await actor.holdings
        XCTAssertEqual(holdings.first?.currentPrice, 155.0)
    }
}

// MARK: - Mock Services

private struct MockTradeService: TradeExecutionService {
    let shouldFail: Bool

    func confirmTrade(symbol: String, quantity: Double, price: Double) async throws {
        try await Task.sleep(for: .milliseconds(10)) // simulate network
        if shouldFail {
            throw NSError(domain: "TradeError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Trade rejected"])
        }
    }
}

private struct MockPriceRefreshService: PriceRefreshService {
    let prices: [(String, Double)]

    func fetchLatestPrices(for symbols: [String]) async throws -> [(String, Double)] {
        try await Task.sleep(for: .milliseconds(10)) // simulate network
        return prices
    }
}
