//
//  WatchlistTabViewModel.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-23.
//

import Foundation
import Combine
@testable import iStocks

final class WatchlistTabViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var watchlists: [Watchlist] = []
    @Published var selectedIndex: Int = 0
    
    // MARK: - Dependencies
    private let persistenceService: WatchlistPersistenceProtocol
    private let availableStocks: [Stock]
    
    // MARK: - ViewModels
    var watchlistViewModels: [WatchlistViewModel] = []

    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init
    init(persistenceService: WatchlistPersistenceProtocol, availableStocks: [Stock]) {
        self.persistenceService = persistenceService
        self.availableStocks = availableStocks
        loadWatchlists()
    }

    // MARK: - Public Methods

    func addWatchlist(_ watchlist: Watchlist) {
        watchlists.append(watchlist)
        let vm = makeViewModel(for: watchlist)
        watchlistViewModels.append(vm)
        persistenceService.saveWatchlist(watchlist)
    }

    func removeWatchlist(_ watchlist: Watchlist) {
        if let index = watchlists.firstIndex(where: { $0.id == watchlist.id }) {
            watchlists.remove(at: index)
            watchlistViewModels.remove(at: index)
            persistenceService.deleteWatchlist(watchlist)
        }
    }

    func updateWatchlist(_ watchlist: Watchlist) {
        if let index = watchlists.firstIndex(where: { $0.id == watchlist.id }) {
            watchlists[index] = watchlist
            watchlistViewModels[index] = makeViewModel(for: watchlist)
            persistenceService.saveWatchlist(watchlist)
        }
    }

    func replaceWatchlists(_ newWatchlists: [Watchlist]) {
        watchlists = newWatchlists
        watchlistViewModels = newWatchlists.map { makeViewModel(for: $0) }
        persistenceService.saveWatchlists(newWatchlists)
    }

    func refreshAll() {
        for vm in watchlistViewModels {
            vm.requestRefresh()
        }
    }

    func getSelectedWatchlist() -> Watchlist {
        return watchlists[selectedIndex]
    }

    // MARK: - Private Methods

    private func loadWatchlists() {
        self.watchlists = persistenceService.loadWatchlists()
        self.watchlistViewModels = watchlists.map { makeViewModel(for: $0) }
    }

    private func makeViewModel(for watchlist: Watchlist) -> WatchlistViewModel {
        WatchlistViewModel(watchlist: watchlist, availableStocks: availableStocks)
    }
}
