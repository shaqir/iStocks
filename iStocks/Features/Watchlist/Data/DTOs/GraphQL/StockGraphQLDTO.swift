//
//  StockGraphQLDTO.swift
//  iStocks
//
//  Created by Sakir Saiyed.
//

import Foundation

// MARK: - Generic GraphQL Response Wrapper

nonisolated struct GraphQLResponse<T: Decodable>: Decodable {
    let data: T?
    let errors: [GraphQLErrorDetail]?
}

// MARK: - Stock Quotes Response

/// Maps the `data.stockQuotes` field from the GraphQL response
nonisolated struct StockQuotesGraphQLResponse: Decodable {
    let stockQuotes: [StockGraphQLDTO]
}

/// Maps the `data.top50Stocks` field from the GraphQL response
nonisolated struct Top50StocksGraphQLResponse: Decodable {
    let top50Stocks: [StockGraphQLDTO]
}

/// Maps the `data.stockPrice` field for a single stock query
nonisolated struct StockPriceGraphQLResponse: Decodable {
    let stockPrice: StockGraphQLDTO
}

// MARK: - Stock GraphQL DTO

nonisolated struct StockGraphQLDTO: Decodable {
    let symbol: String
    let name: String?
    let price: Double?
    let previousClose: Double?
    let change: Double?
    let percentChange: Double?
    let volume: Int?
    let currency: String?
    let exchange: String?
    let sector: String?
}
