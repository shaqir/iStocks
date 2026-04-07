//
//  StockQuoteDTO.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-18.
//

import Foundation

nonisolated struct StockQuoteDTO: Decodable {
    let symbol: String
    let name: String?
    let exchange: String?
    let currency: String?
    let price: String?
    let change: String?
    let percentChange: String?
    let volume: String?
    let previousClose: String?
    let close: String? // its same as price


    enum CodingKeys: String, CodingKey {
            case symbol, name, exchange, currency, price, change
            case percentChange = "percent_change"
            case volume
            case previousClose = "previous_close"
            case close
        }
 
    func toStock() -> Stock? {
        let finalPrice = price ?? close ?? previousClose
        guard let priceStr = finalPrice,
              let previousStr = previousClose,
              let priceDouble = Double(priceStr),
              let previousDouble = Double(previousStr)
        else { return nil }

        return Stock(
            symbol: symbol,
            name: name ?? symbol,
            price: priceDouble,
            previousPrice: previousDouble,
            isPriceUp: priceDouble >= previousDouble,
            sector: StockMetadata.sectorMap[symbol] ?? "Unknown",
            currency: currency ?? "USD",
            exchange: exchange ?? "NASDAQ"
        )
    }
}
