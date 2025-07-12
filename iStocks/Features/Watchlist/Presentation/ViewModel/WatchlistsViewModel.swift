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
    @Published var isFirstBatchReceived: Bool = false
    
    private let useCaseMock: ObserveMockStocksUseCase
    private let useCase50: ObserveTop50StocksUseCase
    
    private var cancellables = Set<AnyCancellable>()
    
    let persistenceService: WatchlistPersistenceService
    
    private let viewModelProvider: WatchlistViewModelProvider
    
    @Published private(set) var stocks: [Stock] = [] // for the top 50 live updates
    
    private let watchlistUseCase: ObserveWatchlistStocksUseCase
    
    //MARK: Init
    init(useCaseMock: ObserveMockStocksUseCase,
         useCase50: ObserveTop50StocksUseCase,
         watchlistUseCase: ObserveWatchlistStocksUseCase,
         persistenceService: WatchlistPersistenceService,
         viewModelProvider: WatchlistViewModelProvider) {
        self.useCaseMock = useCaseMock
        self.useCase50 = useCase50
        self.watchlistUseCase = watchlistUseCase
        self.persistenceService = persistenceService
        self.viewModelProvider = viewModelProvider
        
        viewModelProvider.watchlistDidUpdate
            .sink { [weak self] updated in
                    self?.updateWatchlist(id: updated.id, with: updated)
            }
            .store(in: &cancellables)
    }
    
    //MARK: Load watchlists
    
    func loadWatchlists() {
        isLoading = true
        
        let saved = persistenceService.load()
        if !saved.isEmpty {
            self.watchlists = saved
            self.stocks = saved.flatMap { $0.stocks }
            if watchlists.isEmpty {
                self.rebuildWatchlistsFromMasterStocks() // only once at start
            }
            self.isLoading = false
            if WatchlistDIContainer.mode == .mock {
                ///observeMockLiveUpdates() //Begin simulation after loading persisted stocks
            }
        } else {
            if WatchlistDIContainer.mode == .mock {
                loadMockData()
            }
            else {
                loadTop50StockPricesFromServer()
            }
        }
    }
    
    //MARK: Mock Methods
    
    private func loadMockData() {
        self.stocks = MockStockData.allStocks
        self.rebuildWatchlistsFromMasterStocks() // Just once on first load
        //self.observeMockLiveUpdates()            // Price simulation only
    }
    
    private func observeMockLiveUpdates() {
        useCaseMock.observe()
            .sink { completion in
                if case .failure(let error) = completion {
                    print("Live mock update failed: \(error)")
                }
            } receiveValue: { [weak self] updatedStocks in
                guard let self = self else { return }
                self.isLoading = false
                self.stocks = updatedStocks
                for i in watchlists.indices {
                    let updated = updatedStocks.filter { new in
                        self.watchlists[i].stocks.contains(where: { $0.symbol == new.symbol })
                    }
                    watchlists[i].stocks = updated
                }
            }
            .store(in: &cancellables)
    }
    
    //MARK: REST API Methods
    
    func loadTop50StockPricesFromServer() {
        isLoading = true
        isFirstBatchReceived = false
        
        useCase50.execute()
            .receive(on: DispatchQueue.main) // UI updates ONLY on main thread
            .sink { [weak self] completion in
                self?.isLoading = false // always stop spinner regardless of success/failure
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] stocks in
                print("Received \(stocks.count) stocks")
                guard let self = self else { return }
                if !isFirstBatchReceived {
                    self.isLoading = false
                    self.isFirstBatchReceived = true
                }
                self.appendToOrUpdateWatchlist(with: stocks)
                if watchlists.isEmpty {
                    self.rebuildWatchlistsFromMasterStocks()
                }
                self.saveAllWatchlists()
            }
            .store(in: &cancellables)
    }
    
    private func appendToOrUpdateWatchlist(with newStocks: [Stock]) {
        for stock in newStocks {
            if let index = self.stocks.firstIndex(where: { $0.symbol == stock.symbol }) {
                self.stocks[index] = stock // update
            } else {
                self.stocks.append(stock) // add
            }
        }
    }
    
    private func rebuildWatchlistsFromMasterStocks() {
        let grouped = Dictionary(grouping: stocks.filter { !$0.sector.isEmpty }, by: \.sector)
        let sorted = grouped.sorted(by: { $0.key.count < $1.key.count }).prefix(10)
        let updatedWatchlists = sorted.map { (sector, stocks) -> Watchlist in
            return Watchlist(id: UUID(), name: sector, stocks: Array(stocks))
        }
        self.watchlists = updatedWatchlists
    }
    
    //MARK: Helper ViewModel Methods
    func addWatchlist(id: UUID, with newWatchlist: Watchlist) {
        watchlists.append(newWatchlist)
        saveAllWatchlists()
    }
    
    func updateWatchlist(id: UUID, with updated: Watchlist) {
        if let index = watchlists.firstIndex(where: { $0.id == id }) {
            watchlists[index] = updated
            persistenceService.updateWatchlist(updated)
        }
    }
    
    func saveAllWatchlists() {
        persistenceService.saveWatchlists(watchlists)
    }
    
}

