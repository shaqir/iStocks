//
//  GraphQLClient.swift
//  iStocks
//
//  Created by Sakir Saiyed.
//

import Foundation
import Combine

// MARK: - Protocol

protocol GraphQLClientProtocol {
    /// Execute a GraphQL query and decode the response using Combine
    func execute<T: Decodable>(query: GraphQLQuery) -> AnyPublisher<T, Error>

    /// Execute a GraphQL query and decode the response using async/await
    func execute<T: Decodable>(query: GraphQLQuery) async throws -> T
}

// MARK: - Implementation

/// Lightweight GraphQL client built on URLSession — no third-party dependencies
final class GraphQLClient: GraphQLClientProtocol {

    // MARK: - Dependencies

    private let session: URLSession
    private let decoder: JSONDecoder
    private let baseURL: URL

    // MARK: - Init

    init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    // MARK: - Combine

    func execute<T: Decodable>(query: GraphQLQuery) -> AnyPublisher<T, Error> {
        do {
            let request = try buildRequest(for: query)
            return session.dataTaskPublisher(for: request)
                .tryMap { try self.validateHTTPResponse(data: $0.data, response: $0.response) }
                .tryMap { data -> T in
                    let graphQLResponse = try self.decoder.decode(GraphQLResponse<T>.self, from: data)
                    return try self.extractData(from: graphQLResponse)
                }
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
    }

    // MARK: - Async/Await

    func execute<T: Decodable>(query: GraphQLQuery) async throws -> T {
        let request = try buildRequest(for: query)
        let (data, response) = try await session.data(for: request)
        let validData = try validateHTTPResponse(data: data, response: response)
        let graphQLResponse = try decoder.decode(GraphQLResponse<T>.self, from: validData)
        return try extractData(from: graphQLResponse)
    }

    // MARK: - Private Helpers

    private func buildRequest(for query: GraphQLQuery) throws -> URLRequest {
        guard let body = try? query.toJSONData() else {
            throw GraphQLError.encodingFailed
        }

        var request = URLRequest(url: baseURL)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }

    private func validateHTTPResponse(data: Data, response: URLResponse) throws -> Data {
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch http.statusCode {
        case 200..<300:
            return data
        case 401:
            throw NetworkError.unauthorized
        case 429:
            throw NetworkError.rateLimited
        case 500...599:
            throw NetworkError.serverError(http.statusCode)
        default:
            throw NetworkError.invalidResponse
        }
    }

    private func extractData<T: Decodable>(from response: GraphQLResponse<T>) throws -> T {
        if let errors = response.errors, !errors.isEmpty {
            throw GraphQLError.graphQLErrors(errors)
        }
        guard let data = response.data else {
            throw GraphQLError.invalidResponse
        }
        return data
    }
}
