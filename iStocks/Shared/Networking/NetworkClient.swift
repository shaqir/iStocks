//
//  NetworkClient.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Combine
import SwiftUI

protocol NetworkClient {
    // Combine (Decodable)
    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, Error>

    // Combine (Raw Data)
    func request(_ endpoint: Endpoint) -> AnyPublisher<Data, Error>

    // Closure
    //func request<T: Decodable>(_ endpoint: Endpoint, completion: @escaping (Result<T, Error>) -> Void)

    // Async/Await
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}
