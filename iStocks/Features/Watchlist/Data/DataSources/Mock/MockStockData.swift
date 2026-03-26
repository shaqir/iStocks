//
//  MockStockData.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-04.
//
import Foundation

struct MockStockData {
    
    static let allStocks: [Stock] = {
        let rawStocks: [Stock] = [
            Stock(symbol: "AAPL", name: "Apple Inc.", price: 151.30, previousPrice: 149.99, isPriceUp: true, sector: "IT", currency: "USD", exchange: "NASDAQ"),
            Stock(symbol: "MSFT", name: "Microsoft Corp.", price: 279.24, previousPrice: 278.99, isPriceUp: true, sector: "IT", currency: "USD", exchange: "NASDAQ"),
            Stock(symbol: "GOOGL", name: "Alphabet Inc.", price: 111.18, previousPrice: 109.99, isPriceUp: true, sector: "Communication", currency: "USD", exchange: "NASDAQ"),
            Stock(symbol: "TSLA", name: "Tesla Inc.", price: 1100.07, previousPrice: 1099.99, isPriceUp: true, sector: "Consumer", currency: "USD", exchange: "NASDAQ"),
            Stock(symbol: "AMZN", name: "Amazon.com Inc.", price: 1000.71, previousPrice: 1000.0, isPriceUp: true, sector: "Consumer", currency: "USD", exchange: "NASDAQ"),
            Stock(symbol: "NVDA", name: "NVIDIA Corp.", price: 1001.03, previousPrice: 1000.0, isPriceUp: true, sector: "IT", currency: "USD", exchange: "NASDAQ"),
            Stock(symbol: "JPM", name: "JPMorgan Chase & Co.", price: 148.50, previousPrice: 147.20, isPriceUp: true, sector: "Financials", currency: "USD", exchange: "NYSE"),
            Stock(symbol: "V", name: "Visa Inc.", price: 235.00, previousPrice: 232.40, isPriceUp: true, sector: "Financials", currency: "USD", exchange: "NYSE"),
            Stock(symbol: "XOM", name: "Exxon Mobil Corp.", price: 109.20, previousPrice: 107.80, isPriceUp: true, sector: "Energy", currency: "USD", exchange: "NYSE"),
            Stock(symbol: "CVX", name: "Chevron Corp.", price: 160.45, previousPrice: 159.00, isPriceUp: true, sector: "Energy", currency: "USD", exchange: "NYSE"),
            Stock(symbol: "PFE", name: "Pfizer Inc.", price: 38.60, previousPrice: 38.00, isPriceUp: true, sector: "Healthcare", currency: "USD", exchange: "NYSE"),
            Stock(symbol: "JNJ", name: "Johnson & Johnson", price: 168.30, previousPrice: 167.00, isPriceUp: true, sector: "Healthcare", currency: "USD", exchange: "NYSE"),
            Stock(symbol: "UNH", name: "UnitedHealth Group", price: 510.00, previousPrice: 505.00, isPriceUp: true, sector: "Healthcare", currency: "USD", exchange: "NYSE"),
            Stock(symbol: "HD", name: "Home Depot", price: 330.00, previousPrice: 328.00, isPriceUp: true, sector: "Consumer", currency: "USD", exchange: "NYSE"),
            Stock(symbol: "BAC", name: "Bank of America", price: 32.70, previousPrice: 32.10, isPriceUp: true, sector: "Financials", currency: "USD", exchange: "NYSE"),
            Stock(symbol: "BA", name: "Boeing Co.", price: 210.00, previousPrice: 208.00, isPriceUp: true, sector: "Industrials", currency: "USD", exchange: "NYSE"),
            Stock(symbol: "CSCO", name: "Cisco Systems", price: 54.20, previousPrice: 53.70, isPriceUp: true, sector: "IT", currency: "USD", exchange: "NASDAQ"),
            Stock(symbol: "WMT", name: "Walmart Inc.", price: 140.50, previousPrice: 139.80, isPriceUp: true, sector: "Consumer Staples", currency: "USD", exchange: "NYSE"),
            Stock(symbol: "KO", name: "Coca-Cola Co.", price: 63.20, previousPrice: 62.50, isPriceUp: true, sector: "Consumer Staples", currency: "USD", exchange: "NYSE"),
            Stock(symbol: "DIS", name: "Walt Disney Co.", price: 97.60, previousPrice: 96.50, isPriceUp: true, sector: "Communication", currency: "USD", exchange: "NYSE"),
            Stock(symbol: "INTC", name: "Intel Corporation", price: 27.20, previousPrice: 26.50, isPriceUp: true, sector: "Technology", currency: "USD", exchange: "NASDAQ"),
            Stock(symbol: "MMM", name: "3M Company", price: 131.00, previousPrice: 130.00, isPriceUp: true, sector: "Technology", currency: "USD", exchange: "NYSE"),
            Stock(symbol: "ABT", name: "Abbott Laboratories", price: 101.00, previousPrice: 100.00, isPriceUp: true, sector: "Healthcare", currency: "USD", exchange: "NYSE"),
            Stock(symbol: "VZ", name: "Verizon Communications Inc.", price: 55.00, previousPrice: 54.00, isPriceUp: true, sector: "Communication", currency: "USD", exchange: "NYSE"),
            Stock(symbol: "BRK.B", name: "Berkshire Hathaway Inc.", price: 450.00, previousPrice: 440.00, isPriceUp: true, sector: "Consumer Discretionary", currency: "USD", exchange: "NYSE")
        ]
        return rawStocks
    }()
    
    static let noStocks: [Stock] = []
    
    static var sectors: [String] {
        Set(allStocks.map { $0.sector }).sorted()
    }
}
