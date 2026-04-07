//
//  StockGraphQLDataSource.swift
//  iStocks
//
//  Created by Sakir Saiyed.
//

import Foundation
import Combine

// MARK: - Protocol

nonisolated protocol StockGraphQLDataSourceProtocol {
    func fetchStockQuotes(for symbols: [String]) -> AnyPublisher<[Stock], Error>
    func fetchTop50Stocks() -> AnyPublisher<[Stock], Error>
}

// MARK: - Implementation

nonisolated final class StockGraphQLDataSource: StockGraphQLDataSourceProtocol {

    // MARK: - Dependencies

    private let graphQLClient: GraphQLClientProtocol

    // MARK: - Init

    init(graphQLClient: GraphQLClientProtocol) {
        self.graphQLClient = graphQLClient
    }

    // MARK: - Fetch Stock Quotes

    func fetchStockQuotes(for symbols: [String]) -> AnyPublisher<[Stock], Error> {
        let query = StockGraphQLQueries.stockQuotes(symbols: symbols)

        return graphQLClient.execute(query: query)
            .tryMap { (response: StockQuotesGraphQLResponse) -> [Stock] in
                let stocks = GraphQLResponseMapper.map(response.stockQuotes)
                guard !stocks.isEmpty else {
                    throw AppError.api(message: "No stock data returned for symbols: \(symbols)")
                }
                return stocks
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Fetch Top 50

    func fetchTop50Stocks() -> AnyPublisher<[Stock], Error> {
        let query = StockGraphQLQueries.top50Stocks()

        return graphQLClient.execute(query: query)
            .tryMap { (response: Top50StocksGraphQLResponse) -> [Stock] in
                let stocks = GraphQLResponseMapper.map(response.top50Stocks)
                guard !stocks.isEmpty else {
                    throw AppError.api(message: "No top 50 stock data returned")
                }
                return stocks
            }
            .eraseToAnyPublisher()
    }
}
