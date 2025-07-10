//
//  StockPriceDTO.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-09.
//

import Foundation

struct StockPriceDTO: Decodable {
    let symbol: String
    let price: String
}

extension StockPriceDTO {
    
    func toStockPrice(symbol: String) -> Stock? {

        let current = Double(price) ?? 0
        let sector = StockMetadata.sectorMap[symbol] ?? "Unknown"

        return Stock(
            id: UUID(),
            symbol: symbol,
            name: symbol, // Placeholder, could be looked up via cached metadata
            price: current,
            previousPrice: current * Double.random(in: 0.95...1.05), // Simulate small variation
            isPriceUp: Bool.random(), // You could compare to previousPrice if available
            qty: Double.random(in: 1...100), // For demo/mock only
            averageBuyPrice: current * Double.random(in: 0.8...1.2),
            sector: sector
        )
    }
}
 
