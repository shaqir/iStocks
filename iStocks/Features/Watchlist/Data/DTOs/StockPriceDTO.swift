//
//  StockPriceDTO.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-09.
//

import Foundation

nonisolated struct StockPriceDTO: Decodable {
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

    func toDomainModel(previousPrice: Double? = nil) -> Stock? {
        guard let symbol = symbol, let price = price else { return nil }

        let previous = previousPrice ?? price

        return Stock(
            symbol: symbol,
            name: symbol,
            price: price,
            previousPrice: previous,
            isPriceUp: price >= previous,
            sector: StockMetadata.sectorMap[symbol] ?? "Unknown",
            currency: currencyBase ?? "USD",
            exchange: exchange ?? "Unknown"
        )
    }
}
 
nonisolated extension StockPriceDTO {
    func toStockPrice(symbol: String) -> Stock? {
        guard let current = price else { return nil }

        let sector = StockMetadata.sectorMap[symbol] ?? "Unknown"

        return Stock(
            symbol: symbol,
            name: symbol,
            price: current,
            previousPrice: current,
            isPriceUp: false,
            sector: sector,
            currency: currencyBase ?? "USD",
            exchange: exchange ?? "NASDAQ"
        )
    }
}
