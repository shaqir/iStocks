//
//  MockStockRepositoryTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-23.
//

import XCTest
import Combine
@testable import iStocks

final class MockStockRepositoryTests: XCTestCase {
    
    var sut: MockStockRepositoryImpl!//System Under Test.
    var mockService: MockStockStreamingService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockService = MockStockStreamingService()
        sut = MockStockRepositoryImpl(service: mockService)
        cancellables = []
    }
    
    override func tearDown() {
        sut.stopUpdates()
        sut = nil
        cancellables = nil
        super.tearDown()
    }
    
    func test_observeStocks_shouldEmitMockPrices() {
        let expectation = XCTestExpectation(description: "Should receive mock stock price updates")

        var receivedStocks: [Stock] = []

        sut.observeStocks()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected failure: \(error)")
                    }
                },
                receiveValue: { stocks in
                    receivedStocks = stocks
                    if !stocks.isEmpty {
                        expectation.fulfill()
                    }
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 2.0)
        XCTAssertFalse(receivedStocks.isEmpty)
    }
    
    func test_stopUpdates_shouldStopPublishing() {
        let expectation = XCTestExpectation(description: "Should receive updates and then stop")
        var receivedCount = 0

        sut.observeStocks()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Unexpected error: \(error)")
                    }
                },
                receiveValue: { stocks in
                    if !stocks.isEmpty {
                        receivedCount += 1
                        if receivedCount == 2 {
                            self.sut.stopUpdates()
                            expectation.fulfill()
                        }
                    }
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
        XCTAssertGreaterThanOrEqual(receivedCount, 2)
    }
    
}
