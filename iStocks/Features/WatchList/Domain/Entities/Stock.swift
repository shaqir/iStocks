//
//  Stock.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation

//Pure Swift struct, reusable and testable.
//Represents the business model: symbol, LTP, change %, PnL, etc.
struct Stock: Identifiable, Codable {
    var id: UUID = UUID()
    let symbol: String
    let ltp: Double
    let change: Double
    let percentChange: Double
    let invested: Double
    let currentValue: Double
    let groupName: String

    var pnl: Double {
        currentValue - invested
    }

    var pnlPercentage: Double {
        (pnl / invested) * 100
    }
}
