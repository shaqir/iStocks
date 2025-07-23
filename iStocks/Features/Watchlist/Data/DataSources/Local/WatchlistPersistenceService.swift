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
    init(context: ModelContext) { self.context = context }
}

extension WatchlistPersistenceService {
    
    // MARK: - Watchlist Persistence

    func loadWatchlists() -> [Watchlist] {
        var descriptor = FetchDescriptor<WatchlistEntity>()
        descriptor.sortBy = [SortDescriptor(\.orderIndex)]
        do {
            let results = try context.fetch(descriptor)
            return results.map { $0.toDomain() }
        } catch {
            return []
        }
    }

    func saveWatchlists(_ watchlists: [Watchlist]) {
        clearWatchlists()
        
        for (index, watchlist) in watchlists.enumerated() {
            let validStocks = watchlist.stocks.compactMap { StockEntity.from($0) }
            guard !validStocks.isEmpty else {
                continue
            }
            let entity = WatchlistEntity(
                id: watchlist.id,
                name: watchlist.name,
                stocks: validStocks,
                orderIndex: index
            )
            context.insert(entity)
        }
        
        do {
            try context.save()
            Logger.log("Watchlists saved successfully.")
            
        } catch {
            Logger.log("Failed to save Watchlists:\(error.localizedDescription)")
        }
    }

    func updateWatchlist(_ updated: Watchlist) {
        let watchlistID = updated.id
        
        let descriptor = FetchDescriptor<WatchlistEntity>(
            predicate: #Predicate { $0.id == watchlistID },
            sortBy: [SortDescriptor(\.orderIndex)]
        )
        
        if let entity = try? context.fetch(descriptor).first {
            entity.name = updated.name
            entity.stocks = updated.stocks.compactMap { StockEntity.from($0) }
            do {
                try context.save()
            } catch {
                Logger.log("Failed to save context: \(error.localizedDescription)")
            }
        }
    }

    func clearWatchlists() {
        let descriptor = FetchDescriptor<WatchlistEntity>()
        do {
            let results = try context.fetch(descriptor)
            for entity in results {
                context.delete(entity)
            }
            try context.save()
        } catch {
            Logger.log("Failed to clear Watchlists: \(error.localizedDescription)")
        }
    }
    
}

// MARK: - All Stocks Persistence : REST API Stocks

extension WatchlistPersistenceService {

    func saveAllStocks(_ stocks: [Stock]) {
        // Optional: Clear previous to avoid duplicates
        clearAllStocks()

        for stock in stocks {
            if let entity = StockEntity.from(stock) {
                context.insert(entity)
            }
        }

        do {
            try context.save()
            print("All stocks saved successfully.")
        } catch {
            print("Failed to save all stocks:", error.localizedDescription)
        }
    }

    func loadAllStocks() -> [Stock] {
        let descriptor = FetchDescriptor<StockEntity>()
        do {
            let results = try context.fetch(descriptor)
            return results.map { $0.toDomain() }
        } catch {
            Logger.log("Failed to load all stocks: \(error.localizedDescription)")
            return []
        }
    }

    func clearAllStocks() {
        let descriptor = FetchDescriptor<StockEntity>()
        do {
            let results = try context.fetch(descriptor)
            for stock in results {
                context.delete(stock)
            }
            try context.save()
        } catch {
            Logger.log("Failed to clear stock entities: \(error.localizedDescription)")
        }
    }
    
}
 
// MARK: - WebSocket mode

extension WatchlistPersistenceService{
    
    
}
