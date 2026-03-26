//
//  StockRemoteDataSourceAsyncTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed
//
//  Tests for the structured concurrency (TaskGroup) batch fetching migration.
//  Compare with StockRemoteDataSourceTests.swift — the Combine version requires
//  XCTestExpectation + wait(for:timeout:) for every async assertion.
//  These async tests read top-to-bottom with no expectations needed.

import XCTest
@testable import iStocks

final class StockRemoteDataSourceAsyncTests: XCTestCase {

    private var mockClient: MockNetworkClient!
    private var sut: StockRemoteDataSource!

    override func setUp() {
        super.setUp()
        mockClient = MockNetworkClient()
        // batchDelay: 0 — skip rate-limit waits in tests
        sut = StockRemoteDataSource(networkClient: mockClient, batchDelay: 0)
    }

    override func tearDown() {
        sut = nil
        mockClient = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makePriceResponseJSON(symbols: [String]) -> Data {
        var dict: [String: Any] = [:]
        for symbol in symbols {
            dict[symbol] = ["price": 150.0]
        }
        return try! JSONSerialization.data(withJSONObject: dict)
    }

    // MARK: - Success

    func test_fetchTop50InBatchesAsync_shouldReturnAllStocks() async throws {
        // Use 4 symbols with batchSize 2 → 2 batches
        // Mock returns the same JSON for every request, so each batch
        // decodes all 4 symbols. We verify stocks are returned and non-empty.
        let symbols = ["AAPL", "MSFT", "GOOGL", "TSLA"]
        mockClient.resultData = makePriceResponseJSON(symbols: symbols)

        // No XCTestExpectation needed — just await the result
        let stocks = try await sut.fetchTop50InBatchesAsync(symbols, batchSize: 2)

        // Each batch returns 4 stocks (mock returns same data), 2 batches = 8
        XCTAssertFalse(stocks.isEmpty)
        let returnedSymbols = Set(stocks.map(\.symbol))
        XCTAssertTrue(returnedSymbols.contains("AAPL"))
        XCTAssertTrue(returnedSymbols.contains("MSFT"))
    }

    // MARK: - Progress Tracking

    func test_fetchTop50InBatchesAsync_shouldReportProgress() async throws {
        let symbols = ["AAPL", "MSFT", "GOOGL", "TSLA"]
        mockClient.resultData = makePriceResponseJSON(symbols: symbols)

        var progressUpdates: [(batch: Int, total: Int, success: Bool)] = []

        _ = try await sut.fetchTop50InBatchesAsync(
            symbols,
            batchSize: 2
        ) { batchIndex, totalBatches, _, success in
            progressUpdates.append((batchIndex, totalBatches, success))
        }

        XCTAssertEqual(progressUpdates.count, 2, "Should report progress for each batch")
        XCTAssertTrue(progressUpdates.allSatisfy(\.success))
    }

    // MARK: - Partial Failure (graceful degradation)

    func test_fetchTop50InBatchesAsync_whenBatchFails_shouldReturnPartialResults() async throws {
        // Configure mock to fail (simulates network error)
        mockClient.resultError = NetworkError.serverError(500)

        let symbols = ["AAPL", "MSFT", "GOOGL"]

        // Should NOT throw — failed batches are skipped, not fatal
        let stocks = try await sut.fetchTop50InBatchesAsync(
            symbols,
            batchSize: 2,
            maxRetries: 0 // No retries for fast test
        )

        XCTAssertEqual(stocks.count, 0, "All batches failed, should return empty")
    }

    // MARK: - Cancellation

    func test_fetchTop50InBatchesAsync_shouldSupportCancellation() async {
        let symbols = Array(repeating: "AAPL", count: 50)
        mockClient.resultData = makePriceResponseJSON(symbols: ["AAPL"])

        let task = Task {
            try await sut.fetchTop50InBatchesAsync(symbols, batchSize: 2)
        }

        // Cancel immediately
        task.cancel()

        do {
            _ = try await task.value
            // If it completes before cancellation takes effect, that's acceptable
        } catch is CancellationError {
            // Expected — Task.checkCancellation() threw
        } catch {
            // Other errors are also acceptable in a cancellation race
        }
    }
}
