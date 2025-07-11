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
        guard let url = endpoint.url else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        return session.dataTaskPublisher(for: request)
            .tryMap { try self.validate(data: $0.data, response: $0.response) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Combine Decodable
    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, Error> {
        guard let url = endpoint.url else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        return session.dataTaskPublisher(for: request)
            .tryMap { try self.validate(data: $0.data, response: $0.response) }
            .decode(type: T.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Closure
    func request<T: Decodable>(_ endpoint: Endpoint, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = endpoint.url else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    return completion(.failure(error))
                }

                do {
                    let validData = try self.validate(data: data, response: response)
                    let decoded = try self.decoder.decode(T.self, from: validData)
                    completion(.success(decoded))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    // MARK: - Async/Await
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        guard let url = endpoint.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        let (data, response) = try await session.data(for: request)
        let validData = try validate(data: data, response: response)
        return try decoder.decode(T.self, from: validData)
    }

    // MARK: - Shared Validation
    private func validate(data: Data?, response: URLResponse?) throws -> Data {
        guard let data = data else { throw NetworkError.noData }
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw NetworkError.invalidResponse
        }

        #if DEBUG
        self.debugPrintJSON(data: data)
        #endif

        // Optional: decode application-level errors
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           jsonObject["status"] as? String == "error" {
            let apiError = try decoder.decode(TwelveDataAPIError.self, from: data)
            throw apiError
        }

        return data
    }

    private func debugPrintJSON(data: Data) {
        if let json = try? JSONSerialization.jsonObject(with: data),
           let prettyData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
           let jsonString = String(data: prettyData, encoding: .utf8) {
            print("Raw JSON Response:\n\(jsonString)")
        }
    }
}
