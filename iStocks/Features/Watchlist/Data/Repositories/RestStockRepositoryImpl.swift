//
//  StockRepositoryImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//
import Foundation
import Combine

nonisolated final class RestStockRepositoryImpl: RestStockRepository, @unchecked Sendable {
    
    private let remoteDataSource: StockRemoteDataSourceProtocol
    private let persistenceService: WatchlistPersistenceProtocol

    /// NOTE (Swift 6.2): nonisolated(unsafe) because CurrentValueSubject is not Sendable,
    /// but this is only accessed from the main thread via DispatchQueue.main.async.
    nonisolated(unsafe) var batchProgress: BatchProgress? = nil {
        didSet { batchProgressPassthrough.send(batchProgress) }
    }
    private let batchProgressPassthrough = PassthroughSubject<BatchProgress?, Never>()

    var progressPublisher: AnyPublisher<BatchProgress, Never> {
        batchProgressPassthrough
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }
    
    init(service: StockRemoteDataSourceProtocol, persistenceService: WatchlistPersistenceProtocol) {
           self.remoteDataSource = service
           self.persistenceService = persistenceService
    }
    
    func observeTop50Stocks() -> AnyPublisher<[Stock], Error> {
        
        let allSaved = persistenceService.loadAllStocks()
        let savedSymbols = Set(allSaved.map(\.symbol))
        let missingSymbols = NYSETop50Symbols.top50.filter { !savedSymbols.contains($0) }

        if missingSymbols.isEmpty {
            // Using cached data - no logging needed
            return Just(allSaved)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }

        // Only log if fetching significant amount of data
        if missingSymbols.count > 10 {
            AppLogger.info("Fetching \(missingSymbols.count) new symbols", category: AppLogger.network)
        }

        return remoteDataSource.fetchRealtimePricesForTop50InBatches(
            missingSymbols,
            batchSize: 8,
            onProgress: { [weak self] index, total, retry, success in
                DispatchQueue.main.async {
                    self?.batchProgress = BatchProgress(current: index,
                                                        total: total,
                                                        retryCount: retry,
                                                        success: success)
                }
            }
        )
    }
    
    func fetchStockQuotes(for symbols: [String]) -> AnyPublisher<[Stock], any Error> {
        return remoteDataSource.fetchRealtimePrices(for: symbols)
    }
}
