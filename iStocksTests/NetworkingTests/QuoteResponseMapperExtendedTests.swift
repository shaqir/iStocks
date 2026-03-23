//
//  QuoteResponseMapperExtendedTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2026-03-21.
//

import XCTest
@testable import iStocks

/// Additional edge-case tests for QuoteResponseMapper, complementing
/// the existing tests in WatchlistModuleTests/QuoteResponseMapperTests.swift
final class QuoteResponseMapperExtendedTests: XCTestCase {

    // MARK: - Helpers

    private func makeErrorWrapper(symbol: String, message: String) -> TwelveDataAPIError {
        return .invalidSymbols(["\(symbol): \(message)"])
    }

    // MARK: - Single Valid Stock

    func test_map_withSingleValidStock_shouldReturnOneStock() throws {
        let wrapper: [String: StockResponseWrapper] = [
            "TSLA": .success(StockDTO.mock(symbol: "TSLA", close: "200.00"))
        ]

        let stocks = try QuoteResponseMapper.map(wrapper)
        XCTAssertEqual(stocks.count, 1)
        XCTAssertEqual(stocks.first?.symbol, "TSLA")
    }

    // MARK: - Mixed: Multiple Valid + Multiple Errors

    func test_map_withMultipleValidAndMultipleErrors_shouldReturnOnlyValidStocks() throws {
        let wrapper: [String: StockResponseWrapper] = [
            "AAPL": .success(StockDTO.mock(symbol: "AAPL")),
            "MSFT": .success(StockDTO.mock(symbol: "MSFT")),
            "BAD1": .error(makeErrorWrapper(symbol: "BAD1", message: "Not found")),
            "BAD2": .error(makeErrorWrapper(symbol: "BAD2", message: "Rate limited"))
        ]

        let stocks = try QuoteResponseMapper.map(wrapper)
        XCTAssertEqual(stocks.count, 2)

        let symbols = Set(stocks.map { $0.symbol })
        XCTAssertTrue(symbols.contains("AAPL"))
        XCTAssertTrue(symbols.contains("MSFT"))
        XCTAssertFalse(symbols.contains("BAD1"))
        XCTAssertFalse(symbols.contains("BAD2"))
    }

    // MARK: - All Invalid Prices (no errors, just unmappable DTOs)

    func test_map_withAllInvalidPrices_shouldThrowAppError() {
        var dto1 = StockDTO.mock(symbol: "X")
        dto1.close = "not_a_number"
        var dto2 = StockDTO.mock(symbol: "Y")
        dto2.close = "also_bad"

        let wrapper: [String: StockResponseWrapper] = [
            "X": .success(dto1),
            "Y": .success(dto2)
        ]

        XCTAssertThrowsError(try QuoteResponseMapper.map(wrapper)) { error in
            guard case AppError.api(let message) = error else {
                return XCTFail("Expected AppError.api, got \(error)")
            }
            XCTAssertTrue(message.contains("Invalid or empty response"))
        }
    }

    // MARK: - StockQuoteDynamicResponse Decoding

    func test_dynamicResponse_dictionary_shouldDecodeDictionary() throws {
        let json = """
        {
            "AAPL": {
                "symbol": "AAPL",
                "close": "150.00",
                "status": "ok",
                "exchange": "NASDAQ"
            },
            "MSFT": {
                "symbol": "MSFT",
                "close": "300.00",
                "status": "ok",
                "exchange": "NASDAQ"
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(StockQuoteDynamicResponse.self, from: json)
        if case .dictionary(let dict) = response {
            XCTAssertEqual(dict.count, 2)
        } else {
            XCTFail("Expected .dictionary case")
        }
    }

    func test_dynamicResponse_single_shouldDecodeSingle() throws {
        let json = """
        {
            "symbol": "AAPL",
            "close": "150.00",
            "status": "ok",
            "exchange": "NASDAQ"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(StockQuoteDynamicResponse.self, from: json)
        if case .single(let wrapper) = response {
            if case .success(let dto) = wrapper {
                XCTAssertEqual(dto.symbol, "AAPL")
            } else {
                XCTFail("Expected .success wrapper")
            }
        } else {
            XCTFail("Expected .single case")
        }
    }

    func test_dynamicResponse_invalidJSON_shouldThrowDecodingError() {
        let json = """
        [1, 2, 3]
        """.data(using: .utf8)!

        XCTAssertThrowsError(try JSONDecoder().decode(StockQuoteDynamicResponse.self, from: json))
    }
}
