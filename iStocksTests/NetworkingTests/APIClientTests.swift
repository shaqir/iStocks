//
//  APIClientTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed
//

import XCTest
@testable import iStocks

// MARK: - Mock API Client

final class MockAPIClient: APIClientProtocol, @unchecked Sendable {
    var resultData: Data?
    var resultError: Error?
    var requestCallCount = 0

    func request<E: APIEndpoint>(_ endpoint: E) async throws -> E.Response {
        requestCallCount += 1

        if let error = resultError {
            throw error
        }

        guard let data = resultData else {
            throw NetworkError.noData
        }

        return try JSONDecoder().decode(E.Response.self, from: data)
    }
}

// MARK: - Test Endpoint

private struct TestEndpoint: APIEndpoint {
    typealias Response = TestResponse
    var path: String { "/test" }
}

private struct TestResponse: Decodable, Sendable {
    let value: String
}

// MARK: - Tests

final class APIClientTests: XCTestCase {

    func test_request_decodesSuccessfully() async throws {
        let mockClient = MockAPIClient()
        let json = #"{"value": "hello"}"#
        mockClient.resultData = json.data(using: .utf8)

        let response: TestResponse = try await mockClient.request(TestEndpoint())

        XCTAssertEqual(response.value, "hello")
        XCTAssertEqual(mockClient.requestCallCount, 1)
    }

    func test_request_throwsOnError() async {
        let mockClient = MockAPIClient()
        mockClient.resultError = NetworkError.httpError(statusCode: 500, data: Data())

        do {
            let _: TestResponse = try await mockClient.request(TestEndpoint())
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }

    func test_request_throwsOnNoData() async {
        let mockClient = MockAPIClient()
        mockClient.resultData = nil

        do {
            let _: TestResponse = try await mockClient.request(TestEndpoint())
            XCTFail("Expected error to be thrown")
        } catch let error as NetworkError {
            if case .noData = error {
                // Expected
            } else {
                XCTFail("Expected noData error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
