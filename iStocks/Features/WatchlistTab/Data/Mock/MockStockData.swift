//
//  MockStockData.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-04.
//
import Foundation

//
//  MockStockData.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation

struct MockStockData {
    static let allStocks: [Stock] = [
        Stock(id: UUID(), symbol: "AAPL", name: "Apple Inc.", price: 151.30, previousPrice: 149.99, isPriceUp: true, qty: 100, averageBuyPrice: 145, sector: "IT"),
        Stock(id: UUID(), symbol: "MSFT", name: "Microsoft Corp.", price: 279.24, previousPrice: 278.99, isPriceUp: true, qty: 50, averageBuyPrice: 270, sector: "IT"),
        Stock(id: UUID(), symbol: "GOOGL", name: "Alphabet Inc.", price: 111.18, previousPrice: 109.99, isPriceUp: true, qty: 30, averageBuyPrice: 100, sector: "Communication"),
        Stock(id: UUID(), symbol: "TSLA", name: "Tesla Inc.", price: 1100.07, previousPrice: 1099.99, isPriceUp: true, qty: 20, averageBuyPrice: 1000, sector: "Consumer"),
        Stock(id: UUID(), symbol: "AMZN", name: "Amazon.com Inc.", price: 1000.71, previousPrice: 1000.0, isPriceUp: true, qty: 10, averageBuyPrice: 900, sector: "Consumer"),
        Stock(id: UUID(), symbol: "NVDA", name: "NVIDIA Corp.", price: 1001.03, previousPrice: 1000.0, isPriceUp: true, qty: 30, averageBuyPrice: 950, sector: "IT"),
        Stock(id: UUID(), symbol: "JPM", name: "JPMorgan Chase & Co.", price: 148.50, previousPrice: 147.20, isPriceUp: true, qty: 40, averageBuyPrice: 140, sector: "Financials"),
        Stock(id: UUID(), symbol: "V", name: "Visa Inc.", price: 235.00, previousPrice: 232.40, isPriceUp: true, qty: 25, averageBuyPrice: 220, sector: "Financials"),
        Stock(id: UUID(), symbol: "XOM", name: "Exxon Mobil Corp.", price: 109.20, previousPrice: 107.80, isPriceUp: true, qty: 60, averageBuyPrice: 100, sector: "Energy"),
        Stock(id: UUID(), symbol: "CVX", name: "Chevron Corp.", price: 160.45, previousPrice: 159.00, isPriceUp: true, qty: 35, averageBuyPrice: 150, sector: "Energy"),
        Stock(id: UUID(), symbol: "PFE", name: "Pfizer Inc.", price: 38.60, previousPrice: 38.00, isPriceUp: true, qty: 80, averageBuyPrice: 35, sector: "Healthcare"),
        Stock(id: UUID(), symbol: "JNJ", name: "Johnson & Johnson", price: 168.30, previousPrice: 167.00, isPriceUp: true, qty: 50, averageBuyPrice: 160, sector: "Healthcare"),
        Stock(id: UUID(), symbol: "UNH", name: "UnitedHealth Group", price: 510.00, previousPrice: 505.00, isPriceUp: true, qty: 10, averageBuyPrice: 490, sector: "Healthcare"),
        Stock(id: UUID(), symbol: "HD", name: "Home Depot", price: 330.00, previousPrice: 328.00, isPriceUp: true, qty: 15, averageBuyPrice: 310, sector: "Consumer"),
        Stock(id: UUID(), symbol: "BAC", name: "Bank of America", price: 32.70, previousPrice: 32.10, isPriceUp: true, qty: 100, averageBuyPrice: 30, sector: "Financials"),
        Stock(id: UUID(), symbol: "BA", name: "Boeing Co.", price: 210.00, previousPrice: 208.00, isPriceUp: true, qty: 20, averageBuyPrice: 200, sector: "Industrials"),
        Stock(id: UUID(), symbol: "CSCO", name: "Cisco Systems", price: 54.20, previousPrice: 53.70, isPriceUp: true, qty: 45, averageBuyPrice: 50, sector: "IT"),
        Stock(id: UUID(), symbol: "WMT", name: "Walmart Inc.", price: 140.50, previousPrice: 139.80, isPriceUp: true, qty: 30, averageBuyPrice: 135, sector: "Consumer Staples"),
        Stock(id: UUID(), symbol: "KO", name: "Coca-Cola Co.", price: 63.20, previousPrice: 62.50, isPriceUp: true, qty: 70, averageBuyPrice: 60, sector: "Consumer Staples"),
        Stock(id: UUID(), symbol: "DIS", name: "Walt Disney Co.", price: 97.60, previousPrice: 96.50, isPriceUp: true, qty: 25, averageBuyPrice: 90, sector: "Communication"),
        Stock(id: UUID(), symbol: "XOM", name: "Exxon Mobil Corp.", price: 102.00, previousPrice: 101.00, isPriceUp: true, qty: 35, averageBuyPrice: 95, sector: "Energy"),
        Stock(id: UUID(), symbol: "CVX", name: "Chevron Corp.", price: 77.00, previousPrice: 76.00, isPriceUp: true, qty: 40, averageBuyPrice: 70, sector: "Energy"),
        Stock(id: UUID(), symbol: "JNJ", name: "Johnson & Johnson", price: 112.00, previousPrice: 111.00, isPriceUp: true, qty: 50, averageBuyPrice: 105, sector: "Healthcare"),
        Stock(id: UUID(), symbol: "UNH", name: "UnitedHealth Group Incorporated", price: 109.00, previousPrice: 108.00, isPriceUp: true, qty: 60, averageBuyPrice: 100, sector: "Healthcare"),
        Stock(id: UUID(), symbol: "INTC", name: "Intel Corporation", price: 27.20, previousPrice: 26.50, isPriceUp: true, qty: 55, averageBuyPrice: 25, sector: "Technology"),
        Stock(id: UUID(), symbol: "MMM", name: "3M Company", price: 131.00, previousPrice: 130.00, isPriceUp: true, qty: 65, averageBuyPrice: 125, sector: "Technology"),
        Stock(id: UUID(), symbol: "ABT", name: "Abbott Laboratories", price: 101.00, previousPrice: 100.00, isPriceUp: true, qty: 75, averageBuyPrice: 95, sector: "Healthcare"),
        Stock(id: UUID(), symbol: "PFE", name: "Pfizer Inc.", price: 22.00, previousPrice: 21.50, isPriceUp: true, qty: 80, averageBuyPrice: 20, sector: "Healthcare"),
        
        
    ]

    static var sectors: [String] {
        Set(allStocks.map { $0.sector }).sorted()
    }
}

 
