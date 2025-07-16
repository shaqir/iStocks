//
//  StockAPIResponse.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation

// MARK: - DTO (Response from Twelve Data): mirrors the API response format
///   Needs to be mapped to Stock via a mapper (e.g. StockMapper or StockResponseWrapper)
struct StockDTO: Decodable {
    let symbol: String?
    let close: String?
    let previousClose: String?
    let code: Int?
    let message: String?
    let status: String?
    let currency: String?
    
    var isValid: Bool {
        return status != "error" && symbol != nil && close != nil
    }

    func toDomainModel(invested: Double) -> Stock? {
        guard
            let symbol = symbol,
            let priceStr = close,
            let previousStr = previousClose ?? close,
            let price = Double(priceStr),
            let previous = Double(previousStr)
        else {
            return nil
        }
        
        let qty = Double(Int.random(in: 1...100))
        let averageBuyPrice = Bool.random()
            ? price * Double.random(in: 0.8...0.99)
            : price * Double.random(in: 1.01...1.2)
        
        return Stock(
            symbol: symbol,
            name: "name",
            price: price,
            previousPrice: previous,
            isPriceUp: price >= previous,
            qty: qty,
            averageBuyPrice: averageBuyPrice,
            sector: "My Watchlist"
        )
    }

    enum CodingKeys: String, CodingKey {
        case symbol, close
        case previousClose
        case code, message, status
        case currency
    }
}
