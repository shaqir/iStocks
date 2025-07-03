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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchText: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init(stocks: [Stock]) {
        self.stocks = stocks
        setupSearchBinding()
    }
    
    // MARK: - Computed filteredStocks (replaces @Published)
    var filteredStocks: [Stock] {
        guard !searchText.isEmpty else { return stocks }
        return stocks.filter {
            $0.symbol.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { _ in
            }
            .store(in: &cancellables)
    }

    func refresh() {
    }
}

