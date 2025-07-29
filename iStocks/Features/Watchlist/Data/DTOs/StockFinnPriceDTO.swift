//
//  StockFinnPriceDTO.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-28.
//

import Foundation

// MARK: - StockTradePriceDTO
struct StockFinnPriceDTO: Decodable {
    let symbol: String?
    let price: Double
    let timestamp: TimeInterval
}

extension StockFinnPriceDTO {
    func toDomainModel(invested: Double) -> Stock? {
        guard let symbol = symbol else { return nil }

        let previous = invested > 0 ? invested : price * Double.random(in: 0.97...1.03)

        return Stock(
            symbol: symbol,
            name: symbol,
            price: price,
            previousPrice: previous,
            isPriceUp: price >= previous,
            qty: Double(Int.random(in: 1...10)),
            averageBuyPrice: previous,
            sector: "Crypto", // or use a mapping
            currency: "USD",
            exchange: "Finnhub",
            isFavorite: false
        )
    }
}
