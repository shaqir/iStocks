//
//  WatchlistViewModelProvider.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation
import Combine

/// Provides cached WatchlistViewModels for each Watchlist.
/// Manages structural change subscriptions and exposes updates downstream.
final class WatchlistViewModelProvider {
    
    // Cache of WatchlistViewModels by their Watchlist ID (UUID)
    private var cache: [UUID: WatchlistViewModel] = [:]
    
    // Keeps references to Combine subscriptions for each ViewModel
    private var cancellables: [UUID: AnyCancellable] = [:]
    
    /// Injected list of all available stocks (used during ViewModel creation)
    /// This is kept in sync by WatchlistsViewModel
    var allStocks: [Stock] = []
    
    /// Emits structural updates (add/remove stocks, rename watchlist) to the parent
    /// WatchlistsViewModel subscribes to this and updates its internal state
    var watchlistDidUpdate = PassthroughSubject<Watchlist, Never>()
    
    /// Use case for observing live updates for an individual watchlist (REST mode)
    private let useCases: WatchlistUseCases
    
    /// Convenience accessor for testing or diagnostics
    var cachedViewModels: [WatchlistViewModel] {
        cache.values.map { $0 }
    }
    
    /// Dependency Injection of use case
    init(useCases: WatchlistUseCases) {
        self.useCases = useCases
    }
    
    /// Returns a cached WatchlistViewModel or creates a new one if not already cached
    func viewModel(for watchlist: Watchlist) -> WatchlistViewModel {
        // Reuse existing ViewModel if present
        if let existing = cache[watchlist.id] {
            // Sync internal watchlist model if changed externally
            //if existing.watchlist != watchlist {
            existing.updateWatchlist(watchlist)
            //}
            return existing
        }
        
        // Create an observePublisher based on the app mode
        let observePublisher = makeObservePublisher(for: watchlist)
        
        // Create new WatchlistViewModel with correct observePublisher
        let vm = WatchlistViewModel(
            watchlist: watchlist,
            observePublisher: observePublisher,
            availableStocks: allStocks
        )
        
        // Setup Combine pipeline for structural updates
        // Published var watchlist (changes to array or name)
        // when watchlist variable is updated
        let structuralChanges = vm.$watchlist
            .filter { _ in !vm.isPriceOnlyUpdate } // ignore price-only updates
            .eraseToAnyPublisher()
        
        // Passthrough signal from internal logic (e.g., add/remove stock, rename)
        // watchlistStructuralUpdate is likely triggered manually via .send
        let semanticChanges = vm.watchlistStructuralUpdate
            .eraseToAnyPublisher()
        
        // Merge both and send to parent
        let merged = Publishers.Merge(structuralChanges, semanticChanges)
            .handleEvents(receiveOutput: { updated in
                Logger.log("Structural change received for \(updated.name)", category: "WatchlistVMProvider")
            })
        
        cancellables[watchlist.id] = merged
            .sink { [weak self] updated in
                DispatchQueue.main.async {
                    self?.watchlistDidUpdate.send(updated)
                }
            }
        
        // Cache and return
        cache[watchlist.id] = vm
        return vm
    }
    
    func removeViewModel(for id: UUID) {
        cache[id] = nil
        cancellables[id]?.cancel()
        cancellables[id] = nil
    }
    
    // MARK: - Helper Methods
    private func makeObservePublisher(for watchlist: Watchlist) -> AnyPublisher<[Stock], Never> {
        useCases
            .observeWatchlist
            .observeLiveUpdates(for: watchlist)
            .replaceError(with: watchlist.stocks)
            .eraseToAnyPublisher()
    }
}
