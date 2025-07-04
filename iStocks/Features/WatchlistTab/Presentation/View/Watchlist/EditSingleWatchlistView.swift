//
//  EditSingleWatchlistView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-03.
//

import SwiftUI

struct EditSingleWatchlistView: View {
    let original: Watchlist
    let onSave: (Watchlist) -> Void
    let onDismiss: () -> Void

    @State private var name: String
    @State private var stocks: [Stock]

    init(
        watchlist: Watchlist,
        onSave: @escaping (Watchlist) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.original = watchlist
        self.onSave = onSave
        self.onDismiss = onDismiss
        _name = State(initialValue: watchlist.name)
        _stocks = State(initialValue: watchlist.stocks)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Watchlist Name")) {
                    TextField("Name", text: $name)
                }

                Section(header: Text("Stocks")) {
                    if stocks.isEmpty {
                        Text("No stocks added.")
                    } else {
                        ForEach(stocks) { stock in
                            HStack {
                                Text(stock.symbol)
                                Spacer()
                                Text("$\(stock.price, specifier: "%.2f")")
                            }
                        }
                        .onDelete { indexSet in
                            stocks.remove(atOffsets: indexSet)
                        }
                    }
                }

                Button("Add Dummy Stock") {
                    let dummy = Stock.dummy() // define this helper
                    stocks.append(dummy)
                }
            }
            .navigationTitle("Edit Watchlist")
            .navigationBarItems(
                leading: Button("Cancel") {
                    onDismiss()
                },
                trailing: Button("Save") {
                    let updated = Watchlist(id: original.id, name: name, stocks: stocks)
                    onSave(updated)
                }
            )
        }
    }
}
