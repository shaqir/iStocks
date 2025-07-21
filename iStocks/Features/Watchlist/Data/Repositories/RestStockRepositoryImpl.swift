//
//  StockRepositoryImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//
import Foundation
import Combine

final class RestStockRepositoryImpl: RestStockRepository {
    
    private let remoteDataSource: StockRemoteDataSourceProtocol
    private let persistenceService: WatchlistPersistenceService

    @Published var batchProgress: BatchProgress? = nil

    var progressPublisher: AnyPublisher<BatchProgress, Never> {
            $batchProgress
                .compactMap { $0 } // remove nils
                .eraseToAnyPublisher()
        }
    
    init(service: StockRemoteDataSourceProtocol, persistenceService: WatchlistPersistenceService) {
           self.remoteDataSource = service
           self.persistenceService = persistenceService
    }
    
    func observeTop50Stocks() -> AnyPublisher<[Stock], Error> {
        
        let allSaved = persistenceService.loadAllStocks()
        let savedSymbols = Set(allSaved.map(\.symbol))
        let missingSymbols = NYSETop50Symbols.top50.filter { !savedSymbols.contains($0) }

        if missingSymbols.isEmpty {
            Logger.log("All top 50 symbols already saved — skipping API call", category: "RestStockRepository")
            return Just(allSaved)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        Logger.log("Fetching only \(missingSymbols.count) new symbols in batches", category: "RestStockRepository")

        return remoteDataSource.fetchRealtimePricesForTop50InBatches(
            missingSymbols,
            batchSize: 8,
            onProgress: { [weak self] index, total, retry, success in
                self?.batchProgress = BatchProgress(current: index,
                                                    total: total,
                                                    retryCount: retry,
                                                    success: success)
            }
        )
    }
    
    func fetchStockQuotes(for symbols: [String]) -> AnyPublisher<[Stock], any Error> {
        remoteDataSource.fetchRealtimePrices(for: symbols)
        
    }
}
