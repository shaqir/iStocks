//
//  WatchlistTabContainerView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-14.
//

import SwiftUI
import SwiftData

struct WatchlistTabContainerView: View {
    
    @StateObject private var viewModel: WatchlistsViewModel
    var watchlistVmProvider: WatchlistViewModelProvider
    @State private var hasLoaded = false
    
    init(context: ModelContext) {
        Logger.log("WatchlistTabContainerView() called.")
        let useCases = WatchlistDIContainer.makeWatchlistUseCases(context: context)
        let provider = DefaultWatchlistViewModelProvider(useCases: useCases)
        self.watchlistVmProvider = provider
        _viewModel = StateObject(
            wrappedValue: WatchlistDIContainer.makeWatchlistsViewModel(
                mode: WatchlistDIContainer.mode,
                context: context,
                viewModelProvider: provider
            )
        )
    }
    
    var body: some View {
        WatchlistTabView(viewModel: viewModel, viewModelProvider: watchlistVmProvider)
            .onAppear {
                Logger.log("[Appear] WatchlistTabContainerView into view hierarchy")
                if !hasLoaded {
                    viewModel.loadWatchlists() // Load persisted data
                    viewModel.startObservingGlobalPriceUpdates()//Start price-observation globally
                    hasLoaded = true
                }
            }
            .onDisappear {
                Logger.log("[Disappear] WatchlistTabContainerView removed from view hierarchy")
            }
    }
    
}
