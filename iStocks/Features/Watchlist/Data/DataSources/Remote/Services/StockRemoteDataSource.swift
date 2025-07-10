//
//  StockAPIService.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation
import Combine


protocol StockRemoteDataSourceProtocol {
    func fetchRealtimePricesForTop5() -> AnyPublisher<[Stock], Error>
    func fetchRealtimePricesForTop50() -> AnyPublisher<[Stock], Error>
}

import Combine

final class StockRemoteDataSource: StockRemoteDataSourceProtocol {
    private let networkClient: NetworkClient
   
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func fetchRealtimePricesForTop5() -> AnyPublisher<[Stock], Error> {
        let endpoint = Endpoint(
            path: "/quote",
            method: .get,
            queryItems: [
                URLQueryItem(name: "symbol", value: NYSETop50Symbols.top5.joined(separator: ",")),
                URLQueryItem(name: "apikey", value: API.apiKey)
            ]
        )
        
        print(endpoint.url!)

        return networkClient.request(endpoint)
            .tryMap { try QuoteResponseMapper.map($0) }
            .mapError { self.handleAndMapToAppError($0) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func fetchRealtimePricesForTop50() -> AnyPublisher<[Stock], Error> {
        let endpoint = PriceEndpoint.forSymbols(NYSETop50Symbols.top50, apiKey: API.apiKey)

        print(endpoint.url!)

        return networkClient.request(endpoint)
            .map { PriceResponseMapper.map($0) }
            .mapError { self.handleAndMapToAppError($0) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func handleAndMapToAppError(_ error: Error) -> AppError {
        let appError: AppError
        if let api = error as? TwelveDataAPIError {
            appError = .api(message: api.errorDescription ?? "Unknown API error")
            SharedAlertManager.shared.show(api.alert)
        } else if let network = error as? NetworkError {
            appError = .network(network)
        } else {
            appError = .unknown(error)
        }
        return appError
    }
}
