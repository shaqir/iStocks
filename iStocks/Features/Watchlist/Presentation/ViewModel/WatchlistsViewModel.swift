//
//  WatchlistsViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//
import Foundation
import Combine

// MARK: - ViewModel

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

    private let useCaseMock: ObserveMockStocksUseCase
    private let useCase50: ObserveTop50StocksUseCase
    private let watchlistUseCase: ObserveWatchlistStocksUseCase
    private let globalPricesUseCase: ObserveGlobalStockPricesUseCase
    
    let persistenceService: WatchlistPersistenceService
    private let viewModelProvider: WatchlistViewModelProvider

    // MARK: - Private State

    private var cancellables = Set<AnyCancellable>()
    private var isRefreshing = false
    
    // MARK: - Subscriptions
    private var livePriceCancellable: AnyCancellable?
    private var liveUpdatesCancellable: AnyCancellable?
    private(set) var isLiveUpdatesActive: Bool = false
     
    // MARK: - Init

    init(
        useCaseMock: ObserveMockStocksUseCase,
        useCase50: ObserveTop50StocksUseCase,
        watchlistUseCase: ObserveWatchlistStocksUseCase,
        globalPricesUseCase: ObserveGlobalStockPricesUseCase,
        persistenceService: WatchlistPersistenceService,
        viewModelProvider: WatchlistViewModelProvider
    ) {
        self.useCaseMock = useCaseMock
        self.useCase50 = useCase50
        self.watchlistUseCase = watchlistUseCase
        self.globalPricesUseCase = globalPricesUseCase
        self.persistenceService = persistenceService
        self.viewModelProvider = viewModelProvider

        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        viewModelProvider.watchlistDidUpdate
            .sink { [weak self] updated in
                self?.updateWatchlist(id: updated.id, with: updated)
            }
            .store(in: &cancellables)
    }

    // MARK: - Live Price Updates
    
    func observeLiveStockPrices() {
        guard WatchlistDIContainer.mode == .mock else { return }
        guard livePriceCancellable == nil else { return }
        
        livePriceCancellable = globalPricesUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] updatedStocks in
                print("price updates")
                self?.broadcastPricesToAllWatchlists(updatedStocks)
            })
    }
    
    private func broadcastPricesToAllWatchlists(_ stocks: [Stock]) {
        for vm in viewModelProvider.cachedViewModels {
            vm.replaceStocks(stocks)
        }
    }
     
    // MARK: - Public Methods

    func loadWatchlists() {
        isLoading = true

        let savedWatchlists = persistenceService.load()

        if !savedWatchlists.isEmpty {
            self.watchlists = savedWatchlists
            self.allFetchedStocks = persistenceService.loadAllStocks()

            if watchlists.isEmpty {
                rebuildWatchlistsFromMasterStocks()
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.isLoading = false
            }


        } else {
            if WatchlistDIContainer.mode == .mock {
                loadMockData()
            } else {
                loadTop50StockPricesFromServer()
            }
        }
    }

    func refresh() {
        print("Manual refresh called...")
        guard WatchlistDIContainer.mode == .restAPI else { return }
        executeTop50StockLoad(isManualRefresh: true, delay: 3.0)
    }

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

    // MARK: - Mock Mode

    private func loadMockData() {
        self.allFetchedStocks = MockStockData.allStocks
        self.rebuildWatchlistsFromMasterStocks()

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.isLoading = false
        }
    }

    // MARK: - REST API Mode

    func loadTop50StockPricesFromServer() {
        print("Initial top 50 fetch")
        executeTop50StockLoad(isManualRefresh: false, delay: 3.0)
    }

    private func executeTop50StockLoad(
        isManualRefresh: Bool = false,
        delay: TimeInterval = 1.0
    ) {
        if isManualRefresh {
            guard !isRefreshing else { return }
            isRefreshing = true
        }

        isLoading = true
        errorMessage = nil
        isFirstBatchReceived = false

        useCase50.execute()
            .retry(isManualRefresh ? 1 : 0)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }

                if isManualRefresh {
                    self.isRefreshing = false
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.isLoading = false
                }

                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }

            }, receiveValue: { [weak self] stocks in
                guard let self = self else { return }

                print(" Loaded \(stocks.count) stocks (\(isManualRefresh ? "refresh" : "initial"))")

                self.appendToOrUpdateWatchlist(with: stocks)
                self.persistenceService.saveAllStocks(self.allFetchedStocks)

                let previousSelectedID = self.watchlists.indices.contains(self.selectedIndex)
                    ? self.watchlists[self.selectedIndex].id
                    : nil

                self.rebuildWatchlistsFromMasterStocks()

                if let previousID = previousSelectedID,
                   let newIndex = self.watchlists.firstIndex(where: { $0.id == previousID }) {
                    self.selectedIndex = newIndex
                } else {
                    self.selectedIndex = 0
                }

                self.saveAllWatchlists()
                self.lastUpdated = Date()
                self.isLoading = false
            })
            .store(in: &cancellables)
    }

    // MARK: - Watchlist Helpers

    private func appendToOrUpdateWatchlist(with newStocks: [Stock]) {
        for stock in newStocks {
            if let index = allFetchedStocks.firstIndex(where: { $0.symbol == stock.symbol }) {
                allFetchedStocks[index] = stock
            } else {
                allFetchedStocks.append(stock)
            }
        }
    }

    private func rebuildWatchlistsFromMasterStocks() {
        let grouped = Dictionary(grouping: allFetchedStocks.filter { !$0.sector.isEmpty }, by: \.sector)

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
