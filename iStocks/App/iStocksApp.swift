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
            #if targetEnvironment(simulator)
            // Skip biometric gate on simulator — no secure enclave available.
            // Auth flow is still fully demonstrable via BiometricAuthManager + AuthGateView.
            TabBarContainer()
                .environmentObject(SharedAlertManager.shared)
            #else
            AuthGateView(viewModel: AuthDIContainer.makeAuthViewModel()) {
                TabBarContainer()
                    .environmentObject(SharedAlertManager.shared)
            }
            #endif
        }
        .modelContainer(for: [WatchlistEntity.self, StockEntity.self])
    }
}

 
