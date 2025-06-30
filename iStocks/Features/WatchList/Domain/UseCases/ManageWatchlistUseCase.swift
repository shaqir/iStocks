//
//  ManageWatchlistUseCase.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation
import SwiftData

//Save/load/delete from SwiftData
protocol ManageWatchlistUseCase {
    func loadSymbols(from context: ModelContext) -> [String]
    func add(symbol: String, in context: ModelContext)
    func remove(symbol: String, from context: ModelContext)
}
