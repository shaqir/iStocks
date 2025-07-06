//
//  WatchlistViewModelProvider.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation

final class WatchlistViewModelProvider {
    
    private var cache: [UUID: WatchlistViewModel] = [:]
    var onUpdate: ((Watchlist) -> Void)? // 🔁 Pass updates upward

    func viewModel(for watchlist: Watchlist) -> WatchlistViewModel {
        if let existing = cache[watchlist.id] {
            return existing
        }

        let new = WatchlistViewModel(watchlist: watchlist)

        // Wire up callback to persist any changes
        new.didUpdateStocks = { [weak self] updatedStocks in
            var updated = watchlist
            updated.stocks = updatedStocks
            self?.onUpdate?(updated)
        }

        cache[watchlist.id] = new
        return new
    }
}
