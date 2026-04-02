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
}
