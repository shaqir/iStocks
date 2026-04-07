//
//  APIClient.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Generic networking client protocol for testability.
///
/// NOTE: Sendable conformance is required because APIClientProtocol instances
/// are passed across actor boundaries (e.g., into PortfolioActor or TaskGroup closures).
/// The protocol knows nothing about stocks or portfolios — it's fully generic.
/// MockAPIClient in tests conforms to this same protocol, enabling network-free testing.
nonisolated protocol APIClientProtocol: Sendable {
    func request<E: APIEndpoint>(_ endpoint: E) async throws -> E.Response
}

/// Production implementation using URLSession.
///
/// NOTE: @unchecked Sendable because URLSession.shared is thread-safe and the
/// JSONDecoder is only used within the async method scope (no shared mutable state).
nonisolated final class URLSessionAPIClient: APIClientProtocol, @unchecked Sendable {

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    /// Performs a type-safe network request.
    ///
    /// The generic constraint `E: APIEndpoint` means the return type is
    /// determined by the endpoint's associated type — not by the caller.
    /// This prevents decoding mismatches at compile time.
    func request<E: APIEndpoint>(_ endpoint: E) async throws -> E.Response {
        let request = try buildRequest(for: endpoint)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        // NOTE: Status code check before decoding — fail fast on server errors
        // rather than getting a confusing DecodingError from invalid JSON.
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        do {
            return try decoder.decode(E.Response.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }

    private func buildRequest<E: APIEndpoint>(for endpoint: E) throws -> URLRequest {
        var components = URLComponents(
            url: endpoint.baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: true
        )
        components?.queryItems = endpoint.queryItems

        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
}
