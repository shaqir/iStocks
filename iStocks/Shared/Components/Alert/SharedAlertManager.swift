//
//  File.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-05.
//
import SwiftUI
import Combine

/// Centralized alert coordination across the app.
///
/// NOTE: Dual access pattern by design:
/// - `.shared` singleton for non-View contexts (Data layer error handlers, ViewModels)
///   where @EnvironmentObject is not available.
/// - `@EnvironmentObject` injection in SwiftUI Views (injected in iStocksApp.swift)
///   for idiomatic SwiftUI access.
///
/// Both point to the same instance. The singleton exists because Data layer code
/// (e.g., StockRemoteDataSource error mapping) needs to show alerts but has no
/// access to the SwiftUI environment.
final class SharedAlertManager: ObservableObject {
    static let shared = SharedAlertManager()

    // MARK: - Combine Alert Publisher
    @Published var alert: SharedAlertData? = nil

    var alertPublisher: AnyPublisher<SharedAlertData?, Never> {
        $alert.eraseToAnyPublisher()
    }

    func show(_ alert: SharedAlertData, autoDismissAfter seconds: Double? = 2.5) {
        self.alert = alert

        if let seconds = seconds {
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                self.dismiss()
            }
        }

        triggerHaptic()
    }

    func dismiss() {
        self.alert = nil
    }

    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}

/// NOTE (Swift 6.2): nonisolated so alert data can be constructed from any isolation context
/// (e.g., Data layer error handlers that may run outside MainActor).
nonisolated struct SharedAlertData: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let icon: String?
    let action: (() -> Void)?

    static func == (lhs: SharedAlertData, rhs: SharedAlertData) -> Bool {
        // Compare only relevant parts (not closures)
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.message == rhs.message &&
               lhs.icon == rhs.icon
    }
}
