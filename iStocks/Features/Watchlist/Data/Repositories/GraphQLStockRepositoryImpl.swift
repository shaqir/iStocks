//
//  GraphQLStockRepositoryImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed.
//

import Foundation
import Combine

final class GraphQLStockRepositoryImpl: RestStockRepository {

    // MARK: - Dependencies

    private let graphQLDataSource: StockGraphQLDataSourceProtocol
    private let persistenceService: WatchlistPersistenceProtocol

    @Published var batchProgress: BatchProgress? = nil

    var progressPublisher: AnyPublisher<BatchProgress, Never> {
        $batchProgress
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    // MARK: - Init

    init(dataSource: StockGraphQLDataSourceProtocol, persistenceService: WatchlistPersistenceProtocol) {
        self.graphQLDataSource = dataSource
        self.persistenceService = persistenceService
    }

    // MARK: - WatchlistRepository

    func observeTop50Stocks() -> AnyPublisher<[Stock], Error> {
        let allSaved = persistenceService.loadAllStocks()
        let savedSymbols = Set(allSaved.map(\.symbol))
        let missingSymbols = NYSETop50Symbols.top50.filter { !savedSymbols.contains($0) }

        if missingSymbols.isEmpty {
            return Just(allSaved)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        if missingSymbols.count > 10 {
            AppLogger.info("GraphQL: Fetching \(missingSymbols.count) new symbols", category: AppLogger.network)
        }

        return graphQLDataSource.fetchTop50Stocks()
    }

    // MARK: - RestStockRepository

    func fetchStockQuotes(for symbols: [String]) -> AnyPublisher<[Stock], Error> {
        return graphQLDataSource.fetchStockQuotes(for: symbols)
    }
}
