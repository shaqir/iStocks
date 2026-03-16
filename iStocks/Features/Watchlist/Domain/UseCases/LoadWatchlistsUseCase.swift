//
//  LoadWatchlistsUseCase.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-15.
//

import Foundation

protocol LoadWatchlistsUseCase {
    func loadWatchlists() -> [Watchlist]
    func loadAllStocks() -> [Stock]
}

final class LoadWatchlistsUseCaseImpl: LoadWatchlistsUseCase {
    private let persistenceService: WatchlistPersistenceProtocol

    init(persistenceService: WatchlistPersistenceProtocol) {
        self.persistenceService = persistenceService
    }

    func loadWatchlists() -> [Watchlist] {
        persistenceService.loadWatchlists()
    }

    func loadAllStocks() -> [Stock] {
        persistenceService.loadAllStocks()
    }
}
