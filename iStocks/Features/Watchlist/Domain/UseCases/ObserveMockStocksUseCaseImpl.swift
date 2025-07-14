//
//  ObserveMockStocksUseCase.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-10.
//

import Foundation
import Combine

protocol ObserveMockStocksUseCase {
    func observe() -> AnyPublisher<[Stock], Error>
}

final class ObserveMockStocksUseCaseImpl: ObserveMockStocksUseCase {
    private let repository: WatchlistRepository
    
    init(repository: WatchlistRepository) {
        self.repository = repository
    }
    
    func observe() -> AnyPublisher<[Stock], Error> {
        repository.observeStocks()
    }
}
