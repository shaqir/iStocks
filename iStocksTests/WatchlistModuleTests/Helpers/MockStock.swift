//
//  MockStock.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-23.
//

import Foundation
@testable import iStocks

/// Helper model for mocking stock data in tests
struct MockStock {
    let symbol: String
    let name: String
    let price: Double
    let previousPrice: Double
    let isPriceUp: Bool
    let qty: Int
    let averageBuyPrice: Double
    let sector: String
    let currency: String
    let isFavorite: Bool

    init(
        symbol: String,
        name: String = "",
        price: Double = 100.0,
        previousPrice: Double = 95.0,
        isPriceUp: Bool = true,
        qty: Int = 0,
        averageBuyPrice: Double = 0.0,
        sector: String = "Technology",
        currency: String = "USD",
        isFavorite: Bool = false
    ) {
        self.symbol = symbol
        self.name = name.isEmpty ? "\(symbol) Inc." : name
        self.price = price
        self.previousPrice = previousPrice
        self.isPriceUp = isPriceUp
        self.qty = qty
        self.averageBuyPrice = averageBuyPrice
        self.sector = sector
        self.currency = currency
        self.isFavorite = isFavorite
    }

    func toDomain() -> Stock {
        Stock(
            symbol: symbol,
            name: name,
            price: price,
            previousPrice: previousPrice,
            isPriceUp: isPriceUp,
            qty: Double(qty),
            averageBuyPrice: averageBuyPrice,
            sector: sector,
            currency: currency,
            exchange: "NASDAQ",
            isFavorite: isFavorite
        )
    }
}
