//
//  TabRouterView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//

import SwiftUI
import SwiftData

struct TabRouterView: View {
    
    let tab: TabViewEnum
    @Environment(\.modelContext) private var context
    
    var body: some View {
        switch tab {

        case .watchlist:
            WatchlistTabContainerView(context: context)

        case .orders:
            OrderView()

        case .portfolio:
            DashboardView(viewModel: DashboardDIContainer.makeDashboardViewModel())

        case .research:
            StockResearchView()

        case .settings:
            SettingsView()
        }
    }
}

