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

    // MARK: - Shared Use Cases
    let observeWatchlist: ObserveWatchlistStocksUseCase

    /// Fetch quotes for specific symbols (e.g. search bar, stock picker)
    let fetchQuotesBySymbols: FetchStocksBySymbolUseCase

    // MARK: - Init
    init(
        observeMock: ObserveMockStocksUseCase,
        observeTop50: ObserveTop50StocksUseCase,
        observeLiveWebSocket: ObserveStockPricesUseCase,
        observeWatchlist: ObserveWatchlistStocksUseCase,
        fetchQuotesBySymbols: FetchStocksBySymbolUseCase
    ) {
        self.observeMock = observeMock
        self.observeTop50 = observeTop50
        self.observeLiveWebSocket = observeLiveWebSocket
        self.observeWatchlist = observeWatchlist
        self.fetchQuotesBySymbols = fetchQuotesBySymbols
    }
}
