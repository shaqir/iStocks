//
//  EditWatchlistViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-09.
//

import Foundation
import Combine 

final class EditWatchlistViewModel: ObservableObject {
    // MARK: - Inputs
    @Published var searchText: String = ""
    @Published private(set) var filteredStocks: [Stock] = []

    let selectionManager: StockSelectionManager
    let isNewWatchlist: Bool

    private var cancellables = Set<AnyCancellable>()
    private let originalWatchlist: Watchlist  // Keep original

    // MARK: - Init
    init(watchlist: Watchlist, isNewWatchlist: Bool = false) {
        self.originalWatchlist = watchlist
        self.selectionManager = StockSelectionManager(
            initialSelected: watchlist.stocks,
            maxSelectable: AppConstants.maxStocksPerWatchlist
        )
        self.isNewWatchlist = isNewWatchlist
        setupBindings()
    }

    var initialName: String {
        originalWatchlist.name
    }

    // MARK: - Search Filtering
    private func setupBindings() {
        $searchText
            .removeDuplicates()
            .map { query -> [Stock] in
                guard !query.isEmpty else { return MockStockData.allStocks }
                let lowercaseQuery = query.lowercased()
                return MockStockData.allStocks.filter {
                    $0.symbol.lowercased().contains(lowercaseQuery) ||
                    $0.name.lowercased().contains(lowercaseQuery)
                }
            }
            .map { $0.sorted { $0.symbol < $1.symbol } }
            .assign(to: &$filteredStocks)
    }

    // MARK: - Validation
    func validateAndReturnWatchlist(named name: String) throws -> Watchlist {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw WatchlistValidationError.nameRequired
        }
        let stocks = selectionManager.selectedStocks
        guard !stocks.isEmpty else {
            throw WatchlistValidationError.noStocksAdded
        }
        guard Set(stocks.map { $0.symbol }).count == stocks.count else {
            throw StockValidationError.duplicate
        }

        return Watchlist(
            id: originalWatchlist.id, // preserve original ID
            name: trimmed,
            stocks: stocks
        )
    }
}
