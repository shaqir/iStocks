//
//  EditSingleWatchlistView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-03.
//

import SwiftUI

struct EditSingleWatchlistView: View {
    @State var watchlist: Watchlist
    var onSave: (Watchlist) -> Void
    var onDismiss: () -> Void
    var isNewWatchlist: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingStockPicker = false
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Watchlist Name")) {
                    TextField(isNewWatchlist ? "New Watchlist" : watchlist.name, text: $watchlist.name)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("Stocks (\(watchlist.stocks.count))")) {
                    if watchlist.stocks.isEmpty {
                        Text("No stocks added yet")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(Array(watchlist.stocks).sorted(by: { $0.symbol < $1.symbol }), id: \.id) { stock in
                            HStack {
                                Text(stock.symbol)
                                    .font(.body)
                                Spacer()
                                Text("\(stock.price, specifier: "%.2f")")
                                    .foregroundColor(.gray)
                            }
                        }
                        .onDelete(perform: deleteStock)
                    }
                }
                Section(header: Text("Add Stocks")) {
                    Button {
                        isShowingStockPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search & add stock")
                            Spacer()
                        }
                        .foregroundColor(.blue)
                        .padding(.vertical, 6)
                    }
                }
                
            }
            .navigationTitle(isNewWatchlist ? "Add New Watchlist" : watchlist.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedName = watchlist.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmedName.isEmpty {
                            SharedAlertManager.shared.show(
                                SharedAlertData(
                                    title: "Watchlist Name Missing",
                                    message: "Watchlist name cannot be empty.",
                                    icon: "exclamationmark.circle.fill",
                                    action: nil
                                )
                            )
                            return
                        }
                        
                        if watchlist.stocks.isEmpty {
                            SharedAlertManager.shared.show(
                                SharedAlertData(
                                    title: "No Stocks Added",
                                    message: "Please add at least one stock to your watchlist.",
                                    icon: "chart.line.uptrend.xyaxis",
                                    action: nil
                                )
                            )
                            return
                        }
                        
                        let symbols = watchlist.stocks.map { $0.symbol }
                        let uniqueSymbols = Set(symbols)
                        if symbols.count != uniqueSymbols.count {
                            SharedAlertManager.shared.show(
                                SharedAlertData(
                                    title: "Duplicate Stocks",
                                    message: "Duplicate stocks found in your watchlist.",
                                    icon: "arrow.triangle.2.circlepath.circle.fill",
                                    action: nil
                                )
                            )
                            return
                        }
                        
                        onSave(watchlist)
                    }
                }
                
            }
        }
        .sheet(isPresented: $isShowingStockPicker) {
            StockPickerView(
                allStocks: MockStockData.allStocks,
                alreadySelectedStocks: watchlist.stocks,
                onSelect: { handleAddStock($0)}
            )
            .environmentObject(SharedAlertManager.shared)
        }


        
    }
    
    // MARK: - Helper Methods
    
    private func handleAddStock(_ stock: Stock) {
        do {
            try watchlist.tryAddStock(stock)
        } catch let error as StockValidationError {
            SharedAlertManager.shared.show(error.alert)
        } catch {
            // Optional: Log or show generic error
            print("Unexpected error: \(error.localizedDescription)")
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

    private func deleteStock(at offsets: IndexSet) {
        var array = Array(watchlist.stocks)
        for offset in offsets {
            let stock = array[offset]
            do {
                try watchlist.tryRemoveStock(stock)
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
    }

    
    
}
