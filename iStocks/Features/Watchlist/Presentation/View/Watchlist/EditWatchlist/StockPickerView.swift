//
//  StockPickerView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-04.
//
import SwiftUI
import Combine

struct StockPickerView: View {
    @ObservedObject var viewModel: EditWatchlistViewModel
    @Environment(\.dismiss) private var dismiss
    let onSave: PassthroughSubject<Watchlist, Never>

    private let maxSelectable = AppConstants.maxStocksPerWatchlist
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                infoBanner
                
                List {
                    ForEach(viewModel.filteredStocks) { stock in
                        let isSelected = viewModel.selectedStocks.contains(where: { $0.symbol == stock.symbol })
                        let isDisabled = !isSelected && viewModel.selectedStocks.count >= maxSelectable
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text(stock.symbol).font(.headline)
                                Text(stock.name).font(.subheadline).foregroundColor(.gray)
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
                }
                .listStyle(.plain)
            }
            .navigationTitle("Add Stocks")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        do {
                            let validated = try viewModel.validateAndReturnWatchlist()
                            DispatchQueue.main.async {
                                onSave.send(validated)
                            }
                            dismiss()
                        } catch {
                            if let err = error as? LocalizedAlertConvertible {
                                SharedAlertManager.shared.show(err.alert)
                            } else {
                                SharedAlertManager.shared.show(StockValidationError.failedToAdd.alert)
                            }
                        }
                    }
                    .disabled(viewModel.selectedStocks.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField("Search stocks", text: $viewModel.searchText)
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Banner
    
    private var infoBanner: some View {
        Text("\(viewModel.selectedStocks.count)/\(maxSelectable) stocks added")
            .font(.caption)
            .foregroundColor(viewModel.selectedStocks.count >= maxSelectable ? .red : .gray)
            .padding(.horizontal)
            .padding(.top, 8)
    }
    
    // MARK: - Toggle Logic
    
    private func handleToggle(_ stock: Stock, isSelected: Bool, isDisabled: Bool) {
        if isDisabled && !isSelected {
            SharedAlertManager.shared.show(
                StockValidationError.limitReached(num: maxSelectable).alert
            )
            return
        }
        
        if isSelected {
            if viewModel.selectedStocks.count == 1 {
                SharedAlertManager.shared.show(StockValidationError.mustHaveAtLeastOne.alert)
                return
            }
            viewModel.removeStock(stock)
        } else {
            viewModel.addStock(stock)
        }
    }
}
