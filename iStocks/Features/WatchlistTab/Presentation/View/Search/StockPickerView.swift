//
//  StockPickerView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-04.
//

import SwiftUI

struct StockPickerView: View {
    var allStocks: [Stock]
    var alreadySelectedStocks: [Stock]
    let onSelectMultiple: ([Stock]) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""
    @State private var selectedStocks: [Stock] = []
    
    private let maxStockLimit = 10
    
    private var hasReachedMaxStockLimit: Bool {
        selectedStocks.count >= maxStockLimit
    }

    var filteredStocks: [Stock] {
        let base = searchText.isEmpty ? allStocks : allStocks.filter {
            $0.symbol.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
        return base.sorted(by: { $0.symbol < $1.symbol })
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // 🔍 Search Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                    TextField("Search stocks", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    if !searchText.isEmpty {
                        Button("Clear") {
                            searchText = ""
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                
                // 📊 Count
                Text("\(selectedStocks.count) / \(maxStockLimit) stocks added")
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
                    .padding(.bottom, 4)
                }

                // 📋 Stock List
                List {
                    ForEach(filteredStocks) { stock in
                        Button(action: {
                            toggle(stock)
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
                                
                                if selectedStocks.contains(where: { $0.symbol == stock.symbol }) {
                                    Image(systemName: "checkmark.square.fill")
                                        .foregroundColor(.green)
                                        .font(.system(size: 22, weight: .medium))
                                } else {
                                    Image(systemName: "plus.square")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 22, weight: .medium))
                                }
                            }
                            .opacity(isDisabled(stock) ? 0.5 : 1.0)
                        }
                        .disabled(isDisabled(stock))
                    }
                }
                .listStyle(.plain)
                
                // Bottom Action Buttons
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    Spacer()
                    Button("Add \(selectedStocks.count)") {
                        onSelectMultiple(selectedStocks)
                        dismiss()
                    }
                    .disabled(selectedStocks.isEmpty)
                }
                .padding()
            }
            .onAppear {
                self.selectedStocks = alreadySelectedStocks
            }
        }
    }
    
    private func toggle(_ stock: Stock) {
        if let index = selectedStocks.firstIndex(where: { $0.symbol == stock.symbol }) {
            selectedStocks.remove(at: index)
        } else if !hasReachedMaxStockLimit {
            selectedStocks.append(stock)
        }
    }
    
    private func isDisabled(_ stock: Stock) -> Bool {
        hasReachedMaxStockLimit
    }
}
