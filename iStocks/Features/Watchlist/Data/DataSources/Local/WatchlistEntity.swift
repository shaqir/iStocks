//
//  WatchistEntity.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-03.
//
import Foundation
import SwiftData

@Model
class WatchlistEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var stocks: [StockEntity]
    var orderIndex: Int
    
    init(id: UUID = UUID(), name: String, stocks: [StockEntity], orderIndex: Int = 0) {
        self.id = id
        self.name = name
        self.stocks = stocks
        self.orderIndex = orderIndex
    }
}

extension WatchlistEntity {
    func toDomain() -> Watchlist {
        Watchlist(id: id, name: name, stocks: stocks.map { $0.toDomain() })
    }

    static func from(_ watchlist: Watchlist, orderIndex: Int) -> WatchlistEntity? {
        let stockEntities = watchlist.stocks.compactMap { StockEntity.from($0) }

        guard !watchlist.name.isEmpty else {
            Logger.log("Skipping watchlist with empty name: \(watchlist))", category: "StockEntity")

            return nil
        }

        return WatchlistEntity(
            id: watchlist.id,
            name: watchlist.name,
            stocks: stockEntities,
            orderIndex: orderIndex
        )
    }

}
