//
//  TestHelpers.swift
//  iStocksIntegrationTests
//
//  Created by Sakir Saiyed on 2025-07-23.
//

import Foundation
@testable import iStocks
internal import Combine

final class FailingNetworkClient: NetworkClient {

    // For Combine-based requests
    func request<T>(_ endpoint: Endpoint) -> AnyPublisher<T, Error> where T: Decodable {
        return Fail(error: NetworkError.invalidResponse)
            .eraseToAnyPublisher()
    }

    // For async/await-based requests
    func request<T>(_ endpoint: Endpoint) async throws -> T where T: Decodable {
        throw NetworkError.invalidResponse
    }
}
