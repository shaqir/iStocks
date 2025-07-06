//
//  StockValidationError.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-06.
//

import Foundation

enum StockValidationError: Error {
    case duplicate
    case limitReached
    case invalidSymbol
    case notFound

    var alert: SharedAlertData {
        switch self {
        case .duplicate:
            return SharedAlertData(
                title: "Duplicate Stock",
                message: "This stock is already in the watchlist.",
                icon: "arrow.2.squarepath",
                action: nil
            )
        case .limitReached:
            return SharedAlertData(
                title: "Limit Reached",
                message: "You can add a maximum of 10 stocks.",
                icon: "exclamationmark.triangle.fill",
                action: nil
            )
        case .invalidSymbol:
            return SharedAlertData(
                title: "Invalid Stock",
                message: "Selected stock has no symbol.",
                icon: "xmark.circle.fill",
                action: nil
            )
        case .notFound:
            return SharedAlertData(
                title: "Stock Not Found",
                message: "The stock you're trying to remove doesn't exist in this watchlist.",
                icon: "minus.circle.fill",
                action: nil
            )
        }
    }
}
