//
//  StockRepositoryImpl.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//
import Foundation
import Combine

final class StockRepositoryImpl: StockRepository {
    
    private let remoteDataSource: StockRemoteDataSourceProtocol
    
    init(service: StockRemoteDataSourceProtocol) {
           self.remoteDataSource = service
    }

    func observeStocks() -> AnyPublisher<[Stock], any Error> {
        // from a real-time API
        //remoteDataSource.fetchWatchlistStocks()
        remoteDataSource.fetchRealtimePricesForTop50()
    }
    
}
