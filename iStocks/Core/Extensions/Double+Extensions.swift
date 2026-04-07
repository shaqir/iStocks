//
//  Double+Extension.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//

import Foundation

nonisolated extension Double {
    /// Convenience accessor — delegates to StockFormatter for cached formatting.
    var currencyFormatted: String {
        StockFormatter.formatPrice(self)
    }
}
