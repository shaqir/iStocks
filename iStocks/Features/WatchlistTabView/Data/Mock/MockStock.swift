//
//  MockedStock.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//

import Foundation

struct MockStock: Identifiable {
    let id = UUID()
    let symbol: String
    var price: Double
    var isPriceUp: Bool
    let invested: Double // how much the user invested
}

extension MockStock {
    func toDomainModel() -> Stock {
         Stock(symbol: symbol,
               price: price,
               previousPrice: price,
               isPriceUp: isPriceUp,
               qty: 1,
               averageBuyPrice: 1)
    }
}
