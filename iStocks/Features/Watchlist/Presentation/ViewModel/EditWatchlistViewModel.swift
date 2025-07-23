//
//  EditWatchlistViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-09.
//
import Foundation
import Combine

final class EditWatchlistViewModel: ObservableObject {
    @Published var name: String
    @Published var selectedStocks: [Stock]
    @Published var searchText: String = ""

    let availableStocks: [Stock]
    let isNewWatchlist: Bool
    private let originalWatchlistID: UUID

    /// Emits validated Watchlist when saved
    let onSave = PassthroughSubject<Watchlist, Never>()
        
    //test
    var existingNames: [String] = []


    init(watchlist: Watchlist, availableStocks: [Stock], isNewWatchlist: Bool = false) {
        self.name = watchlist.name
        self.selectedStocks = watchlist.stocks
        self.availableStocks = availableStocks
        self.originalWatchlistID = watchlist.id
        self.isNewWatchlist = isNewWatchlist
    }

    // MARK: - Filtered Stocks
    var filteredStocks: [Stock] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return uniqueStocks(from: availableStocks)
        }

        let filtered = availableStocks.filter {
            $0.symbol.localizedCaseInsensitiveContains(trimmed) ||
            $0.name.localizedCaseInsensitiveContains(trimmed)
        }
        
        return uniqueStocks(from: filtered)
    }

    private func uniqueStocks(from stocks: [Stock]) -> [Stock] {
        Dictionary(grouping: stocks, by: \.symbol)
            .compactMapValues { $0.first }
            .values
            .sorted { $0.symbol < $1.symbol } // consistent order
    }

    // MARK: - Stock Actions
    func addStock(_ stock: Stock) {
        guard !selectedStocks.contains(where: { $0.symbol == stock.symbol }),
              selectedStocks.count < AppConstants.maxStocksPerWatchlist else { return }
        selectedStocks.append(stock)
    }

    func removeStock(_ stock: Stock) {
        guard selectedStocks.count > 1 else { return }
        selectedStocks.removeAll { $0.symbol == stock.symbol }
    }

    // MARK: - Save
    
    func validateAndReturnWatchlist() throws -> Watchlist {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw WatchlistValidationError.emptyName
        }

        guard !selectedStocks.isEmpty else {
            throw StockValidationError.mustHaveAtLeastOne
        }

        guard selectedStocks.count <= AppConstants.maxStocksPerWatchlist else {
            throw StockValidationError.limitReached(num: AppConstants.maxStocksPerWatchlist)
        }

        if existingNames.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            throw WatchlistValidationError.duplicateName
        }

        return Watchlist(id: originalWatchlistID, name: trimmed, stocks: selectedStocks)
    }

}
