//
//  AccessibilityIdentifiers.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2026-03-21.
//

import Foundation

/// Centralized accessibility identifiers for UI testing
nonisolated enum AccessibilityID {
    /// Bottom tab bar buttons. `tab` is the lowercased TabViewEnum case (e.g. "watchlist").
    enum Tabs {
        static func identifier(_ tab: String) -> String { "tab_" + tab }
    }
    enum Watchlist {
        static let tabBar = "watchlist_tab_bar"
        static let stockRow = "watchlist_stock_row"
        static let searchField = "watchlist_search_field"
        static let addStocksButton = "watchlist_add_stocks_button"
        static let addWatchlistButton = "watchlist_add_button"
        static let stockPicker = "watchlist_stock_picker"
        static let progressBar = "watchlist_progress_bar"
    }
    enum Dashboard {
        static let portfolioSummary = "dashboard_portfolio_summary"
        static let holdingRow = "dashboard_holding_row"
        static let newsSection = "dashboard_news_section"
        static let refreshButton = "dashboard_refresh_button"
    }
    enum Auth {
        static let authGate = "auth_gate"
        static let biometricButton = "auth_biometric_button"
        static let retryButton = "auth_retry_button"
    }
    enum General {
        static let loadingOverlay = "loading_overlay"
        static let emptyState = "empty_state"
        static let errorView = "error_view"
        static let retryButton = "retry_button"
    }
}
