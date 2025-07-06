//
//  WatchlistViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//
import Foundation
import Combine

final class WatchlistViewModel: ObservableObject {
    
    @Published private(set) var watchlist: Watchlist
    
    var didUpdateStocks: (([Stock]) -> Void)? // Callback
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    var stocks: [Stock] {
        watchlist.stocks
    }
    
    init(watchlist: Watchlist) {
        self.watchlist = watchlist
        setupSearchBinding()
    }
    
    // MARK: - Computed filteredStocks (returns [Stock])
    var filteredStocks: [Stock] {
        guard !searchText.isEmpty else {
            return Array(watchlist.stocks).sorted(by: { $0.symbol < $1.symbol })
        }
        return stocks
            .filter { $0.symbol.localizedCaseInsensitiveContains(searchText) }
            .sorted(by: { $0.symbol < $1.symbol })
    }
    
    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { _ in
            }
            .store(in: &cancellables)
    }
    
    func addStock(_ stock: Stock){
        var updatedWatchlist = watchlist
        do {
            try updatedWatchlist.tryAddStock(stock)
            watchlist = updatedWatchlist
            didUpdateStocks?(watchlist.stocks)
        }
        catch let error as StockValidationError {
            SharedAlertManager.shared.show(error.alert)
        }
        catch {
            print("Error adding stock to watchlist: \(error)")
        }
    }
}

