//
//  WatchlistViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation
import Combine
import SwiftData

import Combine
import Foundation
import SwiftData

final class WatchlistViewModel: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""

    var modelContext: ModelContext? //Injected at runtime from the view

    private let fetchUseCase: FetchWatchlistStocksUseCase
    private let manageUseCase: ManageWatchlistUseCase

    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: AnyCancellable?

    init(fetchUseCase: FetchWatchlistStocksUseCase,
         manageUseCase: ManageWatchlistUseCase) {
        self.fetchUseCase = fetchUseCase
        self.manageUseCase = manageUseCase
    }
   
    // MARK: - Factory method
    static func previewInstance() -> WatchlistViewModel {
        let service = StockAPIService.shared
        let repo = StockRepositoryImpl(service: service)
        let fetchUseCase = FetchWatchlistStocksUseCaseImpl(repository: repo)
        let manageUseCase = ManageWatchlistUseCaseImpl(repo: SwiftDataWatchlistRepositoryImpl())
        return WatchlistViewModel(fetchUseCase: fetchUseCase, manageUseCase: manageUseCase)
    }
   
    func fetchStocks() {
        isLoading = true
        fetchUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.isLoading = false
                if case .failure(let error) = result {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] result in
                self?.stocks = result
            }
            .store(in: &cancellables)
    }
    
    var filteredStocks: [Stock] {
        searchText.isEmpty ? stocks :
            stocks.filter { $0.symbol.localizedCaseInsensitiveContains(searchText) }
    }

    var groupedStocks: [String: [Stock]] {
        Dictionary(grouping: filteredStocks, by: \.groupName)
    }

    // MARK: - Auto Refresher
    func startAutoRefresh(interval: TimeInterval = 15) {
        refreshTimer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.fetchStocks() }
    }

    func stopAutoRefresh() {
        refreshTimer?.cancel()
    }

    // MARK: - Local SwiftData Persistence Methods
    func loadSavedWatchlist() {
        guard let context = modelContext else { return }
        let symbols = manageUseCase.loadSymbols(from: context)
        self.stocks = symbols.map {
            Stock(symbol: $0, ltp: 0, change: 0, percentChange: 0,
                  invested: 1000, currentValue: 1080, groupName: "My Watchlist")
        }
    }

    func saveToWatchlist(_ symbol: String) {
        guard let context = modelContext else { return }
        manageUseCase.add(symbol: symbol, in: context)
        loadSavedWatchlist()
    }

    func deleteFromWatchlist(_ symbol: String) {
        guard let context = modelContext else { return }
        manageUseCase.remove(symbol: symbol, from: context)
        loadSavedWatchlist()
    }

}
