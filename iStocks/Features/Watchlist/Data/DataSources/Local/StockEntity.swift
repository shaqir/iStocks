//
//  StockEntity.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-03.
//

import Foundation
import SwiftData

///The Persistence Model: represents your SwiftData (or CoreData) model
@Model
class StockEntity {
    var id: UUID
    var symbol: String
    var price: Double
    var previousPrice: Double
    var isPriceUp: Bool
    var averageBuyPrice: Double
    var qty: Double
    var sector: String
    
    @Relationship var watchlist: WatchlistEntity?  // inverse relationship here

    init(
        id: UUID = UUID(),
        symbol: String,
        price: Double,
        previousPrice: Double,
        isPriceUp: Bool,
        averageBuyPrice: Double,
        qty: Double,
        sector: String,
        watchlist: WatchlistEntity? = nil
    ) {
        self.id = id
        self.symbol = symbol
        self.price = price
        self.previousPrice = previousPrice
        self.isPriceUp = isPriceUp
        self.averageBuyPrice = averageBuyPrice
        self.qty = qty
        self.sector = sector
        self.watchlist = watchlist
    }
}

extension StockEntity {
    func toDomain() -> Stock {
        Stock(
            symbol: symbol,
            name: symbol,
            price: price,
            previousPrice: previousPrice,
            isPriceUp: isPriceUp,
            qty: qty,
            averageBuyPrice: averageBuyPrice,
            sector: sector,
            currency: "USD",
            exchange: "NASDAQ",
            isFavorite: false
        )
    }

    static func from(_ stock: Stock, watchlist: WatchlistEntity? = nil) -> StockEntity? {
        guard !stock.symbol.isEmpty,
              stock.price.isFinite,
              stock.previousPrice.isFinite,
              stock.qty.isFinite,
              stock.averageBuyPrice.isFinite else {
             
            Logger.log("Skipping invalid stock:: \(stock))", category: "StockEntity")
            
            return nil
        }
        
        return StockEntity(
            symbol: stock.symbol,
            price: stock.price,
            previousPrice: stock.previousPrice,
            isPriceUp: stock.isPriceUp,
            averageBuyPrice: stock.averageBuyPrice,
            qty: stock.qty,
            sector: stock.sector,
            watchlist: watchlist
        )
    }

}
