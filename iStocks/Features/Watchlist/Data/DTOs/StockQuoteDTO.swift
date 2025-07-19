//
//  StockQuoteDTO.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-18.
//

import Foundation

struct StockQuoteDTO: Decodable {
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
        guard let price = finalPrice,
              let previous = previousClose
        else { return nil }

        return Stock(
            symbol: symbol,
            name: name ?? "",
            price: Double(price) ?? 0,
            previousPrice: Double(previous) ?? 0,
            isPriceUp: price >= previous,
            qty: 0,
            averageBuyPrice: Double(price) ?? 0,
            sector: "Technology",
            currency: currency ?? "USD",
            exchange: exchange ?? "NASDAQ",
            isFavorite: false
        )
    }
}
