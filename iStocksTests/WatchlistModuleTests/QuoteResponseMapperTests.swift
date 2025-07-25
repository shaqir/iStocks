//
//  QuoteResponseMapperTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-24.
//

import XCTest
@testable import iStocks

final class QuoteResponseMapperTests: XCTestCase {

    func makeErrorMessage(symbol: String, message: String) -> TwelveDataAPIError {
        return .invalidSymbols(["\(symbol): Failed to load data for: \(message)"])
    }

    func test_map_withAllValidStocks_shouldReturnStocks() throws {
        let wrapper: [String: StockResponseWrapper] = [
            "AAPL": .success(StockDTO.mock(symbol: "AAPL")),
            "MSFT": .success(StockDTO.mock(symbol: "MSFT"))
        ]

        let stocks = try QuoteResponseMapper.map(wrapper)
        let symbols = stocks.map { $0.symbol }

        XCTAssertEqual(stocks.count, 2)
        XCTAssertTrue(symbols.contains("AAPL"))
        XCTAssertTrue(symbols.contains("MSFT"))
    }

    func test_map_withSomeErrors_shouldReturnValidStocksAndLog() throws {
        let wrapper: [String: StockResponseWrapper] = [
            "AAPL": .success(StockDTO.mock(symbol: "AAPL")),
            "INVALID": .error(makeErrorMessage(symbol: "INVALID", message: "Invalid symbol"))
        ]

        let stocks = try QuoteResponseMapper.map(wrapper)
        XCTAssertEqual(stocks.count, 1)
        XCTAssertEqual(stocks[0].symbol, "AAPL")
    }

    func test_map_withOnlyInvalidStocks_shouldThrowError() throws {
        let wrapper: [String: StockResponseWrapper] = [
            "INVALID1": .error(makeErrorMessage(symbol: "INVALID1", message: "Not Found")),
            "INVALID2": .error(makeErrorMessage(symbol: "INVALID2", message: "Internal Error"))
        ]

        XCTAssertThrowsError(try QuoteResponseMapper.map(wrapper)) { error in
            guard case TwelveDataAPIError.invalidSymbols(let messages) = error else {
                return XCTFail("Expected TwelveDataAPIError.invalidSymbols, got \(error)")
            }
            XCTAssertEqual(messages.count, 2)
            XCTAssertTrue(messages.contains { $0.contains("Not Found") })
            XCTAssertTrue(messages.contains { $0.contains("Internal Error") })
        }
    }

    func test_map_withInvalidPrice_shouldSkipStock() throws {
        var invalidDTO = StockDTO.mock(symbol: "AAPL")
        invalidDTO.close = "invalid"

        let wrapper: [String: StockResponseWrapper] = [
            "AAPL": .success(invalidDTO),
            "MSFT": .success(StockDTO.mock(symbol: "MSFT"))
        ]

        let stocks = try QuoteResponseMapper.map(wrapper)
        let symbols = stocks.map { $0.symbol }

        XCTAssertEqual(stocks.count, 1)
        XCTAssertTrue(symbols.contains("MSFT"))
    }

    func test_map_withEmptyDictionary_shouldThrowError() {
        let wrapper: [String: StockResponseWrapper] = [:]

        XCTAssertThrowsError(try QuoteResponseMapper.map(wrapper)) { error in
            guard case AppError.api(let message) = error else {
                return XCTFail("Expected AppError.api, got \(error)")
            }
            XCTAssertTrue(message.contains("Invalid or empty response"))
        }
    }
}

// MARK: - Mock Helpers

extension StockDTO {
    static func mock(
        symbol: String = "AAPL",
        close: String = "123.45",
        previousClose: String? = nil,
        status: String = "ok",
        exchange: String = "NYSE"
    ) -> StockDTO {
        return try! JSONDecoder().decode(StockDTO.self, from: """
        {
            "symbol": "\(symbol)",
            "close": "\(close)",
            "previousClose": "\(previousClose ?? close)",
            "status": "\(status)",
            "exchange": "\(exchange)"
        }
        """.data(using: .utf8)!)
    }
}

struct APIErrorResponse: Decodable, Error {
    let code: Int
    let message: String
    let status: String
    var errorDescription: String? { message }
}
