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
    @ObservedObject var selectionManager: StockSelectionManager

    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""

    private var filteredStocks: [Stock] {
        let base = searchText.isEmpty ? allStocks : allStocks.filter {
            $0.symbol.localizedCaseInsensitiveContains(searchText) ||
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
        return base.sorted { $0.symbol < $1.symbol }
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
                Text("\(selectionManager.selectedStocks.count) / \(AppConstants.maxStocksPerWatchlist) stocks added")
                    .font(.caption)
                    .foregroundColor(selectionManager.hasReachedLimit() ? .red : .gray)
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
                    .disabled(selectionManager.selectedStocks.isEmpty)
                }
                .padding()
            }
        }
    }

    // MARK: - Stock Row

    private func stockRow(_ stock: Stock) -> some View {
        let isSelected = selectionManager.isSelected(stock)
        let isDisabled = !isSelected && selectionManager.hasReachedLimit()

        return HStack {
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
        .opacity(isDisabled ? 0.4 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            handleToggle(stock, isSelected: isSelected, isDisabled: isDisabled)
        }
    }

    // MARK: - Toggle Logic

    private func handleToggle(_ stock: Stock, isSelected: Bool, isDisabled: Bool) {
        guard !isDisabled || isSelected else {
            SharedAlertManager.shared.show(
                StockValidationError.limitReached(num: AppConstants.maxStocksPerWatchlist).alert
            )
            return
        }
        selectionManager.toggleSelection(for: stock)
    }
}
