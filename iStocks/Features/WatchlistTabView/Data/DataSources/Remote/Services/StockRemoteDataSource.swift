//
//  StockAPIService.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//

import Foundation
import Combine


protocol StockRemoteDataSourceProtocol {
    func fetchWatchlistStocks() -> AnyPublisher<[Stock], Error>
}

final class StockRemoteDataSource: StockRemoteDataSourceProtocol {
    
    private let networkClient: NetworkClient
    private let apiKey = "a76f9d57dab34a779a42f9e9558e5fc2"
    private let symbols = ["AAPL", "MSFT", "TSLA", "GOOGL", "AMZN", "NVDA"]
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    func fetchWatchlistStocks() -> AnyPublisher<[Stock], Error> {
        let endpoint = Endpoint(
            path: "/quote",
            method: .get,
            queryItems: [
                URLQueryItem(name: "symbol", value: symbols.joined(separator: ",")),
                URLQueryItem(name: "apikey", value: apiKey)
            ]
        )
        
        return networkClient.request(endpoint)
            .tryMap { [weak self] (responseDict: [String: StockResponseWrapper]) in
                guard let self = self else { return [] }
                return try self.processResponse(responseDict)
            }
            .mapError { error in
                self.mapToAppError(error)
            }
            .eraseToAnyPublisher()
    }
    
    private func processResponse(_ responseDict: [String: StockResponseWrapper]) throws -> [Stock] {
        var validStocks: [Stock] = []
        var errorMessages: [String] = []
        
        for (symbol, result) in responseDict {
            switch result {
            case .success(let response):
                if let stock = response.toDomainModel(invested: Double.random(in: 50000...100000)) {
                    validStocks.append(stock)
                }
            case .error(let apiError):
                errorMessages.append("\(symbol): \(apiError.errorDescription ?? "Unknown error")")
            }
        }
        
        if validStocks.isEmpty {
            throw TwelveDataAPIError.invalidSymbols(errorMessages)
        }
        
        return validStocks
    }
    
    private func mapToAppError(_ error: Error) -> AppError {
        if let api = error as? TwelveDataAPIError {
            return .api(message: api.errorDescription ?? "apiError")
        } else if let network = error as? NetworkError {
            return .network(network)
        } else {
            return .unknown(error)
        }
    }
}
