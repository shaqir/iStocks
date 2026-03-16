//
//  SaveWatchlistsUseCase.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-15.
//

import Foundation

protocol SaveWatchlistsUseCase {
    func saveAll(_ watchlists: [Watchlist])
    func saveSingle(_ watchlist: Watchlist)
    func saveAllStocks(_ stocks: [Stock])
}

final class SaveWatchlistsUseCaseImpl: SaveWatchlistsUseCase {
    private let persistenceService: WatchlistPersistenceProtocol

    init(persistenceService: WatchlistPersistenceProtocol) {
        self.persistenceService = persistenceService
    }

    func saveAll(_ watchlists: [Watchlist]) {
        persistenceService.saveWatchlists(watchlists)
    }

    func saveSingle(_ watchlist: Watchlist) {
        persistenceService.saveWatchlist(watchlist)
    }

    func saveAllStocks(_ stocks: [Stock]) {
        persistenceService.saveAllStocks(stocks)
    }
}
