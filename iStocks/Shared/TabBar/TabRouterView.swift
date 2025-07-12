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
    var watchlistVmProvider: WatchlistViewModelProvider
    @State private var hasLoaded = false

    init(context: ModelContext) {
        let observeUseCase = WatchlistDIContainer.makeWatchlistStocksUseCase()
        let provider = WatchlistViewModelProvider(observeUseCase: observeUseCase)
        self.watchlistVmProvider = provider
        _viewModel = StateObject(
            wrappedValue: WatchlistDIContainer.makeWatchlistsViewModel(
                context: context,
                viewModelProvider: provider
            )
        )
    }

    var body: some View {
        WatchlistTabView(viewModel: viewModel, viewModelProvider: watchlistVmProvider)
            .onAppear {
                if !hasLoaded {
                    viewModel.loadWatchlists()///Load only once
                    hasLoaded = true
                }
            }
    }
}
