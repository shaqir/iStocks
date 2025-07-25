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
    let event: String?
    let symbol: String?
    var close: String?
    var previousClose: String?
    let code: Int?
    let message: String?
    let status: String?
    let currency: String?
    let exchange: String?
    let type: String?
    let timestamp: Int?
    let price: Double?
    let currencyBase: String?
    let currencyQuote: String?
    
    enum CodingKeys: String, CodingKey {
        case symbol, close, previousClose, code, message, status, currency
        case event, exchange, type, timestamp, price
        case currencyBase = "currency_base"
        case currencyQuote = "currency_quote"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        event = try? container.decode(String.self, forKey: .event)
        symbol = try? container.decode(String.self, forKey: .symbol)
        close = try? container.decode(String.self, forKey: .close)
        previousClose = try? container.decode(String.self, forKey: .previousClose)
        code = try? container.decode(Int.self, forKey: .code)
        message = try? container.decode(String.self, forKey: .message)
        status = try? container.decode(String.self, forKey: .status)
        currency = try? container.decode(String.self, forKey: .currency)
        exchange = try? container.decode(String.self, forKey: .exchange)
        type = try? container.decode(String.self, forKey: .type)
        timestamp = try? container.decode(Int.self, forKey: .timestamp)
        currencyBase = try? container.decode(String.self, forKey: .currencyBase)
        currencyQuote = try? container.decode(String.self, forKey: .currencyQuote)
        
        // Price: decode from either Double or String
        if let priceDouble = try? container.decode(Double.self, forKey: .price) {
            price = priceDouble
        } else if let priceStr = try? container.decode(String.self, forKey: .price), let double = Double(priceStr) {
            price = double
        } else {
            price = nil
        }
    }
    
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
            sector: "My Watchlist",
            currency: "USD",
            exchange: exchange ?? "Unknown",
            isFavorite: false
        )
    }
}

