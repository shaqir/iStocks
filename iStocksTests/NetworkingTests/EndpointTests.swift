//
//  EndpointTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2026-03-21.
//

import XCTest
@testable import iStocks

final class EndpointTests: XCTestCase {

    // MARK: - URL Construction

    func test_url_withPathAndQueryItems_shouldConstructValidURL() {
        let endpoint = Endpoint(
            path: "/quote",
            method: .get,
            queryItems: [
                URLQueryItem(name: "symbol", value: "AAPL"),
                URLQueryItem(name: "apikey", value: "test123")
            ]
        )

        let url = endpoint.url
        XCTAssertNotNil(url)

        let urlString = url!.absoluteString
        XCTAssertTrue(urlString.contains(API.baseURL))
        XCTAssertTrue(urlString.contains("/quote"))
        XCTAssertTrue(urlString.contains("symbol=AAPL"))
        XCTAssertTrue(urlString.contains("apikey=test123"))
    }

    func test_url_withPathOnly_shouldConstructURLWithoutQueryString() {
        let endpoint = Endpoint(
            path: "/price",
            method: .get,
            queryItems: nil
        )

        let url = endpoint.url
        XCTAssertNotNil(url)

        let urlString = url!.absoluteString
        XCTAssertTrue(urlString.hasSuffix("/price"))
    }

    func test_url_withMultipleQueryItems_shouldIncludeAll() {
        let endpoint = Endpoint(
            path: "/quote",
            method: .get,
            queryItems: [
                URLQueryItem(name: "symbol", value: "AAPL,MSFT,GOOGL"),
                URLQueryItem(name: "apikey", value: "key123"),
                URLQueryItem(name: "interval", value: "1day")
            ]
        )

        let url = endpoint.url
        XCTAssertNotNil(url)

        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        XCTAssertEqual(components?.queryItems?.count, 3)
    }

    // MARK: - HTTP Method

    func test_method_whenGet_shouldBeGET() {
        let endpoint = Endpoint(path: "/test", method: .get, queryItems: nil)
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.method.rawValue, "GET")
    }

    func test_method_whenPost_shouldBePOST() {
        let endpoint = Endpoint(path: "/test", method: .post, queryItems: nil)
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertEqual(endpoint.method.rawValue, "POST")
    }

    // MARK: - Path

    func test_path_shouldBeStoredCorrectly() {
        let endpoint = Endpoint(path: "/quote", method: .get, queryItems: nil)
        XCTAssertEqual(endpoint.path, "/quote")
    }

    // MARK: - Empty Query Items

    func test_url_withEmptyQueryItems_shouldStillConstructURL() {
        let endpoint = Endpoint(path: "/test", method: .get, queryItems: [])
        let url = endpoint.url
        XCTAssertNotNil(url)
    }
}
