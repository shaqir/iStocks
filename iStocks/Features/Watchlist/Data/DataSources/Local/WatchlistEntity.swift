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
    var orderIndex: Int
    
    @Relationship(inverse: \StockEntity.watchlist)
    var stocks: [StockEntity]
    
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
        
        _ = watchlist.stocks.compactMap { StockEntity.from($0) }
        
        guard !watchlist.name.isEmpty else {
            Logger.log("Skipping watchlist with empty name: \(watchlist))", category: "StockEntity")
            return nil
        }
        
        let entity = WatchlistEntity(
            id: watchlist.id,
            name: watchlist.name,
            stocks: [], // temporary placeholder
            orderIndex: orderIndex
        )
        ///To avoid a retain cycle crash while constructing relationships (StockEntity.from(...) needs access to parent WatchlistEntity)
        entity.stocks = watchlist.stocks.compactMap {
            StockEntity.from($0, watchlist: entity)
        }
        
        return entity
    }
}
