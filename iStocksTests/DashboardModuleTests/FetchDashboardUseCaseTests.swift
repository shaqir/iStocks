//
//  FetchDashboardUseCaseTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed
//

import XCTest
@testable import iStocks

final class FetchDashboardUseCaseTests: XCTestCase {

    func test_execute_returnsDashboardWithHoldingsAndNews() async throws {
        let mockRepo = MockStockRepository()
        mockRepo.holdingsResult = .success([.mock(symbol: "AAPL"), .mock(symbol: "MSFT")])
        mockRepo.priceResult = .success(160.0)
        mockRepo.newsResult = .success([.mock()])

        let actor = PortfolioActor()
        let sut = FetchDashboardUseCase(stockRepository: mockRepo, portfolio: actor)

        let dashboard = try await sut.execute(userId: "test")

        XCTAssertEqual(dashboard.holdings.count, 2)
        XCTAssertFalse(dashboard.news.isEmpty)
        XCTAssertGreaterThan(dashboard.totalValue, 0)
    }

    func test_execute_updatesPortfolioActor() async throws {
        let mockRepo = MockStockRepository()
        let actor = PortfolioActor()
        let sut = FetchDashboardUseCase(stockRepository: mockRepo, portfolio: actor)

        _ = try await sut.execute(userId: "test")

        let actorHoldings = await actor.holdings
        XCTAssertFalse(actorHoldings.isEmpty)
    }

    func test_execute_whenNewsFails_returnsEmptyNews() async throws {
        let mockRepo = MockStockRepository()
        mockRepo.newsResult = .failure(NetworkError.httpError(statusCode: 500, data: Data()))

        let actor = PortfolioActor()
        let sut = FetchDashboardUseCase(stockRepository: mockRepo, portfolio: actor)

        let dashboard = try await sut.execute(userId: "test")

        // News failure is non-critical — returns empty, doesn't throw
        XCTAssertTrue(dashboard.news.isEmpty)
        XCTAssertFalse(dashboard.holdings.isEmpty) // Holdings still loaded
    }

    func test_execute_whenPriceFails_keepsCachedPrice() async throws {
        let mockRepo = MockStockRepository()
        let originalPrice = 145.0
        mockRepo.holdingsResult = .success([.mock(symbol: "AAPL", currentPrice: originalPrice)])
        mockRepo.priceResult = .failure(NetworkError.timeout)

        let actor = PortfolioActor()
        let sut = FetchDashboardUseCase(stockRepository: mockRepo, portfolio: actor)

        let dashboard = try await sut.execute(userId: "test")

        // Price fetch failed — holding should keep its original cached price
        XCTAssertEqual(dashboard.holdings.first?.currentPrice, originalPrice)
    }
}
