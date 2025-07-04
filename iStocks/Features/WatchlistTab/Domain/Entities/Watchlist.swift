//
//  Watchlist.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation

struct Watchlist: Identifiable, Equatable {
    let id: UUID
    var name: String
    var stocks: [Stock]

    init(id: UUID = UUID(), name: String, stocks: [Stock]) {
        self.id = id
        self.name = name
        self.stocks = stocks
    }
}
