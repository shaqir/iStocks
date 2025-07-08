//
//  WatchlistViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//
import Foundation
import Combine

final class WatchlistViewModel: ObservableObject {
    
    @Published var watchlist: Watchlist
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    
    // Combine publisher to notify changes
    let watchlistDidUpdate = PassthroughSubject<Watchlist, Never>()

    private var cancellables = Set<AnyCancellable>()
    
    var stocks: [Stock] {
        watchlist.stocks
    }
    
    init(watchlist: Watchlist) {
        self.watchlist = watchlist
        setupSearchBinding()
    }
    
    func updateWatchlist(_ newValue: Watchlist) {
        self.watchlist = newValue
    }
    var filteredStocks: [Stock] {
        guard !searchText.isEmpty else {
            return stocks.sorted { $0.symbol < $1.symbol }
        }
        return stocks
            .filter { $0.symbol.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.symbol < $1.symbol }
    }
    
    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { _ in }
            .store(in: &cancellables)
    }
    
    func addStock(_ stock: Stock) {
        var updated = watchlist
        do {
            try updated.tryAddStock(stock)
            watchlist = updated             // Triggers $watchlist
            watchlistDidUpdate.send(updated) //  Notify parent on change: Manually emit
        } catch let error as StockValidationError {
            SharedAlertManager.shared.show(error.alert)
        } catch {
            SharedAlertManager.shared.show(SharedAlertData(
                title: "Error",
                message: error.localizedDescription,
                icon: "exclamationmark.triangle",
                action: nil
            ))
        }
    }

    func removeStock(_ stock: Stock) {
        var updated = watchlist
        do {
            try updated.tryRemoveStock(stock)
            watchlist = updated
            watchlistDidUpdate.send(updated)//Notify parent
        } catch {
            SharedAlertManager.shared.show(
                SharedAlertData(
                    title: "Error Removing",
                    message: error.localizedDescription,
                    icon: "trash",
                    action: nil
                )
            )
        }
    }
}

