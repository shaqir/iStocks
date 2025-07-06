//
//  iStocksApp.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import SwiftUI
import SwiftData

@main
struct iStocksApp: App {
    var body: some Scene {
        WindowGroup {
            TabBarContainer()
                .environmentObject(SharedAlertManager.shared)
        }
        .modelContainer(for: [WatchlistEntity.self, StockEntity.self])
    }
}

 
