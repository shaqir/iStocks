//
//  WatchlistUseCases.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-15.
//
import Foundation

/// A centralized container for all stock-related use cases.
/// Injected into ViewModels and shared across the Watchlist module.
struct WatchlistUseCases {

    // MARK: - Mode-Specific Use Cases
    let observeMock: ObserveMockStocksUseCase
    let observeTop50: ObserveTop50StocksUseCase
    let observeLiveWebSocket: ObserveStockPricesUseCase

    /// Fetch quotes for specific symbols (e.g. search bar, stock picker)
    let fetchQuotesBySymbols: FetchStocksBySymbolUseCase

    // MARK: - Persistence Use Cases
    let saveWatchlists: SaveWatchlistsUseCase
    let loadWatchlists: LoadWatchlistsUseCase

    // MARK: - Init
    init(
        observeMock: ObserveMockStocksUseCase,
        observeTop50: ObserveTop50StocksUseCase,
        observeLiveWebSocket: ObserveStockPricesUseCase,
        fetchQuotesBySymbols: FetchStocksBySymbolUseCase,
        saveWatchlists: SaveWatchlistsUseCase,
        loadWatchlists: LoadWatchlistsUseCase
    ) {
        self.observeMock = observeMock
        self.observeTop50 = observeTop50
        self.observeLiveWebSocket = observeLiveWebSocket
        self.fetchQuotesBySymbols = fetchQuotesBySymbols
        self.saveWatchlists = saveWatchlists
        self.loadWatchlists = loadWatchlists
    }
}
