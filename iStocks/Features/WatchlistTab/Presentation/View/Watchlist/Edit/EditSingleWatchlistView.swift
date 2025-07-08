//
//  EditSingleWatchlistView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-03.
//

import SwiftUI
import Combine

struct EditSingleWatchlistView: View {
    @State var watchlist: Watchlist
    @Environment(\.dismiss) private var dismiss
    var isNewWatchlist: Bool
    
    @State private var searchText = ""
    private let maxStockLimit = 10
    
    var watchlistDidSave: PassthroughSubject<Watchlist, Never>

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Watchlist Name Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Watchlist Name")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    TextField("New Watchlist", text: $watchlist.name)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.words)
                }
                .padding()
                
                // MARK: - Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search stocks", text: $searchText)
                        .disableAutocorrection(true)
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 6)
                
                Text("\(watchlist.stocks.count) / \(maxStockLimit) stocks added")
                    .font(.footnote)
                    .foregroundColor(hasReachedMaxStockLimit ? .red : .gray)
                    .padding(.horizontal)
                    .padding(.top, 4)
                
                if hasReachedMaxStockLimit {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Limit reached. You can only add up to \(maxStockLimit) stocks.")
                            .font(.footnote)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                }
                
                // MARK: - Filtered Stock List
                List(filteredStocks) { stock in
                    Button(action: {
                        handleStockToggle(stock)
                    }) {
                        StockRowView(stock: stock,
                                     isSelected: isSelectedStock(stock),
                                     isDisabled: isStockDisabled(stock))
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle(isNewWatchlist ? "Add Watchlist" : watchlist.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        handleSaveTap()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var hasReachedMaxStockLimit: Bool {
        watchlist.stocks.count >= maxStockLimit
    }
    
    private func isStockDisabled(_ stock: Stock) -> Bool {
        if watchlist.stocks.contains(where: { $0.symbol == stock.symbol }) {
            return false // Allow editing selected stocks
        }
        return hasReachedMaxStockLimit
    }
    
    private func isSelectedStock(_ stock: Stock) -> Bool {
        watchlist.stocks.contains(where: { $0.symbol == stock.symbol })
    }

    private var filteredStocks: [Stock] {
        let base = searchText.isEmpty ? MockStockData.allStocks : MockStockData.allStocks.filter {
            let query = searchText.lowercased()
            return $0.symbol.lowercased().contains(query) || $0.name.lowercased().contains(query)
        }
        return base.sorted(by: { $0.symbol < $1.symbol })
    }
    
    private func handleStockToggle(_ stock: Stock) {
        do {
            try toggleStock(stock)
        } catch let error as StockValidationError {
            SharedAlertManager.shared.show(error.alert)
        } catch {
            SharedAlertManager.shared.show(
                SharedAlertData(
                    title: "Unexpected Error",
                    message: error.localizedDescription,
                    icon: "exclamationmark.triangle.fill",
                    action: nil
                )
            )
        }
    }

    private func toggleStock(_ stock: Stock) throws {
        if watchlist.stocks.contains(where: { $0.symbol == stock.symbol }) {
            try? watchlist.tryRemoveStock(stock)
        } else if !hasReachedMaxStockLimit {
            try? watchlist.tryAddStock(stock)
        } else {
            throw StockValidationError.limitReached(num: maxStockLimit)
        }
    }
    
    private func handleSaveTap(){
        let trimmedName = watchlist.name.trimmingCharacters(in: .whitespacesAndNewlines)
           guard !trimmedName.isEmpty else {
               SharedAlertManager.shared.show(WatchlistValidationError.nameRequired.alert)
               return
           }
           guard !watchlist.isEmpty else {
               SharedAlertManager.shared.show(WatchlistValidationError.noStocksAdded.alert)
               return
           }
           guard !watchlist.hasDuplicateSymbols else {
               SharedAlertManager.shared.show(StockValidationError.duplicate.alert)
               return
           }

           watchlist.name = trimmedName
           watchlistDidSave.send(watchlist)
           dismiss()
    }
}

struct StockRowView: View {
    let stock: Stock
    let isSelected: Bool
    let isDisabled: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(stock.symbol)
                    .font(.headline)
                Text(stock.name)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.square.fill" : "plus.square")
                .foregroundColor(isSelected ? .green : .blue)
                .font(.system(size: 22, weight: .medium))
        }
        .opacity(isDisabled ? 0.5 : 1.0)
        .padding(.vertical, 4)
    }
}
