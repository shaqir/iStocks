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
    func fetchRealtimePricesForTop50InBatches() -> AnyPublisher<[Stock], Error>
}

import Combine

final class StockRemoteDataSource: StockRemoteDataSourceProtocol {
    
    private let networkClient: NetworkClient
    
    //Stores Combine subscriptions to manage memory and cancel publishers when needed.
    private var cancellables = Set<AnyCancellable>()
    
    
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
        Logger.log("endpoint.url!", category: "StockRemoteDataSource")
        return networkClient.request(endpoint)
            .tryMap { try QuoteResponseMapper.map($0) }
            .mapError { self.handleAndMapToAppError($0) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    ///Chunks the top 50 symbols into groups of 8
    ///Requests them one at a time with a delay
    ///Uses Combine to merge results and emit alerts if needed
    func fetchRealtimePricesForTop50InBatches() -> AnyPublisher<[Stock], Error> {
        let batches = NYSETop50Symbols.top50.chunked(into: 8)
        let subject = PassthroughSubject<[Stock], Error>()

        fetchSequentially(batches: batches, subject: subject)
        return subject.eraseToAnyPublisher()
    }

    private func fetchSequentially(
        batches: [[String]],
        subject: PassthroughSubject<[Stock], Error>,
        index: Int = 0
    ) {
        guard index < batches.count else {
            subject.send(completion: .finished)
            return
        }

        let batch = batches[index]
        Logger.log("Sending batch \(index + 1): \(batch)", category: "StockRemoteDataSource")
        fetchPrices(for: batch)
            .catch { [weak self] error -> AnyPublisher<[Stock], Error> in
                _ = self?.handleAndMapToAppError(error)
                return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { _ in }, receiveValue: { stocks in
                subject.send(stocks)

                // Delay before next batch
                DispatchQueue.global().asyncAfter(deadline: .now() + 65) {
                    self.fetchSequentially(batches: batches, subject: subject, index: index + 1)
                }
            })
            .store(in: &cancellables)
    }
    private func fetchPrices(for symbols: [String]) -> AnyPublisher<[Stock], Error> {
        let endpoint = PriceEndpoint.forSymbols(symbols, apiKey: API.apiKey)

        return networkClient.request(endpoint)
            .map { (rawMap: [String: StockPriceDTO]) in
                rawMap.compactMap { symbol, dto in
                    dto.toStockPrice(symbol: symbol)
                }
            }
            .mapError(handleAndMapToAppError(_:))
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
        Logger.log("api error: \(appError)", category: "StockRemoteDataSource")
        return appError
    }
}
