//
//  StockValidationError.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-06.
//

import Foundation

enum StockValidationError: Error {
    case duplicate
    case limitReached(num: Int)
    case invalidSymbol
    case notFound
    case failedToAdd
    case failedToDelete(String)

    var alert: SharedAlertData {
        switch self {
        case .duplicate:
            return SharedAlertData(
                title: "Duplicate Stock",
                message: "This stock is already in the watchlist.",
                icon: "arrow.2.squarepath",
                action: nil
            )
        case .limitReached(num: let num):
            return SharedAlertData(
                title: "Limit Reached",
                message: "You can add a maximum of \(num) stocks.",
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
        case .failedToAdd:
            return SharedAlertData(
                title: "Failed to Add Stock",
                message: "Something went wrong while adding the stock.",
                icon: "xmark.circle.fill",
                action: nil
            )
        case .failedToDelete(let error):
            return SharedAlertData(
                title: "Error Removing",
                message: error,
                icon: "trash",
                action: nil
            )
        }
    }
}
