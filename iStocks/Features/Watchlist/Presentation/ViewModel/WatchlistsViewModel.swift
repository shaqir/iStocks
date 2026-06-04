//
//  WatchlistsViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//
import Foundation
import Combine

/// Implicitly @MainActor via defaultIsolation(MainActor.self) — SE-0466
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
    let mode: WatchlistAppMode
    private var viewModelProvider: WatchlistViewModelProvider
    
    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()
    private var isRefreshing = false
    
    private var stockLookup: [String: Stock] = [:]
    
    //MARK: - Only for REST APIs
    @Published var currentBatchProgress: BatchProgress? = nil
    
    /// Emits structural changes to individual watchlists
    let watchlistDidChange = PassthroughSubject<Watchlist, Never>()
    
    private var didSubscribeToWebSocket = false
    
    // MARK: - Init
    init(
        useCases: WatchlistUseCases,
        mode: WatchlistAppMode = AppConfiguration.watchlistMode,
        viewModelProvider: WatchlistViewModelProvider
    ) {
        self.useCases = useCases
        self.mode = mode
        self.viewModelProvider = viewModelProvider
        setupBindings()
    }
    
    private func setupBindings() {
        
        viewModelProvider.watchlistDidUpdate
            .sink { [weak self] updated in
                self?.updateWatchlist(updated)
            }
            .store(in: &cancellables)
        
        //  WebSocket Mode: Subscribe to current tab symbols only
        if mode == .websocket {
            guard !self.didSubscribeToWebSocket else { return }
            self.didSubscribeToWebSocket = true
            observeWebSocketPriceStream()
        }
        
        //  REST API Mode: Subscribe to rest batch call progress
        if mode == .restAPI {
            if let restUseCase = useCases.observeTop50 as? ObserveTop50StocksUseCaseImpl,
               let restRepo = restUseCase.repository as? RestStockRepositoryImpl {
                restRepo.progressPublisher
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] progress in
                        self?.currentBatchProgress = progress
                    }
                    .store(in: &cancellables)
            }
        }
        
    }
    
    func loadWatchlists() {
        isLoading = true
        
        let savedWatchlists = useCases.loadWatchlists.loadWatchlists()
        let savedStocks = useCases.loadWatchlists.loadAllStocks()
        
        if !savedWatchlists.isEmpty
        {
            self.watchlists = savedWatchlists
            self.allFetchedStocks = savedStocks
            
            if watchlists.allSatisfy({ $0.stocks.isEmpty }) {
                rebuildWatchlistsFromMasterStocks()
            }
            
            if mode == .restAPI {
                loadTop50StockPricesFromServer(preservingExisting: true)
            }
        }
        else {
            //First time run
            if mode == .mock {
                loadMockData()
            } else if mode == .restAPI {
                loadTop50StockPricesFromServer(preservingExisting: true)
            }
        }
        
        if mode == .websocket {
            AppLogger.info("WebSocket mode: first run", category: AppLogger.webSocket)
            subscribeToBinanceSymbols()
        }
        
        self.isLoading = false
    }

}

///Mock Mode
extension WatchlistsViewModel {
    
    func startObservingGlobalPriceUpdates() {
        guard mode == .mock else { return }
        useCases.observeMock.execute()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] updatedStocks in
                self?.stockLookup = Dictionary(uniqueKeysWithValues: updatedStocks.map { ($0.symbol, $0) })
                self?.forwardToActiveWatchlists()
            })
            .store(in: &cancellables)
    }
    
    private func forwardToActiveWatchlists() {
        ///This method passing price updates from parent VM to child VMs
        guard watchlists.indices.contains(selectedIndex) else { return }
        
        let selected = watchlists[selectedIndex]
        let relevantStocks = selected.stocks.compactMap { stockLookup[$0.symbol] }
        
        if let vm = viewModelProvider.cachedViewModels.first(where: { $0.watchlist.id == selected.id }) {
            vm.replaceStocks(relevantStocks)
        }
    }
    
    private func loadMockData() {
        self.allFetchedStocks = MockStockData.allStocks
        self.rebuildWatchlistsFromMasterStocks()
        self.saveAllWatchlists()
        self.isLoading = false
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
        executeTop50StockLoad(isManualRefresh: false) { [weak self] newStocks in
            guard let self else { return }

            if preservingExisting {
                self.appendToOrUpdateWatchlist(with: newStocks)
            } else {
                self.allFetchedStocks = newStocks
            }

            self.useCases.saveWatchlists.saveAllStocks(self.allFetchedStocks)

            let previousSelectedID = self.watchlists.indices.contains(self.selectedIndex)
            ? self.watchlists[self.selectedIndex].id : nil

            // Use @concurrent path — 50+ stocks from REST API justify off-MainActor computation
            Task {
                await self.rebuildWatchlistsOffMainActor()
                self.selectedIndex = self.watchlists.firstIndex(where: { $0.id == previousSelectedID }) ?? 0
                self.saveAllWatchlists()
                self.lastUpdated = Date()
                self.isLoading = false
            }
        }
    }
    
    private func executeTop50StockLoad(
        isManualRefresh: Bool = false,
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
                self.isLoading = false
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
    
    /// Rebuilds watchlists synchronously — used for mock data and test setup
    /// where the dataset is small and immediate completion is needed.
    func rebuildWatchlistsFromMasterStocks() {
        self.watchlists = Self.buildWatchlistsSync(
            from: allFetchedStocks,
            existingWatchlists: watchlists
        )
    }

    /// Rebuilds watchlists asynchronously via @concurrent — used for REST/network
    /// paths where 50+ stocks are processed and we want to keep MainActor free.
    func rebuildWatchlistsOffMainActor() async {
        self.watchlists = await Self.buildWatchlists(
            from: allFetchedStocks,
            existingWatchlists: watchlists
        )
    }

    // MARK: - @concurrent Computation (SE-0461)

    /// Pure computation that groups stocks by sector and deduplicates per symbol.
    ///
    /// NOTE (Swift 6.2): @concurrent explicitly runs this on the cooperative thread pool,
    /// NOT on MainActor — even though this class is MainActor-isolated via defaultIsolation.
    /// This is the correct pattern for CPU-intensive work in a ViewModel:
    ///   1. Capture inputs (value types — Stock, Watchlist are Sendable)
    ///   2. Compute off MainActor via @concurrent
    ///   3. Return result to caller, who assigns it back on MainActor
    @concurrent
    private static func buildWatchlists(
        from stocks: [Stock],
        existingWatchlists: [Watchlist]
    ) async -> [Watchlist] {
        buildWatchlistsSync(from: stocks, existingWatchlists: existingWatchlists)
    }

    /// Synchronous implementation shared by both sync and @concurrent paths.
    /// nonisolated because this is a pure computation — no actor state accessed.
    nonisolated private static func buildWatchlistsSync(
        from stocks: [Stock],
        existingWatchlists: [Watchlist]
    ) -> [Watchlist] {
        let grouped = Dictionary(grouping: stocks, by: { stock in
            stock.sector.isEmpty ? "Technology" : stock.sector
        })

        var updated: [Watchlist] = []

        for (sector, stocksInSector) in grouped {
            let deduplicated = Array(
                Dictionary(grouping: stocksInSector, by: \.symbol)
                    .compactMap { $0.value.first }
            )

            if let existingIndex = existingWatchlists.firstIndex(where: { $0.name == sector }) {
                var existing = existingWatchlists[existingIndex]
                existing.stocks = deduplicated
                updated.append(existing)
            } else {
                let newWatchlist = Watchlist(id: UUID(), name: sector, stocks: deduplicated)
                updated.append(newWatchlist)
            }
        }

        return updated
    }
}

// MARK: - Watchlist Modifiers & Persistence Methods

extension WatchlistsViewModel {
    
    func addWatchlist(_ watchlist: Watchlist) {
        guard watchlists.count < AppConstants.maxWatchlists else {
            SharedAlertManager.shared.show(WatchlistValidationError.limitReached.alert)
            return
        }
        watchlists.append(watchlist)
        saveAllWatchlists()
    }
    
    /// Update an existing watchlist and persist changes
    func updateWatchlist(_ updated: Watchlist) {
        if let index = watchlists.firstIndex(where: { $0.id == updated.id }) {
            watchlists[index] = updated
            saveAllWatchlists()
            watchlistDidChange.send(updated) //emit
        }
    }
    
    /// Save all watchlists to persistent storage
    func saveAllWatchlists() {
        useCases.saveWatchlists.saveAll(watchlists)
    }
}

// MARK:- WebSocket Mode

extension WatchlistsViewModel {
    
    func subscribeToBinanceSymbols() {
        guard mode == .websocket else { return }

        // Define the Binance stock
        let binanceSymbol = "BINANCE:BTCUSDT"
        let liveStock = Stock(
            symbol: binanceSymbol,
            name: "Bitcoin / Tether",
            price: 100000,
            previousPrice: 0,
            isPriceUp: true,
            sector: "Crypto",
            currency: "USD",
            exchange: "Binance"
        )
        
        //Case: First time run — create "Crypto" watchlist with Binance stock
        if watchlists.isEmpty {
            let newWatchlist = Watchlist(
                id: UUID(),
                name: "Crypto",
                stocks: [liveStock]
            )
            useCases.saveWatchlists.saveSingle(newWatchlist)
            watchlists.append(newWatchlist)
            selectedIndex = 0
            self.isLoading = false
        }
        
        //  Now get the selected watchlist
        guard watchlists.indices.contains(selectedIndex) else {
            AppLogger.warning("Invalid selectedIndex \(selectedIndex), count: \(watchlists.count)", category: AppLogger.webSocket)
            return
        }
        
        var selectedWatchlist = watchlists[selectedIndex]
        
        // Add Binance stock if not already present
        if !selectedWatchlist.stocks.contains(where: { $0.symbol == binanceSymbol }) {
            selectedWatchlist.stocks.append(liveStock)
            useCases.saveWatchlists.saveSingle(selectedWatchlist)
            watchlists[selectedIndex] = selectedWatchlist
        }
        
        // Subscribe to Binance
        useCases.observeLiveWebSocket.subscribe(to: [binanceSymbol])
    }
    
    func observeWebSocketPriceStream() {
        
    guard mode == .websocket else { return }

    useCases.observeLiveWebSocket
        .execute()
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { _ in },
                receiveValue: { [weak self] updatedStocks in
            guard let self else { return }
            broadcastPricesToAllWatchlists(updatedStocks)
        })
        .store(in: &cancellables)
}
    
    ///This method we can use in future when we subscribe to non-crypto symbols in webSocket
    func subscribeToCurrentTabSymbols() {
        
        guard mode == .websocket else { return }

        guard watchlists.indices.contains(selectedIndex) else {
            AppLogger.warning("Invalid selectedIndex \(selectedIndex), count: \(watchlists.count)", category: AppLogger.webSocket)
            return
        }
        
        let selectedWatchlist = watchlists[selectedIndex]
        /*
         var symbols = selectedWatchlist.stocks.map(\.symbol)
         symbols = MarketHoursHelper.isUSMarketOpen() ? symbols : ["BTC/USD", "ETH/USD", "EUR/USD"]
         */
        
        //For now, websocket supports only following symbol
        let symbols = ["BINANCE:BTCUSDT"]
        
        guard !symbols.isEmpty else {
            AppLogger.warning("No symbols in watchlist: \(selectedWatchlist.name)", category: AppLogger.webSocket)
            return
        }
        
        useCases.observeLiveWebSocket.subscribe(to: symbols)
    }
    
    ///This method we can use in future when we subscribe to non-crypto symbols in webSocket
    private func loadInitialStocksThenStartWebSocket() {
        
        let defaultSymbols: [String] = ["AAPL"]
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
                self.useCases.saveWatchlists.saveAllStocks(stocks)
                self.rebuildWatchlistsFromMasterStocks()
                self.saveAllWatchlists()
                self.isLoading = false
            })
            .store(in: &cancellables)
    }
   
}


