//
//  StockDataStore.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-12.
//

import Foundation

final class StockDataStore {
    static let shared = StockDataStore()
    private init() {}

    private(set) var allStocks: [Stock] = []

    func update(with stocks: [Stock]) {
        self.allStocks = stocks
    }

    func clear() {
        self.allStocks.removeAll()
    }
}
