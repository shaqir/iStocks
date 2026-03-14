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

protocol WatchlistPersistenceProtocol {
    func loadWatchlists() -> [Watchlist]
    func saveWatchlists(_ watchlists: [Watchlist])
    func saveWatchlist(_ watchlist: Watchlist)
    func deleteWatchlist(_ watchlist: Watchlist)
    func clearWatchlists()
    
    // Add these for REST repo
    func loadAllStocks() -> [Stock]
    func saveAllStocks(_ stocks: [Stock])
    func clearAllStocks()
}

extension WatchlistPersistenceService: WatchlistPersistenceProtocol{
    
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
            AppLogger.info("Watchlists saved successfully", category: AppLogger.persistence)
            
        } catch {
            AppLogger.error("Failed to save Watchlists", category: AppLogger.persistence, error: error)
        }
    }

    func saveWatchlist(_ watchlist: Watchlist) {
        guard !watchlist.stocks.isEmpty else { return }

        let entity = WatchlistEntity(
            id: watchlist.id,
            name: watchlist.name,
            stocks: watchlist.stocks.compactMap { StockEntity.from($0) },
            orderIndex: 0
        )
        context.insert(entity)
        do {
            try context.save()
        } catch {
            AppLogger.error("Failed to save single watchlist", category: AppLogger.persistence, error: error)
        }
    }

    func replaceAll(with newWatchlists: [Watchlist]) {
        saveWatchlists(newWatchlists)
    }
    
    func updateWatchlist(_ updated: Watchlist) {
        let id = updated.id
        let descriptor = FetchDescriptor<WatchlistEntity>(predicate: #Predicate { $0.id == id })

        do {
            if let existing = try context.fetch(descriptor).first {
                existing.name = updated.name
                existing.stocks = updated.stocks.compactMap { StockEntity.from($0) }
                try context.save()
            }
        } catch {
            AppLogger.error("Failed to update watchlist", category: AppLogger.persistence, error: error)
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
            AppLogger.error("Failed to clear Watchlists", category: AppLogger.persistence, error: error)
        }
    }
    
    func deleteWatchlist(_ watchlist: Watchlist) {
        let idToDelete = watchlist.id
        let descriptor = FetchDescriptor<WatchlistEntity>(
            predicate: #Predicate { $0.id == idToDelete }
        )
        do {
            if let entity = try context.fetch(descriptor).first {
                context.delete(entity)
                try context.save()
            }
        } catch {
            AppLogger.error("Failed to delete watchlist", category: AppLogger.persistence, error: error)
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
            AppLogger.info("All stocks saved successfully", category: AppLogger.persistence)
        } catch {
            AppLogger.error("Failed to save all stocks", category: AppLogger.persistence, error: error)
        }
    }

    func loadAllStocks() -> [Stock] {
        let descriptor = FetchDescriptor<StockEntity>()
        do {
            let results = try context.fetch(descriptor)
            return results.map { $0.toDomain() }
        } catch {
            AppLogger.error("Failed to load all stocks", category: AppLogger.persistence, error: error)
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
            AppLogger.error("Failed to clear stock entities", category: AppLogger.persistence, error: error)
        }
    }
    
}
  
