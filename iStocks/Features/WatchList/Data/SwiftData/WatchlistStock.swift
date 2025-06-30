//
//  WatchlistStock.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation
import SwiftData

//Used by persistence repository.
@Model
class WatchlistStock {
    var symbol: String
    var groupName: String
    var invested: Double

    init(symbol: String, groupName: String, invested: Double) {
        self.symbol = symbol
        self.groupName = groupName
        self.invested = invested
    }
}

extension WatchlistStock {
    func toDomainModel() -> Stock {
        Stock(
            symbol: symbol,
            ltp: 0,
            change: 0,
            percentChange: 0,
            invested: invested,
            currentValue: invested,
            groupName: groupName
        )
    }
}

