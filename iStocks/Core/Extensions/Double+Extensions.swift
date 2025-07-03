//
//  Double+Extension.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//

import Foundation

extension Double {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$" // or "₹", or use locale
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
