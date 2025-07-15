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
        let useCases = WatchlistDIContainer.makeWatchlistUseCases()
        let provider = WatchlistViewModelProvider(useCases: useCases)
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
                    viewModel.loadWatchlists()///Load only once & then just observe
                    hasLoaded = true
                }
                
                // Delay price observation slightly to ensure cache is populated
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.observeLiveStockPrices() // Update prices
                    }
            }
    }
}
