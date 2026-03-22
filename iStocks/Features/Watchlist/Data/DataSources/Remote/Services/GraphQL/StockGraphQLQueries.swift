//
//  StockGraphQLQueries.swift
//  iStocks
//
//  Created by Sakir Saiyed.
//

import Foundation

/// Predefined GraphQL queries for stock data operations
enum StockGraphQLQueries {

    // MARK: - Stock Quotes (Multiple Symbols)

    static func stockQuotes(symbols: [String]) -> GraphQLQuery {
        GraphQLQuery(
            query: """
            query StockQuotes($symbols: [String!]!) {
                stockQuotes(symbols: $symbols) {
                    symbol
                    name
                    price
                    previousClose
                    change
                    percentChange
                    volume
                    currency
                    exchange
                    sector
                }
            }
            """,
            variables: ["symbols": .stringArray(symbols)],
            operationName: "StockQuotes"
        )
    }

    // MARK: - Single Stock Price

    static func stockPrice(symbol: String) -> GraphQLQuery {
        GraphQLQuery(
            query: """
            query StockPrice($symbol: String!) {
                stockPrice(symbol: $symbol) {
                    symbol
                    name
                    price
                    previousClose
                    change
                    percentChange
                    currency
                    exchange
                    sector
                }
            }
            """,
            variables: ["symbol": .string(symbol)],
            operationName: "StockPrice"
        )
    }

    // MARK: - Top 50 Stocks

    static func top50Stocks() -> GraphQLQuery {
        GraphQLQuery(
            query: """
            query Top50Stocks {
                top50Stocks {
                    symbol
                    name
                    price
                    previousClose
                    change
                    percentChange
                    volume
                    currency
                    exchange
                    sector
                }
            }
            """,
            operationName: "Top50Stocks"
        )
    }
}
