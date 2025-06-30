//
//  ManageWatchlistUseCaseImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation
import SwiftData

final class ManageWatchlistUseCaseImpl: ManageWatchlistUseCase {
    private let repo: WatchlistPersistenceRepository

    init(repo: WatchlistPersistenceRepository) {
        self.repo = repo
    }

    func loadSymbols(from context: ModelContext) -> [String] {
        repo.loadSymbols(from: context)
    }

    func add(symbol: String, in context: ModelContext) {
        repo.add(symbol: symbol, in: context)
    }

    func remove(symbol: String, from context: ModelContext) {
        repo.remove(symbol: symbol, from: context)
    }
}
