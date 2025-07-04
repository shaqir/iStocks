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
    let persistenceService: WatchlistPersistenceService
    
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
        
        self.watchlists = [
            Watchlist(name: "Tech Giants", stocks: stocks),
            Watchlist(name: "Nifty 50", stocks: stocks.shuffled()),
            Watchlist(name: "US Energy", stocks: stocks.shuffled()),
            Watchlist(name: "European Stocks", stocks: stocks.shuffled()),
            Watchlist(name: "Japanese Stocks", stocks: stocks.shuffled()),
            Watchlist(name: "Indian Stocks", stocks: stocks.shuffled()),
            Watchlist(name: "Australian Stocks", stocks: stocks.shuffled()),
            Watchlist(name: "British Stocks", stocks: stocks.shuffled()),
            Watchlist(name: "Canadian Stocks", stocks: stocks.shuffled()),
            Watchlist(name: "South African Stocks", stocks: stocks.shuffled()),
        ]
        
        if WatchlistDIContainer.mode == .live {
            persistenceService.saveWatchlists(self.watchlists)
        }
        
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
        persistenceService.clearAll()
        persistenceService.saveWatchlists(watchlists)
    }
    
    //Update single watchlist
    func updateWatchlist(id: UUID, with updated: Watchlist) {
        if let index = watchlists.firstIndex(where: { $0.id == id }) {
            watchlists[index] = updated
            persistenceService.saveWatchlists(watchlists)
        }
    }
    
    func moveWatchlist(from source: IndexSet, to destination: Int) {
        watchlists.move(fromOffsets: source, toOffset: destination)
        saveAllWatchlists()
    }

}
