//
//  QuoteEndpointTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2026-03-21.
//

import XCTest
@testable import iStocks

final class QuoteEndpointTests: XCTestCase {

    func test_forSymbols_shouldConstructCorrectEndpoint() {
        let endpoint = QuoteEndPoint.forSymbols(["AAPL", "MSFT"], apiKey: "testKey")

        XCTAssertEqual(endpoint.path, "/quote")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertNotNil(endpoint.queryItems)
        XCTAssertEqual(endpoint.queryItems?.count, 2)
    }

    func test_forSymbols_shouldJoinSymbolsWithComma() {
        let endpoint = QuoteEndPoint.forSymbols(["AAPL", "MSFT", "GOOGL"], apiKey: "key")

        let symbolItem = endpoint.queryItems?.first(where: { $0.name == "symbol" })
        XCTAssertEqual(symbolItem?.value, "AAPL,MSFT,GOOGL")
    }

    func test_forSymbols_shouldIncludeAPIKey() {
        let endpoint = QuoteEndPoint.forSymbols(["AAPL"], apiKey: "my_api_key")

        let apiKeyItem = endpoint.queryItems?.first(where: { $0.name == "apikey" })
        XCTAssertEqual(apiKeyItem?.value, "my_api_key")
    }

    func test_forSymbols_shouldProduceValidURL() {
        let endpoint = QuoteEndPoint.forSymbols(["AAPL"], apiKey: "key")
        XCTAssertNotNil(endpoint.url)
        XCTAssertTrue(endpoint.url!.absoluteString.contains("/quote"))
    }

    func test_forSymbols_withSingleSymbol_shouldNotHaveComma() {
        let endpoint = QuoteEndPoint.forSymbols(["TSLA"], apiKey: "key")

        let symbolItem = endpoint.queryItems?.first(where: { $0.name == "symbol" })
        XCTAssertEqual(symbolItem?.value, "TSLA")
        XCTAssertFalse(symbolItem!.value!.contains(","))
    }
}

// MARK: - PriceEndpoint Tests

final class PriceEndpointTests: XCTestCase {

    func test_forSymbols_shouldConstructCorrectEndpoint() {
        let endpoint = PriceEndpoint.forSymbols(["AAPL", "MSFT"], apiKey: "testKey")

        XCTAssertEqual(endpoint.path, "/price")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertNotNil(endpoint.queryItems)
        XCTAssertEqual(endpoint.queryItems?.count, 2)
    }

    func test_forSymbols_shouldJoinSymbolsWithComma() {
        let endpoint = PriceEndpoint.forSymbols(["AAPL", "GOOGL"], apiKey: "key")

        let symbolItem = endpoint.queryItems?.first(where: { $0.name == "symbol" })
        XCTAssertEqual(symbolItem?.value, "AAPL,GOOGL")
    }

    func test_forSymbols_shouldIncludeAPIKey() {
        let endpoint = PriceEndpoint.forSymbols(["AAPL"], apiKey: "secret_key")

        let apiKeyItem = endpoint.queryItems?.first(where: { $0.name == "apikey" })
        XCTAssertEqual(apiKeyItem?.value, "secret_key")
    }

    func test_forSymbols_shouldProduceValidURL() {
        let endpoint = PriceEndpoint.forSymbols(["AAPL"], apiKey: "key")
        XCTAssertNotNil(endpoint.url)
        XCTAssertTrue(endpoint.url!.absoluteString.contains("/price"))
    }
}
