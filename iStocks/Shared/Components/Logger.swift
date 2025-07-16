//
//  Logger.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-15.
//

import Foundation

enum Logger {
    static var isEnabled = true

    static func log(_ message: String, category: String = "General") {
        guard isEnabled else { return }
        print("[\(category)] \(message)")
    }
}
