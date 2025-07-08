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
                
                banner
                
                // MARK: - Filtered Stock List
                List {
                    ForEach(filteredStocks) { stock in
                        let isSelected = isSelectedStock(stock)
                        let isDisabled = !isSelected && hasReachedMaxStockLimit

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
                        .id(stock.symbol)
                        .opacity(isDisabled ? 0.4 : 1.0)
                        .contentShape(Rectangle()) // ensures full row is tappable
                        .onTapGesture {
                            handleStockToggleWithTap(stock, isSelected: isSelected, isDisabled: isDisabled)
                        }
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

    private var banner: some View {
        Text("\(watchlist.stocks.count)/\(AppConstants.maxStocksPerWatchlist) stocks added")
            .font(.caption)
            .foregroundColor(hasReachedMaxStockLimit ? .red : .gray)
            .padding(.horizontal)
            .padding(.top, 8)
    }
    
    private var hasReachedMaxStockLimit: Bool {
        watchlist.stocks.count >= AppConstants.maxStocksPerWatchlist
    }

    private func isSelectedStock(_ stock: Stock) -> Bool {
        watchlist.stocks.contains(where: { $0.symbol == stock.symbol })
    }

    private func isStockDisabled(_ stock: Stock) -> Bool {
        return !isSelectedStock(stock) && hasReachedMaxStockLimit
    }

    private var filteredStocks: [Stock] {
        let query = searchText.lowercased()
        let base = searchText.isEmpty ? MockStockData.allStocks : MockStockData.allStocks.filter {
            $0.symbol.lowercased().contains(query) || $0.name.lowercased().contains(query)
        }
        return base.sorted(by: { $0.symbol < $1.symbol })
    }

    private func handleStockToggleWithTap(_ stock: Stock, isSelected: Bool, isDisabled: Bool) {
        guard !isDisabled || isSelected else {
            SharedAlertManager.shared.show(
                StockValidationError.limitReached(num: AppConstants.maxStocksPerWatchlist).alert
            )
            return
        }

        do {
            if isSelected {
                try watchlist.tryRemoveStock(stock)
            } else {
                try watchlist.tryAddStock(stock)
            }
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

    private func handleSaveTap() {
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
        syncWithParent()
        dismiss()
    }

    private func syncWithParent() {
        DispatchQueue.main.async {
            watchlistDidSave.send(watchlist)
        }
    }
}
 
