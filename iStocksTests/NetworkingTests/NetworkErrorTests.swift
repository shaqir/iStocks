//
//  NetworkErrorTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2026-03-21.
//

import XCTest
@testable import iStocks

final class NetworkErrorTests: XCTestCase {

    // MARK: - errorDescription

    func test_errorDescription_invalidURL_shouldReturnExpectedMessage() {
        XCTAssertEqual(NetworkError.invalidURL.errorDescription, "Invalid URL")
    }

    func test_errorDescription_invalidResponse_shouldReturnExpectedMessage() {
        XCTAssertEqual(NetworkError.invalidResponse.errorDescription, "Invalid server response")
    }

    func test_errorDescription_noData_shouldReturnExpectedMessage() {
        XCTAssertEqual(NetworkError.noData.errorDescription, "No data received")
    }

    func test_errorDescription_unauthorized_shouldReturnExpectedMessage() {
        XCTAssertEqual(NetworkError.unauthorized.errorDescription, "API key is invalid or expired")
    }

    func test_errorDescription_rateLimited_shouldReturnExpectedMessage() {
        let description = NetworkError.rateLimited.errorDescription
        XCTAssertNotNil(description)
        XCTAssertTrue(description!.contains("Rate limit"))
    }

    func test_errorDescription_serverError_shouldIncludeStatusCode() {
        let error = NetworkError.serverError(503)
        XCTAssertEqual(error.errorDescription, "Server error (503)")
    }

    func test_errorDescription_timeout_shouldReturnExpectedMessage() {
        XCTAssertEqual(NetworkError.timeout.errorDescription, "Request timed out")
    }

    func test_errorDescription_noInternetConnection_shouldReturnExpectedMessage() {
        XCTAssertEqual(NetworkError.noInternetConnection.errorDescription, "No internet connection available")
    }

    func test_errorDescription_cancelled_shouldReturnExpectedMessage() {
        XCTAssertEqual(NetworkError.cancelled.errorDescription, "Request was cancelled")
    }

    func test_errorDescription_decodingFailed_shouldIncludeUnderlyingError() {
        let underlyingError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "bad format"])
        let error = NetworkError.decodingFailed(underlyingError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("bad format"))
    }

    func test_errorDescription_unknown_shouldIncludeUnderlyingError() {
        let underlyingError = NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "something broke"])
        let error = NetworkError.unknown(underlyingError)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("something broke"))
    }

    // MARK: - isRetryable

    func test_isRetryable_timeout_shouldBeTrue() {
        XCTAssertTrue(NetworkError.timeout.isRetryable)
    }

    func test_isRetryable_serverError_shouldBeTrue() {
        XCTAssertTrue(NetworkError.serverError(500).isRetryable)
    }

    func test_isRetryable_rateLimited_shouldBeTrue() {
        XCTAssertTrue(NetworkError.rateLimited.isRetryable)
    }

    func test_isRetryable_noInternetConnection_shouldBeTrue() {
        XCTAssertTrue(NetworkError.noInternetConnection.isRetryable)
    }

    func test_isRetryable_invalidURL_shouldBeFalse() {
        XCTAssertFalse(NetworkError.invalidURL.isRetryable)
    }

    func test_isRetryable_invalidResponse_shouldBeFalse() {
        XCTAssertFalse(NetworkError.invalidResponse.isRetryable)
    }

    func test_isRetryable_noData_shouldBeFalse() {
        XCTAssertFalse(NetworkError.noData.isRetryable)
    }

    func test_isRetryable_unauthorized_shouldBeFalse() {
        XCTAssertFalse(NetworkError.unauthorized.isRetryable)
    }

    func test_isRetryable_cancelled_shouldBeFalse() {
        XCTAssertFalse(NetworkError.cancelled.isRetryable)
    }

    func test_isRetryable_decodingFailed_shouldBeFalse() {
        let error = NetworkError.decodingFailed(NSError(domain: "", code: 0))
        XCTAssertFalse(error.isRetryable)
    }

    func test_isRetryable_unknown_shouldBeFalse() {
        let error = NetworkError.unknown(NSError(domain: "", code: 0))
        XCTAssertFalse(error.isRetryable)
    }

    // MARK: - failureReason

    func test_failureReason_shouldNotBeNilForAllCases() {
        let cases: [NetworkError] = [
            .invalidURL,
            .invalidResponse,
            .noData,
            .unauthorized,
            .rateLimited,
            .serverError(500),
            .timeout,
            .noInternetConnection,
            .cancelled,
            .decodingFailed(NSError(domain: "", code: 0)),
            .unknown(NSError(domain: "", code: 0))
        ]

        for error in cases {
            XCTAssertNotNil(error.failureReason, "failureReason should not be nil for \(error)")
        }
    }

    func test_failureReason_serverError_shouldIncludeCode() {
        let error = NetworkError.serverError(502)
        XCTAssertTrue(error.failureReason!.contains("502"))
    }

    // MARK: - recoverySuggestion

    func test_recoverySuggestion_cancelled_shouldBeNil() {
        XCTAssertNil(NetworkError.cancelled.recoverySuggestion)
    }

    func test_recoverySuggestion_shouldNotBeNilForMostCases() {
        let cases: [NetworkError] = [
            .invalidURL,
            .invalidResponse,
            .noData,
            .unauthorized,
            .rateLimited,
            .serverError(500),
            .timeout,
            .noInternetConnection,
            .decodingFailed(NSError(domain: "", code: 0)),
            .unknown(NSError(domain: "", code: 0))
        ]

        for error in cases {
            XCTAssertNotNil(error.recoverySuggestion, "recoverySuggestion should not be nil for \(error)")
        }
    }

    func test_recoverySuggestion_unauthorized_shouldSuggestAPIKey() {
        let suggestion = NetworkError.unauthorized.recoverySuggestion
        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.contains("API key"))
    }

    func test_recoverySuggestion_noInternetConnection_shouldSuggestConnect() {
        let suggestion = NetworkError.noInternetConnection.recoverySuggestion
        XCTAssertNotNil(suggestion)
        XCTAssertTrue(suggestion!.lowercased().contains("internet"))
    }
}
