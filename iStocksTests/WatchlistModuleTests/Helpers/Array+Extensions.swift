//
//  Array+Extensions.swift
//  iStocksUITests
//
//  Created by Sakir Saiyed on 2025-07-23.
//

import Foundation
@testable import iStocks

extension Array where Element == String {
    func toMockStocks(price: Double = 100.0) -> [Stock] {
        self.map { MockStock(symbol: $0, price: price).toDomain() }
    }
}


