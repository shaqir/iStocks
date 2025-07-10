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
    @StateObject var viewModel: EditWatchlistViewModel
    var watchlistDidSave: PassthroughSubject<Watchlist, Never>
    @State private var watchlistName: String
    
    @ObservedObject private var selectionManager: StockSelectionManager
    
    init(viewModel: EditWatchlistViewModel, watchlistDidSave: PassthroughSubject<Watchlist, Never>) {
           _viewModel = StateObject(wrappedValue: viewModel)
           _watchlistName = State(initialValue: viewModel.initialName) // Expose from VM
           self.watchlistDidSave = watchlistDidSave
           self.selectionManager = viewModel.selectionManager
       }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                nameField
                searchField
                banner
                List {
                    ForEach(viewModel.filteredStocks) { stock in
                        let isSelected = selectionManager.isSelected(stock)
                        let isDisabled = !isSelected && selectionManager.hasReachedLimit()

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
                            guard !isDisabled || isSelected else {
                                SharedAlertManager.shared.show(StockValidationError.limitReached(num: AppConstants.maxStocksPerWatchlist).alert)
                                return
                            }
                            selectionManager.toggleSelection(for: stock)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle(viewModel.isNewWatchlist ? "Add Watchlist" : watchlistName)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { handleSave() }
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
            TextField("New Watchlist", text: $watchlistName)
                .textFieldStyle(.roundedBorder)
        }
        .padding()
    }

    private var searchField: some View {
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

    private var banner: some View {
        Text("\(selectionManager.selectedStocks.count)/\(AppConstants.maxStocksPerWatchlist) stocks added")
            .font(.caption)
            .foregroundColor(selectionManager.hasReachedLimit() ? .red : .gray)
            .padding(.horizontal)
            .padding(.top, 8)
    }

    // MARK: - Actions

    private func handleTap(_ stock: Stock, isSelected: Bool, isDisabled: Bool) {
        guard !isDisabled || isSelected else {
            SharedAlertManager.shared.show(StockValidationError.limitReached(num: AppConstants.maxStocksPerWatchlist).alert)
            return
        }
        selectionManager.toggleSelection(for: stock)
    }

    private func handleSave() {
        do {
            let updatedWatchlist = try viewModel.validateAndReturnWatchlist(named: watchlistName)
            watchlistDidSave.send(updatedWatchlist)
            dismiss()
        }catch let e as StockValidationError {
            SharedAlertManager.shared.show(e.alert)
        }
        catch let e as WatchlistValidationError {
            SharedAlertManager.shared.show(e.alert)
        }
        catch {
            SharedAlertManager.shared.show(SharedAlertData(
                title: "Unexpected Error",
                message: error.localizedDescription,
                icon: "exclamationmark.triangle.fill",
                action: nil
            ))
        }
    }
}
