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
            PortfolioView()
        
        case .bids:
            BidsView()
        
        case .settings:
            SettingsView()
        }
    }
}

struct WatchlistTabContainerView: View {
    @StateObject private var viewModel: WatchlistsViewModel

    init(context: ModelContext) {
        _viewModel = StateObject(wrappedValue: WatchlistDIContainer.makeWatchlistsViewModel(context: context))
    }

    var body: some View {
        WatchlistTabView(viewModel: viewModel)
    }
}
