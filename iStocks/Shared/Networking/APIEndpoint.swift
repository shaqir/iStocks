//
//  APIEndpoint.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Protocol-oriented endpoint definition with associated types.
///
/// NOTE: Unlike the existing `Endpoint` struct which uses method-level generics,
/// this protocol uses an associated type so each endpoint defines its own
/// Response type at the type level — the compiler enforces correct decoding
/// at every call site. This is the "protocol with associated types" pattern.
///
/// Example:
/// ```swift
/// struct QuoteEndpoint: APIEndpoint {
///     typealias Response = StockQuote  // Compiler knows the return type
///     let symbol: String
///     var path: String { "/quote" }
///     var queryItems: [URLQueryItem]? { [URLQueryItem(name: "symbol", value: symbol)] }
/// }
/// ```
protocol APIEndpoint {
    associatedtype Response: Decodable & Sendable

    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem]? { get }
    var baseURL: URL { get }
}

// MARK: - Defaults via Protocol Extension

/// NOTE: Extension defaults reduce boilerplate — most endpoints are GET requests
/// to the same base URL. Only override what differs.
extension APIEndpoint {
    var baseURL: URL { URL(string: API.baseURL)! }
    var method: HTTPMethod { .get }
    var queryItems: [URLQueryItem]? { nil }
}
