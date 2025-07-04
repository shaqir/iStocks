//
//  WatchlistPersistenceService.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-03.
//

import Foundation
import SwiftData

final class WatchlistPersistenceService {
    
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }
    
    func saveWatchlists(_ watchlists: [Watchlist]) {
        clearAll() // prevent duplicates

        for watchlist in watchlists {
            print("Saving watchlist:", watchlist)
            let validStocks = watchlist.stocks.compactMap { StockEntity.from($0) }

            guard !validStocks.isEmpty else {
                print("Skipping empty watchlist:", watchlist.name)
                continue
            }

            let entity = WatchlistEntity(id: watchlist.id, name: watchlist.name, stocks: validStocks)
            context.insert(entity)
        }

        do {
            try context.save()
            print("Watchlists saved successfully.")
        } catch {
            print("Failed to save Watchlists:", error.localizedDescription)
        }
    }
    
    func save(_ watchlist: Watchlist) {
           // Convert and save each stock
           for stock in watchlist.stocks {
               print("Saving stock:", stock)
               if let entity = StockEntity.from(stock){
                   context.insert(entity)
               }
           }
           try? context.save()
       }

    func load() -> [Watchlist] {
        let descriptor = FetchDescriptor<WatchlistEntity>()
        do {
            let results = try context.fetch(descriptor)
            print("Fetched \(results.count) WatchlistEntities")
            return results.map { $0.toDomain() }
        } catch {
            print("Failed to fetch: \(error)")
            return []
        }
    }

    func clearAll() {
        let descriptor = FetchDescriptor<WatchlistEntity>()
        do {
            let results = try context.fetch(descriptor)
            for entity in results {
                context.delete(entity)
            }
            try context.save()
        } catch {
            print("Failed to clear Watchlists:", error.localizedDescription)
        }
    }

    
     
    
}
