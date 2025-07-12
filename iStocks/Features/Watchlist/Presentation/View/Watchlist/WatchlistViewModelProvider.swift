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
    
    // Relay downstream
    var watchlistDidUpdate = PassthroughSubject<Watchlist, Never>()
    
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
        
        let vm = WatchlistViewModel(
            watchlist: watchlist,
            observeUseCase: observeUseCase
        )
        
        // Combine both publishers: structural (@Published) and semantic (Passthrough)
        let structuralChanges = vm.$watchlist
            .filter { _ in !vm.isPriceOnlyUpdate } //  block price-only updates
            .eraseToAnyPublisher()
        
        let semanticChanges = vm.watchlistStructuralUpdate
            .eraseToAnyPublisher()
        
        let merged = Publishers.Merge(structuralChanges, semanticChanges)
            .handleEvents(receiveOutput: { updated in
                print("Structural change received for \(updated.name)")
            })
        
        cancellables[watchlist.id] = merged
            .sink { [weak self] updated in
                DispatchQueue.main.async {
                            self?.watchlistDidUpdate.send(updated)
                        }
            }
        
        cache[watchlist.id] = vm
        return vm
    }
    
}
