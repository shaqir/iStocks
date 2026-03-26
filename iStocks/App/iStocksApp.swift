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
            AuthGateView(viewModel: AuthDIContainer.makeAuthViewModel()) {
                TabBarContainer()
                    .environmentObject(SharedAlertManager.shared)
            }
        }
        .modelContainer(for: [WatchlistEntity.self, StockEntity.self])
    }
}

 
