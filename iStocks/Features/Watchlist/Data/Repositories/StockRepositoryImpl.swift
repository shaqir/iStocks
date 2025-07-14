//
//  StockRepositoryImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//
import Foundation
import Combine

final class StockRepositoryImpl: WatchlistRepository {
    
    private let remoteDataSource: StockRemoteDataSourceProtocol

    init(service: StockRemoteDataSourceProtocol) {
        self.remoteDataSource = service
    }

    func observeTop5Stocks() -> AnyPublisher<[Stock], Error> {
        remoteDataSource.fetchRealtimePricesForTop5()
    }

    func observeTop50Stocks() -> AnyPublisher<[Stock], Error> {
        remoteDataSource.fetchRealtimePricesForTop50InBatches()
    }

    func observeStocks() -> AnyPublisher<[Stock], Error> {
        // Fallback: Top 5 for example
        remoteDataSource.fetchRealtimePricesForTop5()
        //remoteDataSource.fetchRealtimePricesForTop50InBatches()
    }
}
