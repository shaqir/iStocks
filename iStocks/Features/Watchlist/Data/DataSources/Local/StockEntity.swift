//
//  StockEntity.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-03.
//

import Foundation
import SwiftData

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

    init(
        id: UUID = UUID(),
        symbol: String,
        price: Double,
        previousPrice: Double,
        isPriceUp: Bool,
        averageBuyPrice: Double,
        qty: Double,
        sector: String
    ) {
        self.id = id
        self.symbol = symbol
        self.price = price
        self.previousPrice = previousPrice
        self.isPriceUp = isPriceUp
        self.averageBuyPrice = averageBuyPrice
        self.qty = qty
        self.sector = sector
    }
}

extension StockEntity {
    func toDomain() -> Stock {
        Stock(
            id: id,
            symbol: symbol,
            name: symbol,
            price: price,
            previousPrice: previousPrice,
            isPriceUp: isPriceUp,
            qty: qty,
            averageBuyPrice: averageBuyPrice,
            sector: sector
        )
    }

    static func from(_ stock: Stock) -> StockEntity? {
        guard !stock.symbol.isEmpty,
              stock.price.isFinite,
              stock.previousPrice.isFinite,
              stock.qty.isFinite,
              stock.averageBuyPrice.isFinite else {
            print("Skipping invalid stock:", stock)
            return nil
        }
        
        //print("Creating StockEntity from:", stock)
        return StockEntity(
            id: stock.id,
            symbol: stock.symbol,
            price: stock.price,
            previousPrice: stock.previousPrice,
            isPriceUp: stock.isPriceUp,
            averageBuyPrice: stock.averageBuyPrice,
            qty: stock.qty,
            sector: stock.sector
        )
    }

}
