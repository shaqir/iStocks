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
    func toDomainModel(previousPrice: Double? = nil) -> Stock? {
        guard let symbol = symbol else { return nil }

        let previous = previousPrice ?? price

        return Stock(
            symbol: symbol,
            name: symbol,
            price: price,
            previousPrice: previous,
            isPriceUp: price >= previous,
            sector: StockMetadata.sectorMap[symbol] ?? "Unknown",
            currency: "USD",
            exchange: "Finnhub"
        )
    }
}
