//
//  WatchlistsViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation
import Combine

final class WatchlistsViewModel: ObservableObject {
    @Published var watchlists: [Watchlist] = []
    @Published var selectedIndex: Int = 0
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    private let useCase: ObserveStocksUseCase
    private var cancellables = Set<AnyCancellable>()

    init(useCase: ObserveStocksUseCase) {
        self.useCase = useCase
    }

    func loadWatchlists() {
        isLoading = true
        useCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    let message = (error as? LocalizedError)?.errorDescription ?? "Please try again later."
                    self?.errorMessage = message
                }
            } receiveValue: { [weak self] stocks in
                self?.initializeWatchlists(with: stocks)
            }
            .store(in: &cancellables)
    }

    private func initializeWatchlists(with stocks: [Stock]) {
        self.watchlists = [
            Watchlist(name: "Tech Giants", stocks: stocks),
            Watchlist(name: "Nifty 50", stocks: stocks.shuffled()),
            Watchlist(name: "US Energy", stocks: stocks.shuffled()),
            Watchlist(name: "European Stocks", stocks: stocks.shuffled()),
            Watchlist(name: "Japanese Stocks", stocks: stocks.shuffled()),
            Watchlist(name: "Indian Stocks", stocks: stocks.shuffled()),
            Watchlist(name: "Australian Stocks", stocks: stocks.shuffled()),
            Watchlist(name: "British Stocks", stocks: stocks.shuffled()),
            Watchlist(name: "Canadian Stocks", stocks: stocks.shuffled()),
            Watchlist(name: "South African Stocks", stocks: stocks.shuffled()),
        ]
    }

    func updateWatchlist(at index: Int, with stocks: [Stock]) {
        guard watchlists.indices.contains(index) else { return }
        watchlists[index].stocks = stocks
    }
}
