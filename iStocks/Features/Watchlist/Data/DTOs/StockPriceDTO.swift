//
//  StockPriceDTO.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-09.
//

import Foundation

struct StockPriceDTO: Decodable {
    let event: String?  
    let symbol: String?
    let price: Double?
    let timestamp: Int?
    let currencyBase: String?
    let currencyQuote: String?
    let exchange: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case event, symbol, price, timestamp
        case currencyBase = "currency_base"
        case currencyQuote = "currency_quote"
        case exchange, type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.event = try? container.decode(String.self, forKey: .event)
        self.symbol = try? container.decode(String.self, forKey: .symbol)
        self.timestamp = try? container.decode(Int.self, forKey: .timestamp)
        self.currencyBase = try? container.decode(String.self, forKey: .currencyBase)
        self.currencyQuote = try? container.decode(String.self, forKey: .currencyQuote)
        self.exchange = try? container.decode(String.self, forKey: .exchange)
        self.type = try? container.decode(String.self, forKey: .type)

        // Flexible decoding for price
        if let priceDouble = try? container.decode(Double.self, forKey: .price) {
            self.price = priceDouble
        } else if let priceStr = try? container.decode(String.self, forKey: .price),
                  let priceDouble = Double(priceStr) {
            self.price = priceDouble
        } else {
            self.price = nil
        }
    }

    func toDomainModel(invested: Double) -> Stock? {
        guard let symbol = symbol, let price = price else { return nil }

        let previous = invested > 0 ? invested : price * Double.random(in: 0.97...1.03)

        return Stock(
            symbol: symbol,
            name: symbol,
            price: price,
            previousPrice: previous,
            isPriceUp: price >= previous,
            qty: Double(Int.random(in: 1...10)),
            averageBuyPrice: previous,
            sector: "Crypto",
            currency: "USD",
            exchange: exchange ?? "Coinbase Pro",
            isFavorite: false
        )
    }
}
 
extension StockPriceDTO {
    func toStockPrice(symbol: String) -> Stock? {
        guard let current = price else { return nil }

        let sector = StockMetadata.sectorMap[symbol] ?? "Unknown"

        return Stock(
            symbol: symbol,
            name: symbol,
            price: current,
            previousPrice: current * Double.random(in: 0.95...1.05),
            isPriceUp: Bool.random(),
            qty: Double.random(in: 1...100),
            averageBuyPrice: current * Double.random(in: 0.8...1.2),
            sector: sector,
            currency: "USD",
            exchange: exchange ?? "NASDAQ",
            isFavorite: false
        )
    }
}
