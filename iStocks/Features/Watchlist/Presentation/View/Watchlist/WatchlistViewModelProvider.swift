//
//  WatchlistViewModelProvider.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation
import Combine

final class WatchlistViewModelProvider {
    private var cache: [UUID: WatchlistViewModel] = [:]
    private var cancellables: [UUID: AnyCancellable] = [:]
    
    var watchlistDidUpdate = PassthroughSubject<Watchlist, Never>() // Relay downstream
    
    private let observeUseCase: any ObserveWatchlistStocksUseCase
    
    init(observeUseCase: any ObserveWatchlistStocksUseCase) {
        self.observeUseCase = observeUseCase
    }
    func viewModel(for watchlist: Watchlist) -> WatchlistViewModel {
        if let existing = cache[watchlist.id] {
            // Update the ViewModel's internal watchlist if the input differs
            if existing.watchlist != watchlist {
                existing.updateWatchlist(watchlist)
            }
            return existing
        }
        
        let vm = WatchlistViewModel(watchlist: watchlist, observeUseCase: observeUseCase)
        
        // Combine both publishers: $watchlist (structural changes), and watchlistDidUpdate (semantic changes)
        let publisher = Publishers.Merge(
            vm.$watchlist.dropFirst(),
            vm.watchlistDidUpdate
        )
        
        cancellables[watchlist.id] = publisher
            .sink { [weak self] updated in
                self?.watchlistDidUpdate.send(updated)
            }
        
        cache[watchlist.id] = vm
        return vm
    }
    
}
