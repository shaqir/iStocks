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
    
    init(id: UUID = UUID(), name: String, stocks: [StockEntity]) {
        self.id = id
        self.name = name
        self.stocks = stocks
    }
}

extension WatchlistEntity {
    func toDomain() -> Watchlist {
        Watchlist(id: id, name: name, stocks: stocks.map { $0.toDomain() })
    }

    static func from(_ watchlist: Watchlist) -> WatchlistEntity? {
        let stockEntities = watchlist.stocks.compactMap { StockEntity.from($0) }

        guard !watchlist.name.isEmpty else {
            print("Skipping watchlist with empty name:", watchlist)
            return nil
        }

        return WatchlistEntity(
            id: watchlist.id,
            name: watchlist.name,
            stocks: stockEntities
        )
    }

}
