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
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var newStockSymbol: String = ""
    @FocusState private var isInputFocused: Bool

    @State private var isShowingStockPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Watchlist Name")) {
                    TextField("Enter name", text: $watchlist.name)
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
            .navigationTitle("Edit Watchlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(watchlist)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingStockPicker) {
            StockPickerView(
                allStocks: MockStockData.allStocks,
                alreadySelectedStocks: watchlist.stocks,
                onSelect: { selected in
                    watchlist.stocks.append(selected)
                }
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func deleteStock(at offsets: IndexSet) {
        var array = Array(watchlist.stocks)
        array.remove(atOffsets: offsets)
        watchlist.stocks = array
    }
    
    private func addStock() {
        guard watchlist.stocks.count < 50 else { return }
        let symbol = newStockSymbol.uppercased()
        guard !watchlist.stocks.contains(where: { $0.symbol == symbol }) else { return }

        let newStock = Stock(symbol: symbol, name: "Dummy", price: 0.0, previousPrice: 0.0, isPriceUp: false, qty: 0, averageBuyPrice: 0.0, sector: "-")
        watchlist.stocks.append(newStock)
        newStockSymbol = ""
        isInputFocused = true
    }
}
