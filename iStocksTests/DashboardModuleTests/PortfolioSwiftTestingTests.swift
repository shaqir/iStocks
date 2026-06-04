//
//  PortfolioSwiftTestingTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed
//
//  Swift Testing suite (Xcode 16+, `import Testing`) sitting alongside the existing
//  XCTest suites. Demonstrates the modern APIs: @Suite, parameterized @Test(arguments:),
//  #expect / #require, async actor testing, `await #expect(throws:)`, and custom @Tag.
//

import Testing
import Foundation
@testable import iStocks

// MARK: - Tags

extension Tag {
    @Tag static var pnl: Self
    @Tag static var actorIsolation: Self
}

// MARK: - Holding P&L (parameterized, pure value-type math)

@Suite("Holding P&L math")
struct HoldingPnLSuite {

    /// One row of the truth table. Must be Sendable to be used as @Test arguments.
    struct Scenario: Sendable, CustomTestStringConvertible {
        let quantity: Double
        let averageCost: Double
        let currentPrice: Double
        let expectedMarketValue: Double
        let expectedReturn: Double
        let isPositive: Bool

        var testDescription: String {
            "\(quantity)@\(averageCost)->\(currentPrice)"
        }
    }

    @Test("marketValue / totalReturn / isPositive are computed correctly", .tags(.pnl), arguments: [
        Scenario(quantity: 10, averageCost: 145, currentPrice: 150, expectedMarketValue: 1500, expectedReturn: 50,   isPositive: true),
        Scenario(quantity: 5,  averageCost: 200, currentPrice: 180, expectedMarketValue: 900,  expectedReturn: -100, isPositive: false),
        Scenario(quantity: 3,  averageCost: 100, currentPrice: 100, expectedMarketValue: 300,  expectedReturn: 0,    isPositive: true),
    ])
    func computedProperties(_ s: Scenario) {
        let holding = Holding.mock(quantity: s.quantity, averageCost: s.averageCost, currentPrice: s.currentPrice)
        #expect(holding.marketValue == s.expectedMarketValue)
        #expect(holding.totalReturn == s.expectedReturn)
        #expect(holding.isPositive == s.isPositive)
    }

    @Test("totalReturnPercentage guards against a zero cost basis", .tags(.pnl))
    func zeroCostBasisIsSafe() {
        let holding = Holding.mock(quantity: 0, averageCost: 0, currentPrice: 100)
        #expect(holding.totalReturnPercentage == 0)
    }

    @Test("withUpdatedPrice returns a new value and preserves value semantics")
    func immutablePriceUpdate() {
        let original = Holding.mock(currentPrice: 150)
        let updated = original.withUpdatedPrice(175)
        #expect(updated.currentPrice == 175)
        #expect(original.currentPrice == 150) // the original is untouched
    }
}

// MARK: - Dashboard aggregation

@Suite("Dashboard aggregation")
struct DashboardAggregationSuite {

    @Test("totalReturn sums per-holding returns")
    func totalReturnSumsHoldings() {
        let dashboard = Dashboard(
            holdings: [
                .mock(quantity: 10, averageCost: 100, currentPrice: 110), // +100
                .mock(quantity: 5,  averageCost: 100, currentPrice: 90),  //  -50
            ],
            news: [],
            totalValue: 0,
            lastUpdated: Date()
        )
        #expect(dashboard.totalReturn == 50)
        #expect(dashboard.totalReturnPercentage == (50.0 / 1500.0) * 100)
    }

    @Test("totalReturnPercentage is zero when there are no holdings")
    func emptyPortfolioIsSafe() {
        let dashboard = Dashboard(holdings: [], news: [], totalValue: 0, lastUpdated: Date())
        #expect(dashboard.totalReturnPercentage == 0)
    }
}

// MARK: - PortfolioActor (async + actor isolation)

@Suite("PortfolioActor behavior")
struct PortfolioActorSuite {

    @Test("addHolding accumulates into totalValue", .tags(.actorIsolation))
    func addAccumulatesTotal() async {
        let portfolio = PortfolioActor()
        await portfolio.addHolding(.mock(symbol: "AAPL", quantity: 10, currentPrice: 150)) // 1500
        await portfolio.addHolding(.mock(symbol: "MSFT", quantity: 2,  currentPrice: 400)) //  800
        let total = await portfolio.totalValue()
        #expect(total == 2300)
    }

    @Test("removeHolding drops only the matching symbol", .tags(.actorIsolation))
    func removeDropsMatchingSymbol() async throws {
        let portfolio = PortfolioActor()
        await portfolio.addHolding(.mock(symbol: "AAPL"))
        await portfolio.addHolding(.mock(symbol: "TSLA"))
        await portfolio.removeHolding(symbol: "AAPL")

        let holdings = await portfolio.holdings
        #expect(holdings.count == 1)
        let remaining = try #require(holdings.first)
        #expect(remaining.symbol == "TSLA")
    }

    @Test("executeTrade rolls back the optimistic holding when confirmation fails")
    func executeTradeRollsBackOnFailure() async {
        let portfolio = PortfolioActor()
        let failingBroker = FailingTradeService()

        await #expect(throws: TestTradeError.self) {
            try await portfolio.executeTrade(symbol: "NVDA", quantity: 1, price: 900, using: failingBroker)
        }

        let holdings = await portfolio.holdings
        #expect(holdings.isEmpty) // optimistic append was rolled back
    }

    @Test("executeTrade keeps the holding when confirmation succeeds")
    func executeTradeCommitsOnSuccess() async throws {
        let portfolio = PortfolioActor()
        try await portfolio.executeTrade(symbol: "NVDA", quantity: 1, price: 900, using: SucceedingTradeService())
        let holdings = await portfolio.holdings
        #expect(holdings.map(\.symbol) == ["NVDA"])
    }

    @Test("isMarketOpen is nonisolated — callable without await", .tags(.actorIsolation))
    func nonisolatedQueryNeedsNoAwait() {
        let portfolio = PortfolioActor()
        // Compiles without `await`, which is the whole point of `nonisolated`.
        _ = portfolio.isMarketOpen()
    }
}

// MARK: - Test doubles

private struct FailingTradeService: TradeExecutionService {
    func confirmTrade(symbol: String, quantity: Double, price: Double) async throws {
        throw TestTradeError.rejected
    }
}

private struct SucceedingTradeService: TradeExecutionService {
    func confirmTrade(symbol: String, quantity: Double, price: Double) async throws {
        // no-op: trade confirmed
    }
}

private enum TestTradeError: Error { case rejected }
