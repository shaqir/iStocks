//
//  WatchlistsViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//
import Foundation
import Combine

///Core (Base)
final class WatchlistsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var watchlists: [Watchlist] = []
    @Published var selectedIndex: Int = 0
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var isFirstBatchReceived: Bool = false
    @Published var lastUpdated: Date?
    @Published var allFetchedStocks: [Stock] = [] {
        didSet { viewModelProvider.allStocks = allFetchedStocks }
    }
    
    // MARK: - Dependencies
    let useCases: WatchlistUseCases
    let persistenceService: WatchlistPersistenceService
    private let viewModelProvider: WatchlistViewModelProvider
    
    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()
    private var isRefreshing = false
    private var livePriceCancellable: AnyCancellable?
    private var liveUpdatesCancellable: AnyCancellable?
    
    // MARK: - Init
    init(
        useCases: WatchlistUseCases,
        persistenceService: WatchlistPersistenceService,
        viewModelProvider: WatchlistViewModelProvider
    ) {
        self.useCases = useCases
        self.persistenceService = persistenceService
        self.viewModelProvider = viewModelProvider
        setupBindings()
    }
    
    deinit {
        livePriceCancellable?.cancel()
    }
    
    private func setupBindings() {
        
        viewModelProvider.watchlistDidUpdate
            .sink { [weak self] updated in
                self?.updateWatchlist(id: updated.id, with: updated)
            }
            .store(in: &cancellables)
        
        //  WebSocket Mode: Subscribe to current tab symbols only
        if WatchlistDIContainer.mode == .websocket {
                 Publishers.CombineLatest($watchlists,  $selectedIndex)
                    .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
                    .sink { [weak self] watchlists, _ in
                        guard let self = self, !watchlists.isEmpty else { return }
                        self.subscribeToCurrentTabSymbols()
                    }
                    .store(in: &cancellables)
        }
    }

    func loadWatchlists() {
    isLoading = true
    
    let savedWatchlists = persistenceService.loadWatchlists()
    let savedStocks = persistenceService.loadAllStocks()
    
    if !savedWatchlists.isEmpty {
        self.watchlists = savedWatchlists
        self.allFetchedStocks = savedStocks
        
        if watchlists.allSatisfy({ $0.stocks.isEmpty }) {
            rebuildWatchlistsFromMasterStocks()
        }
        
        if WatchlistDIContainer.mode == .mock {
            observeMockGlobalPriceStream()
        }
        else if(WatchlistDIContainer.mode == .restAPI){
            loadTop50StockPricesFromServer(preservingExisting: true)
        }
        else if WatchlistDIContainer.mode == .websocket {
            Logger.log("WebSocket Mode enabled", category: "WebSocket")
           // observeWebSocketGlobalPriceStream()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
        }
        
    } else {
        //First time run
        if WatchlistDIContainer.mode == .mock {
            loadMockData()
        } else if WatchlistDIContainer.mode == .restAPI {
            loadTop50StockPricesFromServer(preservingExisting: true)
        }
        else if WatchlistDIContainer.mode == .websocket {
            Logger.log("WebSocket Mode enabled: First Run", category: "WebSocket")
            loadInitialStocksThenStartWebSocket()
        }
    }
}

}

///Mock Mode
extension WatchlistsViewModel {
    
    func observeMockGlobalPriceStream() {
        guard livePriceCancellable == nil else { return }
        livePriceCancellable = useCases.observeMock.execute()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] updatedStocks in
                guard let self else { return }
                broadcastPricesToAllWatchlists(updatedStocks)
            })
    }
    
    private func loadMockData() {
        self.allFetchedStocks = MockStockData.allStocks
        self.rebuildWatchlistsFromMasterStocks()
        self.saveAllWatchlists()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
        }
    }
    
    private func broadcastPricesToAllWatchlists(_ stocks: [Stock]) {
        for vm in viewModelProvider.cachedViewModels {
            vm.replaceStocks(stocks)
        }
    }
}


///RestAPI Mode
extension WatchlistsViewModel {
    
    func loadTop50StockPricesFromServer(preservingExisting: Bool) {
        executeTop50StockLoad(isManualRefresh: false, delay: 1.5) { [weak self] newStocks in
            guard let self else { return }
            
            if preservingExisting {
                self.appendToOrUpdateWatchlist(with: newStocks)
            } else {
                self.allFetchedStocks = newStocks
            }
            
            self.persistenceService.saveAllStocks(self.allFetchedStocks)
            
            let previousSelectedID = self.watchlists.indices.contains(self.selectedIndex)
            ? self.watchlists[self.selectedIndex].id : nil
            
            self.rebuildWatchlistsFromMasterStocks()
            
            self.selectedIndex = self.watchlists.firstIndex(where: { $0.id == previousSelectedID }) ?? 0
            self.saveAllWatchlists()
            self.lastUpdated = Date()
            self.isLoading = false
        }
    }
    
    private func executeTop50StockLoad(
        isManualRefresh: Bool = false,
        delay: TimeInterval = 1.0,
        completion: @escaping ([Stock]) -> Void
    ) {
        if isManualRefresh {
            guard !isRefreshing else { return }
            isRefreshing = true
        }
        
        useCases.observeTop50.execute()
            .retry(isManualRefresh ? 1 : 0)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completionResult in
                guard let self else { return }
                if isManualRefresh { self.isRefreshing = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.isLoading = false
                }
                if case .failure(let error) = completionResult {
                    self.errorMessage = error.localizedDescription
                }
            }, receiveValue: completion)
            .store(in: &cancellables)
    }
    
    /// Appends new stocks or updates existing ones in allFetchedStocks
    func appendToOrUpdateWatchlist(with newStocks: [Stock]) {
        for stock in newStocks {
            if let index = allFetchedStocks.firstIndex(where: { $0.symbol == stock.symbol }) {
                allFetchedStocks[index] = stock
            } else {
                allFetchedStocks.append(stock)
            }
        }
    }
    
    /// Rebuilds the watchlists grouped by sector from allFetchedStocks
    func rebuildWatchlistsFromMasterStocks() {
        
        let grouped = Dictionary(grouping: allFetchedStocks, by: { stock in
                stock.sector.isEmpty ? "Technology" : stock.sector
            })
        
        var updated: [Watchlist] = []
        
        for (sector, stocksInSector) in grouped {
            let deduplicated = Array(
                Dictionary(grouping: stocksInSector, by: \.symbol)
                    .compactMap { $0.value.first }
            )
            
            if let existingIndex = watchlists.firstIndex(where: { $0.name == sector }) {
                var existing = watchlists[existingIndex]
                existing.stocks = deduplicated
                updated.append(existing)
            } else {
                let newWatchlist = Watchlist(id: UUID(), name: sector, stocks: deduplicated)
                updated.append(newWatchlist)
            }
        }
        
        self.watchlists = updated
    }
}

// MARK: - Watchlist Modifiers & Persistence Methods

extension WatchlistsViewModel {
    
    func addWatchlist(id: UUID, with newWatchlist: Watchlist) {
        watchlists.append(newWatchlist)
        saveAllWatchlists()
    }
    
    /// Update an existing watchlist and persist changes
    func updateWatchlist(id: UUID, with updated: Watchlist) {
        if let index = watchlists.firstIndex(where: { $0.id == id }) {
            watchlists[index] = updated
            persistenceService.updateWatchlist(updated)
        }
    }
    
    /// Save all watchlists to persistent storage
    func saveAllWatchlists() {
        persistenceService.saveWatchlists(watchlists)
    }
}

// MARK:- WebSocket Mode

extension WatchlistsViewModel {
    
    private func loadInitialStocksThenStartWebSocket() {
        
        let defaultSymbols: [String] = ["AAPL", "TSLA", "GOOGL", "MSFT", "NVDA"]
        
        useCases.fetchQuotesBySymbols.execute(for: defaultSymbols)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                }
            }, receiveValue: { [weak self] stocks in
                
                guard let self else { return }
                
                self.allFetchedStocks = stocks
                self.persistenceService.saveAllStocks(stocks)
                self.rebuildWatchlistsFromMasterStocks()
                self.saveAllWatchlists()
                //self.observeWebSocketGlobalPriceStream()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    //self.subscribeToCurrentTabSymbols()
                }
                self.isLoading = false
            })
            .store(in: &cancellables)
    }
    
    private func observeWebSocketGlobalPriceStream() {
        useCases.observeLiveWebSocket
            .execute()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] updatedStocks in
                guard let self else { return }
                Logger.log("WebSocket updated \(updatedStocks.count) stocks", category: "WebSocket")
                broadcastPricesToAllWatchlists(updatedStocks)
                //persistenceService.updatePrices(for: updatedStocks, shouldUpdatePreviousPrice: true)
            })
            .store(in: &cancellables)
    }
    
    func subscribeToCurrentTabSymbols() {
       
        guard WatchlistDIContainer.mode == .websocket else { return }

        guard watchlists.indices.contains(selectedIndex) else {
            Logger.log("Invalid selectedIndex: \(selectedIndex). Watchlists count: \(watchlists.count)", category: "WebSocket")
            return
        }

        let selectedWatchlist = watchlists[selectedIndex]
        var symbols = selectedWatchlist.stocks.map(\.symbol)
        //TESTING
        symbols.append("BTC/USD")

        guard !symbols.isEmpty else {
            Logger.log("No symbols in watchlist: \(selectedWatchlist.name) [\(selectedWatchlist.id)]", category: "WebSocket")
            return
        }

        Logger.log("Subscribing to \(symbols.count) symbols for tab \(selectedWatchlist.name)", category: "WebSocket")
        useCases.observeLiveWebSocket.subscribe(to: symbols)
    }
    
}
