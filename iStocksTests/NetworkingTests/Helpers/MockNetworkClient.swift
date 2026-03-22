//
//  MockNetworkClient.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2026-03-21.
//

import Foundation
import Combine
@testable import iStocks

final class MockNetworkClient: NetworkClient {

    // MARK: - Tracking

    private(set) var requestCallCount = 0
    private(set) var requestedEndpoints: [Endpoint] = []

    // MARK: - Configurable Results

    var resultData: Data?
    var resultError: Error?

    // MARK: - Combine (Decodable)

    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, Error> {
        requestCallCount += 1
        requestedEndpoints.append(endpoint)

        if let error = resultError {
            return Fail(error: error).eraseToAnyPublisher()
        }

        guard let data = resultData else {
            return Fail(error: NetworkError.noData).eraseToAnyPublisher()
        }

        return Just(data)
            .tryMap { try JSONDecoder().decode(T.self, from: $0) }
            .eraseToAnyPublisher()
    }

    // MARK: - Combine (Raw Data)

    func request(_ endpoint: Endpoint) -> AnyPublisher<Data, Error> {
        requestCallCount += 1
        requestedEndpoints.append(endpoint)

        if let error = resultError {
            return Fail(error: error).eraseToAnyPublisher()
        }

        guard let data = resultData else {
            return Fail(error: NetworkError.noData).eraseToAnyPublisher()
        }

        return Just(data)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    // MARK: - Async/Await

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        requestCallCount += 1
        requestedEndpoints.append(endpoint)

        if let error = resultError {
            throw error
        }

        guard let data = resultData else {
            throw NetworkError.noData
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}
