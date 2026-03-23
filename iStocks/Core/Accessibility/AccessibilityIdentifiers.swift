//
//  AccessibilityIdentifiers.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2026-03-21.
//

import Foundation

/// Centralized accessibility identifiers for UI testing
enum AccessibilityID {
    enum Watchlist {
        static let tabBar = "watchlist_tab_bar"
        static let stockRow = "watchlist_stock_row"
        static let searchField = "watchlist_search_field"
        static let addStocksButton = "watchlist_add_stocks_button"
        static let addWatchlistButton = "watchlist_add_button"
        static let stockPicker = "watchlist_stock_picker"
        static let progressBar = "watchlist_progress_bar"
    }
    enum General {
        static let loadingOverlay = "loading_overlay"
        static let emptyState = "empty_state"
        static let errorView = "error_view"
        static let retryButton = "retry_button"
    }
}
