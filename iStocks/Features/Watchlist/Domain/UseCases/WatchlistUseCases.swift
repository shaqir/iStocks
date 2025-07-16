//
//  WatchlistUseCases.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-15.
//
import Foundation

/// A centralized container for all stock-related use cases.
/// Injected into ViewModels and other layers that need access to stock data logic.
struct WatchlistUseCases {

    // MARK: - Mode-Specific Use Cases

    /// Used in `.mock` mode to simulate bulk stream of all mocked stocks.
    /// Example: `loadMockData()`, mock-based observation
    let observeMock: ObserveMockStocksUseCase

    /// Used in `.restAPI` mode to fetch top 50 trending or popular stocks.
    /// Example: `loadTop50StockPricesFromServer()`
    let observeTop50: ObserveTop50StocksUseCase

    // MARK: - Shared Use Cases

    /// Observes stock updates for a specific `Watchlist`, filtering only relevant stocks.
    /// Used in both `.mock` and `.restAPI` mode for tab-level price updates.
    /// Example: `observePricesForWatchlist(at:)`
    let observeWatchlist: ObserveWatchlistStocksUseCase

    /// Observes live updates for all stocks currently cached/fetched.
    /// Typically used to broadcast global price changes to all watchlists.
    /// Example: `observeLiveStockPrices()`
    let observeGlobalPrices: ObserveStockPricesUseCase

    // MARK: - Init

    init(
        observeMock: ObserveMockStocksUseCase,
        observeTop50: ObserveTop50StocksUseCase,
        observeWatchlist: ObserveWatchlistStocksUseCase,
        observeGlobalPrices: ObserveStockPricesUseCase
    ) {
        self.observeMock = observeMock
        self.observeTop50 = observeTop50
        self.observeWatchlist = observeWatchlist
        self.observeGlobalPrices = observeGlobalPrices
    }
}
