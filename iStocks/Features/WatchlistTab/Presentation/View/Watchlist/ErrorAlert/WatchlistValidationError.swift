//
//  WatchlistValidationError.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-07.
//

import Foundation

enum WatchlistValidationError: Error {
    case nameRequired
    case noStocksAdded
    case unexpectedError(String)
    
    var alert: SharedAlertData {
        switch self {
        case .nameRequired:
            return SharedAlertData(
                title: "Name Required",
                message: "Watchlist name cannot be empty.",
                icon: "exclamationmark.triangle.fill", action: nil
            )
        case .noStocksAdded:
            return SharedAlertData(
                title: "No Stocks Added",
                message: "Add at least one stock before saving.",
                icon: "chart.line.uptrend.xyaxis", action: nil
            )
        case .unexpectedError(let error):
            return SharedAlertData(
                title: "Unexpected Error",
                message: error,
                icon: "exclamationmark.triangle.fill",
                action: nil
            )
            
        }
    }
}
