//
//  StockPickerView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-04.
//

import SwiftUI

struct StockPickerView: View {
    var allStocks: [Stock]
    let alreadySelectedStocks: [Stock]
    let onSelect: ([Stock]) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedStocks: [Stock] = []

    var filteredStocks: [Stock] {
        let lowercasedSearchText = searchText.lowercased()
        
        return allStocks
            .filter { stock in
                !alreadySelectedStocks.contains(where: { $0.symbol == stock.symbol })
            }
            .filter {
                searchText.isEmpty ||
                $0.symbol.lowercased().contains(lowercasedSearchText) ||
                $0.name.lowercased().contains(lowercasedSearchText)
            }
    }

    var body: some View {
        NavigationStack {
            List(filteredStocks, id: \.id) { stock in
                HStack {
                    Button(action: {
                        toggleSelection(stock)
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(stock.symbol)
                                    .font(.headline)
                                Text(stock.name)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if selectedStocks.contains(stock) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                        }
                        .contentShape(Rectangle()) // So whole row is tappable
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Select Stocks")
            .searchable(text: $searchText, prompt: "Search stocks")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add \(selectedStocks.count)") {
                        onSelect(Array(selectedStocks))
                        dismiss()
                    }
                    .disabled(selectedStocks.isEmpty)
                }
            }
        }
    }

    private func toggleSelection(_ stock: Stock) {
        if let index = selectedStocks.firstIndex(of: stock) {
            selectedStocks.remove(at: index)
        } else {
            selectedStocks.append(stock)
        }
    }

}

