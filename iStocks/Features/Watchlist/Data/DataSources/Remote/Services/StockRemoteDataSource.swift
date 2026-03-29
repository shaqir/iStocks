//
//  StockAPIService.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-06-29.
//
import Foundation
import Combine

// MARK: - Protocol

protocol StockRemoteDataSourceProtocol {
    func fetchRealtimePrices(for symbols: [String]) -> AnyPublisher<[Stock], Error>
    func fetchRealtimePricesForTop50InBatches(
        _ symbols: [String],
        batchSize: Int,
        onProgress: BatchProgressHandler?
    ) -> AnyPublisher<[Stock], Error>
}

typealias BatchProgressHandler = (_ batchIndex: Int, _ totalBatches: Int, _ retryAttempt: Int, _ success: Bool) -> Void

// MARK: - Implementation

final class StockRemoteDataSource: StockRemoteDataSourceProtocol {
    
    // MARK: - Dependencies

    private let networkClient: NetworkClient
    private var cancellables = Set<AnyCancellable>()
    private let batchDelay: TimeInterval
    
    // MARK: - Init

    init(networkClient: NetworkClient, batchDelay: TimeInterval = 60) {
            self.networkClient = networkClient
            self.batchDelay = batchDelay
        }

    // MARK: - Public Methods
    func fetchRealtimePrices(for symbols: [String]) -> AnyPublisher<[Stock], Error> {
        let endpoint = QuoteEndPoint.forSymbols(symbols, apiKey: SecureAPIKeyManager.twelveDataAPIKey)
        // Verbose logging removed
        return networkClient.request(endpoint)
            .tryMap { (response: StockQuoteDynamicResponse) in
                // Verbose logging removed
                switch response {
                case .dictionary(let map):
                    // Verbose logging removed
                    let stocks = try QuoteResponseMapper.map(map)
                    guard !stocks.isEmpty else {
                        throw AppError.api(message: "Invalid or empty response for symbols: \(symbols)")
                    }
                    return stocks

                case .single(let wrapper):
                    // Verbose logging removed
                    let stocks = try QuoteResponseMapper.map(["SINGLE": wrapper])
                    guard !stocks.isEmpty else {
                        throw AppError.api(message: "Invalid or empty response for symbols: \(symbols)")
                    }
                    return stocks
                }
            }
            .mapError(self.handleAndMapToAppError(_:))
            .eraseToAnyPublisher()
    }

    func fetchRealtimePricesForTop50InBatches(
        _ symbols: [String],
        batchSize: Int,
        onProgress: BatchProgressHandler? = nil
    ) -> AnyPublisher<[Stock], Error> {
        let batches = symbols.chunked(into: batchSize)
        let subject = PassthroughSubject<[Stock], Error>()

        fetchSequentiallyWithRetry(
            batches: batches,
            subject: subject,
            onProgress: onProgress
        )

        return subject.eraseToAnyPublisher()
    }

    // MARK: - Private Helpers

    private func fetchPrices(for symbols: [String]) -> AnyPublisher<[Stock], Error> {
        let endpoint = PriceEndpoint.forSymbols(symbols, apiKey: SecureAPIKeyManager.twelveDataAPIKey)
        
        return networkClient.request(endpoint)
            .map { (rawMap: [String: StockPriceDTO]) in
                rawMap.compactMap { symbol, dto in
                    dto.toStockPrice(symbol: symbol)
                }
            }
            .mapError(self.handleAndMapToAppError(_:))
            .eraseToAnyPublisher()
    }

    private func fetchSequentiallyWithRetry(
        batches: [[String]],
        subject: PassthroughSubject<[Stock], Error>,
        index: Int = 0,
        retryCounts: [Int] = [],
        onProgress: BatchProgressHandler? = nil
    ) {
        guard index < batches.count else {
            subject.send(completion: .finished)
            return
        }

        let batch = batches[index]
        let totalBatches = batches.count
        let currentRetry = retryCounts.indices.contains(index) ? retryCounts[index] : 0

        // Only log first batch and errors (reduce verbosity)
        if index == 0 {
            AppLogger.info("Starting batch fetch: \(totalBatches) batches", category: AppLogger.network)
        }

        fetchPrices(for: batch)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self else { return }

                switch completion {
                case .finished:
                    onProgress?(index + 1, totalBatches, currentRetry, true)

                case .failure:
                    if currentRetry < 2 {
                        AppLogger.warning("Retrying batch \(index + 1) in 60s (Attempt \(currentRetry + 2))", category: AppLogger.network)
                        onProgress?(index + 1, totalBatches, currentRetry + 1, false)

                        var updatedRetryCounts = retryCounts
                        if updatedRetryCounts.count <= index {
                            updatedRetryCounts.append(contentsOf: Array(repeating: 0, count: index - updatedRetryCounts.count + 1))
                        }
                        updatedRetryCounts[index] += 1

                        DispatchQueue.global().asyncAfter(deadline: .now() + self.batchDelay) { [weak self] in
                            self?.fetchSequentiallyWithRetry(
                                batches: batches,
                                subject: subject,
                                index: index,
                                retryCounts: updatedRetryCounts,
                                onProgress: onProgress
                            )
                        }
                        return
                    } else {
                        AppLogger.error("Failed batch \(index + 1) after 3 tries — skipping", category: AppLogger.network)
                        onProgress?(index + 1, totalBatches, currentRetry, false)
                    }
                }

                // Proceed to next batch after delay
                DispatchQueue.global().asyncAfter(deadline: .now() + 60) { [weak self] in
                    self?.fetchSequentiallyWithRetry(
                        batches: batches,
                        subject: subject,
                        index: index + 1,
                        retryCounts: retryCounts,
                        onProgress: onProgress
                    )
                }
            },
                  receiveValue: { stocks in
                  subject.send(stocks)
            })
            .store(in: &cancellables)
    }

    private func handleAndMapToAppError(_ error: Error) -> AppError {
        let appError: AppError
        if let api = error as? TwelveDataAPIError {
            // Errors propagate as AppError — ViewModels decide how to display alerts.
            // The data layer must not access UI components directly.
            appError = .api(message: api.errorDescription ?? "Unknown API error")
        } else if let network = error as? NetworkError {
            appError = .network(network)
        } else {
            appError = .unknown(error)
        }
        AppLogger.error("API error: \(appError)", category: AppLogger.network)
        return appError
    }
}


//MARK : Only For Testing
extension StockRemoteDataSource{
    
    func fetchRealtimePricesAsync(for symbols: [String]) async throws -> [Stock] {
        try await withCheckedThrowingContinuation { continuation in
            self.fetchRealtimePrices(for: symbols)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        continuation.resume(throwing: error)
                    }
                }, receiveValue: { stocks in
                    continuation.resume(returning: stocks)
                })
                .store(in: &self.cancellables)
        }
    }
    
}
