//
//  WatchlistViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//
import Foundation
import Combine

final class WatchlistViewModel: ObservableObject {
    
    @Published var stocks: [Stock] = []
    var didUpdateStocks: (([Stock]) -> Void)? // Callback

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init(stocks: [Stock]) {
        self.stocks = stocks
        setupSearchBinding()
    }
    
    // MARK: - Computed filteredStocks (replaces @Published)
    // MARK: - Computed filteredStocks (returns [Stock])
    var filteredStocks: [Stock] {
        guard !searchText.isEmpty else {
            return Array(stocks).sorted(by: { $0.symbol < $1.symbol })
        }
        return stocks
            .filter { $0.symbol.localizedCaseInsensitiveContains(searchText) }
            .sorted(by: { $0.symbol < $1.symbol })
    }
    
    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { _ in
            }
            .store(in: &cancellables)
    }

    func addStock(_ stock: Stock) {
        guard !stocks.contains(stock), stocks.count < 50 else { return }
        stocks.append(stock)
        // Notify parent VM
        didUpdateStocks?(stocks)

    }
    
}

