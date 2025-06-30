//
//  StockRepositoryImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation
import Combine

final class StockRepositoryImpl: StockRepository {
    private let service: StockServiceProtocol

    init(service: StockServiceProtocol) {
        self.service = service
    }

    func getWatchlistStocks() -> AnyPublisher<[Stock], Error> {
        service.getWatchlistStocks()
    }
}
