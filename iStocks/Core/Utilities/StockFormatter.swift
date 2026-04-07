//
//  StockFormatter.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Centralized stock data formatting with cached NumberFormatters.
///
/// NOTE: Creating a NumberFormatter on every cell render is a common performance
/// anti-pattern in table/list views. Caching formatters as static properties
/// eliminates this overhead — each formatter is created once for the app's lifetime.
///
/// NOTE (Swift 6.2): nonisolated because formatting is a pure computation used
/// across all isolation contexts.
nonisolated enum StockFormatter {

    // MARK: - Cached Formatters

    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.multiplier = 1 // value is already a percentage
        return formatter
    }()

    private static let changeFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.positivePrefix = "+"
        return formatter
    }()

    // MARK: - Formatting Methods

    /// Format a price value with currency symbol (e.g., "$150.25")
    static func formatPrice(_ value: Double, currency: String = "USD") -> String {
        priceFormatter.string(from: NSNumber(value: value)) ?? String(format: "$%.2f", value)
    }

    /// Format a price change with sign (e.g., "+3.25" or "-1.50")
    static func formatChange(_ value: Double) -> String {
        changeFormatter.string(from: NSNumber(value: value)) ?? String(format: "%+.2f", value)
    }

    /// Format a percentage value (e.g., "2.15%" or "-0.50%")
    static func formatPercentage(_ value: Double) -> String {
        let formatted = percentFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f%%", value)
        return value >= 0 ? "+\(formatted)" : formatted
    }

    /// Format volume with abbreviated suffixes (e.g., "1.2M", "3.5B", "850K")
    static func formatVolume(_ value: Double) -> String {
        switch abs(value) {
        case 1_000_000_000...:
            return String(format: "%.1fB", value / 1_000_000_000)
        case 1_000_000...:
            return String(format: "%.1fM", value / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", value / 1_000)
        default:
            return String(format: "%.0f", value)
        }
    }

    /// Format market cap with abbreviated suffixes (e.g., "$2.5T", "$150.3B")
    static func formatMarketCap(_ value: Double) -> String {
        switch abs(value) {
        case 1_000_000_000_000...:
            return String(format: "$%.1fT", value / 1_000_000_000_000)
        case 1_000_000_000...:
            return String(format: "$%.1fB", value / 1_000_000_000)
        case 1_000_000...:
            return String(format: "$%.1fM", value / 1_000_000)
        default:
            return formatPrice(value)
        }
    }
}
