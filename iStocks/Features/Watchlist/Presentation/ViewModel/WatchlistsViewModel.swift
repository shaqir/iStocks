//
//  WatchlistsViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//
import Foundation
import Combine

final class WatchlistsViewModel: ObservableObject {
    @Published var watchlists: [Watchlist] = []
    @Published var selectedIndex: Int = 0
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    private let useCase: ObserveStocksUseCase
    private var cancellables = Set<AnyCancellable>()
    
    let persistenceService: WatchlistPersistenceService
    
    private let viewModelProvider: WatchlistViewModelProvider
    
    init(useCase: ObserveStocksUseCase,
         persistenceService: WatchlistPersistenceService,
         viewModelProvider: WatchlistViewModelProvider) {
        self.useCase = useCase
        self.persistenceService = persistenceService
        self.viewModelProvider = viewModelProvider
        
        viewModelProvider.watchlistDidUpdate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updated in
                DispatchQueue.main.async {
                    self?.updateWatchlist(id: updated.id, with: updated)
                }
            }
            .store(in: &cancellables)
    }
    
    func loadWatchlists() {
        isLoading = true
        
        let saved = persistenceService.load()
        if !saved.isEmpty {
            self.watchlists = saved
            self.isLoading = false
        } else {
            loadFromServer()
        }
    }
    
    func loadFromServer() {
        useCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
                }
            } receiveValue: { [weak self] stocks in
                self?.initializeWatchlists(with: stocks)
                if WatchlistDIContainer.mode == .restAPI {
                    self?.saveAllWatchlists()
                }
            }
            .store(in: &cancellables)
    }
    
    private func initializeWatchlists(with stocks: [Stock]) {
        let grouped = Dictionary(grouping: stocks, by: \.sector)
        let limitedSectors = grouped.sorted(by: { $0.key.count < $1.key.count }).prefix(20)
        
        var final: [Watchlist] = []
        
        for (sector, stocks) in limitedSectors {
            var seen = Set<String>()
            var unique: [Stock] = []
            for stock in stocks {
                if !seen.contains(stock.symbol) {
                    unique.append(stock)
                    seen.insert(stock.symbol)
                }
                if unique.count == 50 { break }
            }
            final.append(Watchlist(id: UUID(), name: sector, stocks: unique))
        }
        
        self.watchlists = final
        persistenceService.saveWatchlists(final)
    }
    
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
    
    func saveAllWatchlists() {
        persistenceService.saveWatchlists(watchlists)
    }
    
}
