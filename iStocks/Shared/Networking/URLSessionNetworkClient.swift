//
//  URLSessionNetworkClient.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-02.
//

import Foundation
import Combine

final class URLSessionNetworkClient: NetworkClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }
    
    // MARK: - Combine Raw Data
    func request(_ endpoint: Endpoint) -> AnyPublisher<Data, Error> {
        // Verbose logging removed
        guard let url = endpoint.url else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.httpBody
        if endpoint.httpBody != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return session.dataTaskPublisher(for: request)
            .tryMap { try self.validate(data: $0.data, response: $0.response) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Combine Decodable
    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, Error> {
        // Verbose logging removed
        guard let url = endpoint.url else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.httpBody
        if endpoint.httpBody != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return session.dataTaskPublisher(for: request)
            .tryMap { try self.validate(data: $0.data, response: $0.response) }
            .decode(type: T.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    // MARK: - Async/Await
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        // Verbose logging removed

        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.httpBody
        if endpoint.httpBody != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, response) = try await session.data(for: request)
        let validData = try validate(data: data, response: response)
        return try decoder.decode(T.self, from: validData)
    }

    // MARK: - Shared Validation
    private func validate(data: Data?, response: URLResponse?) throws -> Data {
        // Verbose validation logging removed
        guard let data = data else { throw NetworkError.noData }
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch http.statusCode {
        case 200..<300:
            break
        case 401:
            throw NetworkError.unauthorized
        case 429:
            throw NetworkError.rateLimited
        case 500...599:
            throw NetworkError.serverError(http.statusCode)
        default:
            throw NetworkError.invalidResponse
        }

        // Optional: decode application-level errors
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           jsonObject["status"] as? String == "error" {
            let apiError = try decoder.decode(TwelveDataAPIError.self, from: data)
            throw apiError
        }

        return data
    }

}
