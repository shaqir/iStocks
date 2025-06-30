//
//  FetchWatchlistStocksUseCaseImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation
import Combine

//Fetch stocks from network
protocol FetchWatchlistStocksUseCase {
    func execute() -> AnyPublisher<[Stock], Error>
}
 
