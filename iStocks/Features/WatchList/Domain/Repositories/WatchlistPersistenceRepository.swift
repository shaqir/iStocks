//
//  WatchlistPersistenceRepository.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation
import SwiftData

//Abstracts saving/removing symbols
protocol WatchlistPersistenceRepository {
    func loadSymbols(from context: ModelContext) -> [String]
    func add(symbol: String, in context: ModelContext)
    func remove(symbol: String, from context: ModelContext)
}
