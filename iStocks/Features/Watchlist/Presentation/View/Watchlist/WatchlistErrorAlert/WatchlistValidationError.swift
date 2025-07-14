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
    case tooManyWatchlists
    case atLeastOneStockRequired
    case emptyName
    
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
        case .tooManyWatchlists:
            return SharedAlertData(
                title: "Maximum Watchlists Reached.",
                message: "You can create a maximum of \(AppConstants.maxWatchlists) watchlists.",
                icon: "exclamationmark.triangle.fill",
                action: nil
            )
         case .atLeastOneStockRequired:
            return SharedAlertData(
                title: "At Least One Stock Required",
                message: "Add at least one stock before saving.",
                icon: "chart.line.uptrend.xyaxis", action: nil
            )
        case .emptyName:
            return SharedAlertData(
                title: "Empty Name",
                message: "Watchlist name cannot be empty.",
                icon: "exclamationmark.triangle.fill", action: nil
            )
        }
    }
}
