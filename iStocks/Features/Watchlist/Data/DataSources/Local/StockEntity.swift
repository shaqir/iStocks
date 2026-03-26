//
//  StockEntity.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-03.
//

import Foundation
import SwiftData

/// The persistence model: represents a stock stored in SwiftData
@Model
class StockEntity {
    var id: UUID
    var symbol: String
    var name: String
    var price: Double
    var previousPrice: Double
    var isPriceUp: Bool
    var sector: String
    var currency: String
    var exchange: String
    
    @Relationship var watchlist: WatchlistEntity?  // inverse relationship here

    init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        price: Double,
        previousPrice: Double,
        isPriceUp: Bool,
        sector: String,
        currency: String,
        exchange: String,
        watchlist: WatchlistEntity? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.price = price
        self.previousPrice = previousPrice
        self.isPriceUp = isPriceUp
        self.sector = sector
        self.currency = currency
        self.exchange = exchange
        self.watchlist = watchlist
    }
}

extension StockEntity {
    func toDomain() -> Stock {
        Stock(
            symbol: symbol,
            name: name,
            price: price,
            previousPrice: previousPrice,
            isPriceUp: isPriceUp,
            sector: sector,
            currency: currency,
            exchange: exchange
        )
    }

    static func from(_ stock: Stock, watchlist: WatchlistEntity? = nil) -> StockEntity? {
        guard !stock.symbol.isEmpty,
              stock.price.isFinite,
              stock.previousPrice.isFinite else {
            AppLogger.warning("Skipping invalid stock: \(stock.symbol)", category: AppLogger.persistence)
            return nil
        }
        
        return StockEntity(
            symbol: stock.symbol,
            name: stock.name,
            price: stock.price,
            previousPrice: stock.previousPrice,
            isPriceUp: stock.isPriceUp,
            sector: stock.sector,
            currency: stock.currency,
            exchange: stock.exchange,
            watchlist: watchlist
        )
    }
}
