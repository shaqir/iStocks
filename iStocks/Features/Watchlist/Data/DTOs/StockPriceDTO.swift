//
//  StockPriceDTO.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-09.
//

import Foundation

struct StockPriceDTO: Decodable {
    let price: String
}

extension StockPriceDTO {
    func toStockPrice(symbol: String) -> Stock? {
        guard let current = Double(price) else { return nil }
        let sector = StockMetadata.sectorMap[symbol] ?? "Unknown"

        return Stock(
            symbol: symbol,
            name: symbol,
            price: current,
            previousPrice: current * Double.random(in: 0.95...1.05),
            isPriceUp: Bool.random(),
            qty: Double.random(in: 1...100),
            averageBuyPrice: current * Double.random(in: 0.8...1.2),
            sector: sector
        )
    }
}
