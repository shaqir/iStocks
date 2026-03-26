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

        let previous = invested > 0 ? invested : price

        return Stock(
            symbol: symbol,
            name: symbol,
            price: price,
            previousPrice: previous,
            isPriceUp: price >= previous,
            qty: 0,
            averageBuyPrice: 0,
            sector: "Crypto",
            currency: "USD",
            exchange: "Finnhub",
            isFavorite: false
        )
    }
}
