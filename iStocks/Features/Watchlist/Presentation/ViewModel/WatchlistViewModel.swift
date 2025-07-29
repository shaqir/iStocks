//
//  WatchlistViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//
import Foundation
import Combine

/// ViewModel for managing a single watchlist (stocks, search, updates, sync)
final class WatchlistViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var watchlist: Watchlist
    @Published var searchText: String = ""
    @Published var errorMessage: String?
    @Published var animatedSymbols: Set<String> = []
    @Published var availableStocks: [Stock]
    
    // MARK: - Derived Properties
    
    var selectedStocks: [Stock] {
        watchlist.stocks
    }
    
    var filteredStocks: [Stock] {
        guard !searchText.isEmpty else {
            return selectedStocks.sorted { $0.symbol < $1.symbol }
        }
        return selectedStocks
            .filter { $0.symbol.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.symbol < $1.symbol }
    }
    
    // MARK: - Events
    
    /// Emits when the structure of the watchlist changes (name, add/remove stock)
    let watchlistStructuralUpdate = PassthroughSubject<Watchlist, Never>()
    
    /// Emits when only price updates happen (used for animated highlights)
    let priceUpdate = PassthroughSubject<[Stock], Never>()
    
    /// Emits when a manual refresh is requested
    let refreshRequested = PassthroughSubject<Void, Never>()
    
    // MARK: - Internal State
    
    var isPriceOnlyUpdate = false
    var isRefreshBindingSetup = false
    
    // MARK: - Dependencies
    
    private var cancellables = Set<AnyCancellable>()
    
    var isPriceBindingSetup = false
    
    // MARK: - Init
    
    init(
        watchlist: Watchlist,
        availableStocks: [Stock]
    ) {
        self.watchlist = watchlist
        self.availableStocks = availableStocks

        print("[Init] WatchlistViewModel created for \(watchlist.name)")
        
        setupSearchBinding()
    }
    
    deinit {
        Logger.log("DEINIT: WatchlistViewModel for \(watchlist.name)", category: "Watchlist")
    }
    // MARK: - Public API
    
    func requestRefresh() {
        refreshRequested.send()
    }
    
    func isSelected(_ stock: Stock) -> Bool {
        watchlist.stocks.contains { $0.symbol == stock.symbol }
    }
    
    func updateWatchlist(_ newValue: Watchlist) {
        DispatchQueue.main.async {
            if self.watchlist != newValue {
                self.watchlist = newValue
            }
        }
    }
    
    func syncWithParent() {
        watchlistStructuralUpdate.send(watchlist)
    }
    
    // MARK: - Stock Management
    
    func addStock(_ stock: Stock) {
        var updated = watchlist
        do {
            try updated.tryAddStock(stock)
            DispatchQueue.main.async {
                self.watchlist = updated
                self.syncWithParent()
            }
        } catch let error as StockValidationError {
            SharedAlertManager.shared.show(error.alert)
        } catch {
            SharedAlertManager.shared.show(StockValidationError.failedToAdd.alert)
        }
    }
    
    func removeStock(_ stock: Stock) {
        var updated = watchlist
        do {
            try updated.tryRemoveStock(stock)
            DispatchQueue.main.async {
                self.watchlist = updated
                self.syncWithParent()
            }
        } catch {
            SharedAlertManager.shared.show(
                StockValidationError.failedToDelete(error.localizedDescription).alert
            )
        }
    }
    
    func replaceStocks(_ newStocks: [Stock]) {
        guard !newStocks.isEmpty else { return }

        let updated = newStocks.filter { new in
            guard let old = watchlist.stocks.first(where: { $0.symbol == new.symbol }) else { return true }
            return old.price != new.price
        }

        guard !updated.isEmpty else { return }

        DispatchQueue.main.async {
            self.isPriceOnlyUpdate = true
            self.watchlist.replacePrices(from: updated)
            self.isPriceOnlyUpdate = false
            self.priceUpdate.send(updated)
        }
    }
    
    // MARK: - Private
        
    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { _ in }
            .store(in: &cancellables)
    }
}
