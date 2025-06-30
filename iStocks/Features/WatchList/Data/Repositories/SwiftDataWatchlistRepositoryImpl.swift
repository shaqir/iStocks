//
//  SwiftDataWatchlistRepository.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation
import SwiftData

final class SwiftDataWatchlistRepositoryImpl: WatchlistPersistenceRepository {
    func loadSymbols(from context: ModelContext) -> [String] {
        let request = FetchDescriptor<WatchlistStock>()
        return (try? context.fetch(request))?.map { $0.symbol } ?? []
    }

    func add(symbol: String, in context: ModelContext) {
        let entry = WatchlistStock(symbol: symbol, groupName: "My Watchlist", invested: 10000)
        context.insert(entry)
        try? context.save()
    }

    func remove(symbol: String, from context: ModelContext) {
        let request = FetchDescriptor<WatchlistStock>(predicate: #Predicate { $0.symbol == symbol })
        if let entry = try? context.fetch(request).first {
            context.delete(entry)
            try? context.save()
        }
    }
}
