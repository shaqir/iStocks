//
//  SharedAlertManagerTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-24.
//

import Foundation
import XCTest
@testable import iStocks
import Combine

final class SharedAlertManagerTests: XCTestCase {

    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        SharedAlertManager.shared.dismiss()//Clear any existing alerts before each test
    }

    override func tearDown() {
        SharedAlertManager.shared.dismiss()
        cancellables.removeAll()
        super.tearDown()
    }

    func test_showAlert_shouldPublishCorrectAlert() {
        // Given
        let expectedAlert = SharedAlertData(
            title: "Test Title",
            message: "Test Message",
            icon: "bell",
            action: nil
        )

        let expectation = XCTestExpectation(description: "Alert should be published")

        // When
        SharedAlertManager.shared
            .alertPublisher
            .dropFirst()
            .sink { alert in
                guard let alert = alert else { return }
                XCTAssertEqual(alert.title, expectedAlert.title)
                XCTAssertEqual(alert.message, expectedAlert.message)
                XCTAssertEqual(alert.icon, expectedAlert.icon)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Call show *after* sink is set up
        DispatchQueue.main.async {
            SharedAlertManager.shared.show(expectedAlert)
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    func test_clearAlert_shouldResetPublishedAlert() {
        // Given
        let initialAlert = SharedAlertData(
            title: "Alert",
            message: "To be cleared",
            icon: nil,
            action: nil
        )

        let expectation = XCTestExpectation(description: "Alert should be cleared")

        SharedAlertManager.shared.alert = initialAlert

        // When
        SharedAlertManager.shared
            .alertPublisher
            .dropFirst()
            .sink { alert in
                XCTAssertNil(alert)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        SharedAlertManager.shared.dismiss()

        // Then
        wait(for: [expectation], timeout: 1.0)
    }
}
