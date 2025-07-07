//
//  WatchlistsViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation
import Combine

final class WatchlistsViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    private let useCase: ObserveStocksUseCase
    private var cancellables = Set<AnyCancellable>()
    
    // Injected : SwiftData
    var persistenceService: WatchlistPersistenceService
    
    @Published var watchlists: [Watchlist] = []
    @Published var selectedIndex: Int = 0
    
    
    init(useCase: ObserveStocksUseCase, persistenceService: WatchlistPersistenceService){
        self.useCase = useCase
        self.persistenceService = persistenceService
    }
    
    func loadWatchlists() {
        
        isLoading = true
        
        // Load from local storage
        let saved = persistenceService.load()
        if !saved.isEmpty {
            self.watchlists = saved
            self.isLoading = false
            return
        }
        
        // Fallback to remote (use case)
        loadFromServer()
        
    }
    
    private func initializeWatchlists(with stocks: [Stock]) {
        // Group stocks by sector
        let grouped = Dictionary(grouping: stocks, by: { $0.sector })

        // Limit to 10 sectors
        let limitedSectors = grouped
            .sorted(by: { $0.key.count < $1.key.count })
            .prefix(10)

        // Create watchlists per sector, capping stocks to 50
        let sectorWatchlists = limitedSectors.map { sector, sectorStocks in
            let limitedStocks = Array(sectorStocks.prefix(50))
            return Watchlist(name: sector, stocks: limitedStocks)
        }

        self.watchlists = Array(sectorWatchlists)
        persistenceService.saveWatchlists(self.watchlists)
    }

    
    func loadFromServer() {
        useCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    let message = (error as? LocalizedError)?.errorDescription ?? "Please try again later."
                    self?.errorMessage = message
                }
            } receiveValue: { [weak self] stocks in
                self?.initializeWatchlists(with: stocks)
                //only save remote data
                if WatchlistDIContainer.mode == .live {
                    self?.persistenceService.saveWatchlists(self?.watchlists ?? [])
                }
            }
            .store(in: &cancellables)
    }
    
    func saveAllWatchlists() {
        persistenceService.saveWatchlists(watchlists)
    }
    
    //Update single watchlist
    func updateWatchlist(id: UUID, with updated: Watchlist) {
        if let index = watchlists.firstIndex(where: { $0.id == id }) {
            watchlists[index] = updated
            persistenceService.updateWatchlist(updated)
        }
    }
    
    func moveWatchlist(from source: IndexSet, to destination: Int) {
        watchlists.move(fromOffsets: source, toOffset: destination)
        saveAllWatchlists()
    }
    
}
