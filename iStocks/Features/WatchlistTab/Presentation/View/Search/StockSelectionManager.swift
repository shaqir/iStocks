//
//  StockSelectionManager.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-08.
//
import Foundation
import Foundation
import SwiftUI
import Combine

class StockSelectionManager: ObservableObject {
    @Published var selected: [Stock] = []
    private var limit: Int = 10

    func configure(selected: [Stock], limit: Int) {
        self.selected = selected
        self.limit = limit
    }

    func toggle(_ stock: Stock) {
        if isSelected(stock) {
            selected.removeAll { $0.symbol == stock.symbol }
        } else if selected.count < limit {
            selected.append(stock)
        } else {
            SharedAlertManager.shared.show(
                StockValidationError.limitReached(num: limit).alert
            )
        }
    }

    func isSelected(_ stock: Stock) -> Bool {
        selected.contains(where: { $0.symbol == stock.symbol })
    }

    func isInteractionDisabled(for stock: Stock) -> Bool {
        !isSelected(stock) && selected.count >= limit
    }

    var countText: String {
        "\(selected.count) / \(limit) stocks added"
    }

    var hasReachedLimit: Bool {
        selected.count >= limit
    }
}
