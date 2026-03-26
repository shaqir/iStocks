//
//  MockStockGraphQLDataSource.swift
//  iStocksTests
//
//  Created by Sakir Saiyed
//

import Foundation
import Combine
@testable import iStocks

final class MockStockGraphQLDataSource: StockGraphQLDataSourceProtocol {

    var fetchTop50Result: Result<[Stock], Error> = .success([Stock.mock(symbol: "AAPL")])
    var fetchQuotesResult: Result<[Stock], Error> = .success([Stock.mock(symbol: "AAPL")])
    var fetchTop50Called = false
    var fetchQuotesCalled = false

    func fetchTop50Stocks() -> AnyPublisher<[Stock], Error> {
        fetchTop50Called = true
        switch fetchTop50Result {
        case .success(let stocks):
            return Just(stocks)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }

    func fetchStockQuotes(for symbols: [String]) -> AnyPublisher<[Stock], Error> {
        fetchQuotesCalled = true
        switch fetchQuotesResult {
        case .success(let stocks):
            return Just(stocks)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        case .failure(let error):
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
    }
}
