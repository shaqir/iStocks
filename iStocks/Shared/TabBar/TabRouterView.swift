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
            
            let vm = WatchlistDIContainer.makeWatchlistsViewModel(context: context)
            WatchlistTabView(viewModel: vm)
        
        case .orders:
            OrderView()
        
        case .portfolio:
            PortfolioView()
        
        case .bids:
            BidsView()
        
        case .settings:
            SettingsView()
        }
    }
}
