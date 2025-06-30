//
//  iStocksApp.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-07.
//

import SwiftUI
import SwiftData

@main
struct iStocksApp: App {
    var body: some Scene {
        WindowGroup {
            TabBarContainer()
        }
        .modelContainer(for: WatchlistStock.self)
    }
}
