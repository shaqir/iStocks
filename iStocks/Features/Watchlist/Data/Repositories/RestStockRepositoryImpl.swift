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
    
    init(service: StockRemoteDataSourceProtocol) {
        self.remoteDataSource = service
    }
    
    func observeTop50Stocks() -> AnyPublisher<[Stock], Error> {
        remoteDataSource.fetchRealtimePricesForTop50InBatches()
    }
    
    func fetchStockQuotes(for symbols: [String]) -> AnyPublisher<[Stock], any Error> {
        remoteDataSource.fetchRealtimePrices(for: symbols)
        
    }
}

