//
//  Double+Extension.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//

import Foundation

extension Double {
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    var currencyFormatted: String {
        Double.currencyFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
