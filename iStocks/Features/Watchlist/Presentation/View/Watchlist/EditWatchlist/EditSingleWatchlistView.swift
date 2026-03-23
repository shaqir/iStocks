//
//  EditSingleWatchlistView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-03.
//

import SwiftUI
import Combine

struct EditSingleWatchlistView: View {
    @Environment(\.dismiss) private var dismiss

    var watchlistDidSave: PassthroughSubject<Watchlist, Never>

    @StateObject var viewModel: EditWatchlistViewModel

    init(viewModel: EditWatchlistViewModel, watchlistDidSave: PassthroughSubject<Watchlist, Never>) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.watchlistDidSave = watchlistDidSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                nameField
                searchField
                infoBanner

                List {
                    ForEach(viewModel.filteredStocks) { stock in
                        stockRow(stock)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle(viewModel.isNewWatchlist ? "Add Watchlist" : "Edit Watchlist")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { handleSave() }
                        .disabled(viewModel.selectedStocks.isEmpty || viewModel.name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityHint("Saves the watchlist changes")
                }
            }
        }
    }

    // MARK: - UI Components

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Watchlist Name")
                .font(.footnote)
                .foregroundColor(.gray)
                .accessibilityHidden(true)
            TextField("New Watchlist", text: $viewModel.name)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Watchlist name")
                .accessibilityHint("Enter a name for this watchlist")
        }
        .padding()
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .accessibilityHidden(true)
            TextField("Search stocks", text: $viewModel.searchText)
                .accessibilityLabel("Search stocks")
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private var infoBanner: some View {
        Text("\(viewModel.selectedStocks.count)/\(AppConstants.maxStocksPerWatchlist) stocks added")
            .font(.caption)
            .foregroundColor(viewModel.selectedStocks.count >= AppConstants.maxStocksPerWatchlist ? .red : .gray)
            .padding(.horizontal)
            .padding(.top, 8)
            .accessibilityLabel("\(viewModel.selectedStocks.count) of \(AppConstants.maxStocksPerWatchlist) stocks added")
    }

    private func stockRow(_ stock: Stock) -> some View {
        let isSelected = viewModel.selectedStocks.contains(where: { $0.symbol == stock.symbol })
        let isDisabled = !isSelected && viewModel.selectedStocks.count >= AppConstants.maxStocksPerWatchlist

        return HStack {
            VStack(alignment: .leading) {
                Text(stock.symbol).font(.headline)
                Text(stock.name).font(.subheadline).foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.square.fill" : "plus.square")
                .foregroundColor(isSelected ? .green : .blue)
                .font(.system(size: 22, weight: .medium))
                .accessibilityHidden(true)
        }
        .opacity(isDisabled ? 0.4 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            handleToggle(stock, isSelected: isSelected, isDisabled: isDisabled)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(stock.symbol), \(stock.name)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(isDisabled ? "Maximum stocks reached" : (isSelected ? "Removes stock from watchlist" : "Adds stock to watchlist"))
        .accessibilityAddTraits(.isButton)
    }

    private func handleToggle(_ stock: Stock, isSelected: Bool, isDisabled: Bool) {
        if isDisabled && !isSelected {
            SharedAlertManager.shared.show(
                StockValidationError.limitReached(num: AppConstants.maxStocksPerWatchlist).alert
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

    // MARK: - Save
    private func handleSave() {
        do {
            let updatedWatchlist = try viewModel.validateAndReturnWatchlist()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            DispatchQueue.main.async {
                watchlistDidSave.send(updatedWatchlist)
            }
            dismiss()
        } catch {
            if let stockError = error as? StockValidationError {
                SharedAlertManager.shared.show(stockError.alert)
            } else if let nameError = error as? WatchlistValidationError {
                SharedAlertManager.shared.show(nameError.alert)
            } else {
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
