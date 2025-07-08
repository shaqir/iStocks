//
//  StockPickerView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-04.
//
import Foundation
import SwiftUI
import Combine

struct StockPickerView: View {
    var allStocks: [Stock]
    @Binding var selectedStocks: [Stock]

    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""

    private var hasReachedMaxStockLimit: Bool {
        selectedStocks.count >= AppConstants.maxStocksPerWatchlist
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

                // Count
                Text("\(selectedStocks.count) / \(AppConstants.maxStocksPerWatchlist) stocks added")
                    .font(.caption)
                    .foregroundColor(hasReachedMaxStockLimit ? .red : .gray)
                    .padding(.horizontal)
                    .padding(.top, 4)

                // Stock List
                List {
                    ForEach(filteredStocks) { stock in
                        stockRow(stock)
                    }
                }
                .listStyle(.plain)

                // Bottom Buttons
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    Spacer()
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(selectedStocks.isEmpty)
                }
                .padding()
            }
        }
    }

    // MARK: - View Builders

    private func stockRow(_ stock: Stock) -> some View {
        let selected = isSelected(stock)
        let disabled = !selected && hasReachedMaxStockLimit

        return HStack {
            VStack(alignment: .leading) {
                Text(stock.symbol)
                    .font(.headline)
                Text(stock.name)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: selected ? "checkmark.square.fill" : "plus.square")
                .foregroundColor(selected ? .green : .blue)
                .font(.system(size: 22, weight: .medium))
        }
        .opacity(disabled ? 0.4 : 1.0)
        .contentShape(Rectangle()) // Ensures full row is tappable
        .onTapGesture {
            handleToggle(stock, isSelected: selected, isDisabled: disabled)
        }
    }

    // MARK: - Logic

    private func isSelected(_ stock: Stock) -> Bool {
        selectedStocks.contains(where: { $0.symbol == stock.symbol })
    }

    private func handleToggle(_ stock: Stock, isSelected: Bool, isDisabled: Bool) {
        guard !isDisabled || isSelected else {
            SharedAlertManager.shared.show(
                StockValidationError.limitReached(num: AppConstants.maxStocksPerWatchlist).alert
            )
            return
        }

        if isSelected {
            selectedStocks.removeAll(where: { $0.symbol == stock.symbol })
        } else {
            selectedStocks.append(stock)
        }
    }

    private var filteredStocks: [Stock] {
        let base = searchText.isEmpty ? allStocks : allStocks.filter {
            $0.symbol.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
        return base.sorted { $0.symbol < $1.symbol }
    }
}
