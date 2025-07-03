//
//  WatchlistViewModelProvider.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation

final class WatchlistViewModelProvider {
    private var cache: [UUID: WatchlistViewModel] = [:]

    func viewModel(for watchlist: Watchlist) -> WatchlistViewModel {
        if let existing = cache[watchlist.id] { return existing }
        let new = WatchlistViewModel(stocks: watchlist.stocks)
        cache[watchlist.id] = new
        return new
    }
}
