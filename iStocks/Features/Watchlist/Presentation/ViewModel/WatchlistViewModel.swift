//
//  WatchlistViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//
import Foundation
import Combine

///sync and delegate to Watchlist, notify parent
final class WatchlistViewModel: ObservableObject {
    @Published var watchlist: Watchlist
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    @Published var animatedSymbols: Set<String> = []

    private let observeUseCase: ObserveWatchlistStocksUseCase
    private var liveUpdatesCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    let watchlistDidUpdate = PassthroughSubject<Watchlist, Never>()

    var selectedStocks: [Stock] {
        watchlist.stocks
    }

    init(watchlist: Watchlist, observeUseCase: ObserveWatchlistStocksUseCase) {
        self.watchlist = watchlist
        self.observeUseCase = observeUseCase
        setupSearchBinding()
    }

    func isSelected(_ stock: Stock) -> Bool {
        watchlist.stocks.contains(where: { $0.symbol == stock.symbol })
    }

    var filteredStocks: [Stock] {
        guard !searchText.isEmpty else {
            return selectedStocks.sorted { $0.symbol < $1.symbol }
        }
        return selectedStocks
            .filter { $0.symbol.localizedCaseInsensitiveContains(searchText) }
            .sorted { $0.symbol < $1.symbol }
    }

    func observeLiveUpdates() {
        guard WatchlistDIContainer.mode == .mock else { return }

        // Cancel existing live updates if any
        cancelLiveUpdates()

        liveUpdatesCancellable = $watchlist
            .map { [observeUseCase] watchlist in
                observeUseCase.observeLiveUpdates(for: watchlist)
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedStocks in
                self?.replaceStocks(updatedStocks)
            }
    }

    func cancelLiveUpdates() {
        liveUpdatesCancellable?.cancel()
        liveUpdatesCancellable = nil
    }

    func addStock(_ stock: Stock) {
        var updated = watchlist
        do {
            try updated.tryAddStock(stock)
            watchlist = updated
            syncWithParent()
        } catch let error as StockValidationError {
            SharedAlertManager.shared.show(error.alert)
        } catch {
            SharedAlertManager.shared.show(StockValidationError.failedToAdd.alert)
        }
    }

    func removeStock(_ stock: Stock) {
        var updated = watchlist
        do {
            try updated.tryRemoveStock(stock)
            watchlist = updated
            syncWithParent()
        } catch {
            SharedAlertManager.shared.show(
                StockValidationError.failedToDelete(error.localizedDescription).alert
            )
        }
    }

    func replaceStocks(_ newStocks: [Stock]) {
        guard !newStocks.isEmpty else { return }
        print("update prices only....")
        watchlist.replacePrices(from: newStocks)
        syncWithParent()
    }

    func updateStocks(with newStocks: [Stock]) {
        watchlist.stocks = newStocks
        syncWithParent()
    }

    func updateWatchlist(_ newValue: Watchlist) {
        DispatchQueue.main.async {
            self.watchlist = newValue
        }
    }

    func syncWithParent() {
        watchlistDidUpdate.send(watchlist)
    }

    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { _ in }
            .store(in: &cancellables)
    }
}
