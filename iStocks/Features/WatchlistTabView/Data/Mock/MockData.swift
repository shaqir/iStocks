//
//  MockStocks.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation

struct MockData {
    
    static let sampleStocks: [Stock] = [
        .init(symbol: "AAPL", price: 149.99, previousPrice: 145.00, isPriceUp: true, qty: 100, averageBuyPrice: 145.00),
        .init(symbol: "MSFT", price: 278.99, previousPrice: 270.00, isPriceUp: true, qty: 50, averageBuyPrice: 270.00),
        .init(symbol: "TSLA", price: 1099.99, previousPrice: 1000.00, isPriceUp: true, qty: 20, averageBuyPrice: 1000.00),
        .init(symbol: "GOOGL", price: 109.99, previousPrice: 100.00, isPriceUp: true, qty: 30, averageBuyPrice: 100.00),
        .init(symbol: "AMZN", price: 1000.00, previousPrice: 900.00, isPriceUp: true, qty: 10, averageBuyPrice: 900.00),
         .init(symbol: "NVDA", price: 1000.00, previousPrice: 950.00, isPriceUp: true, qty: 30, averageBuyPrice: 950.00),
    ]
}
