//
//  NetworkClient.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Combine

protocol NetworkClient {
    // Combine
    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, Error>

    // Closure
    func request<T: Decodable>(_ endpoint: Endpoint, completion: @escaping (Result<T, Error>) -> Void)
        
    // Async/Await
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T

}
