//
//  TabRouterView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-30.
//

import SwiftUI

struct TabRouterView: View {
    
    let tab: TabViewEnum
    @StateObject private var watchlistsViewModel = WatchlistDIContainer.makeWatchlistsViewModel()

    var body: some View {
        switch tab {
        
        case .watchlist:
           // WatchlistView()
            WatchlistTabView(viewModel: watchlistsViewModel)
        
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
