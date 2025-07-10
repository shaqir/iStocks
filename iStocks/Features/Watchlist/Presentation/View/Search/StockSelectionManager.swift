//
//  StockSelectionManager.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-08.
//
import Foundation
import Combine 

final class StockSelectionManager: ObservableObject {
    @Published private(set) var selectedStocks: [Stock] = []
    let maxSelectable: Int

    init(initialSelected: [Stock] = [], maxSelectable: Int = 10) {
        self.selectedStocks = initialSelected
        self.maxSelectable = maxSelectable
    }

    func isSelected(_ stock: Stock) -> Bool {
        selectedStocks.contains(where: { $0.symbol == stock.symbol })
    }

    func toggleSelection(for stock: Stock) {
        if isSelected(stock) {
            if selectedStocks.count <= 1 {
                SharedAlertManager.shared.show(
                    WatchlistValidationError.atLeastOneStockRequired.alert
                )
                return
            }
            remove(stock)
        } else {
            add(stock)
        }
    }

    func hasReachedLimit() -> Bool {
        selectedStocks.count >= maxSelectable
    }

    func canSelectMore() -> Bool {
        !hasReachedLimit()
    }

    private func add(_ stock: Stock) {
        guard !isSelected(stock), !hasReachedLimit() else { return }
        selectedStocks.append(stock)
    }

    private func remove(_ stock: Stock) {
        selectedStocks.removeAll { $0.symbol == stock.symbol }
    }

    func resetSelection() {
        selectedStocks.removeAll()
    }

    func setSelection(_ stocks: [Stock]) {
        selectedStocks = Array(stocks.prefix(maxSelectable))
    }
}
