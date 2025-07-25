//
//  File.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-05.
//
import SwiftUI
import Combine

final class SharedAlertManager: ObservableObject {
    static let shared = SharedAlertManager()

    // MARK: - Combine Alert Publisher
    @Published var alert: SharedAlertData? = nil
    
    var alertPublisher: AnyPublisher<SharedAlertData?, Never> {
        $alert.eraseToAnyPublisher()
    }

    func show(_ alert: SharedAlertData, autoDismissAfter seconds: Double? = 2.5) {
        self.alert = alert // For tests or Combine-driven UI
        GlobalAlertPresenter.present(alert)
        Logger.log("SharedAlertManager.show called", category: "SharedAlert")

        if let seconds = seconds {
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                self.alert = nil  //Auto-dismiss should clear published alert too
                self.dismiss()
            }
        }

        triggerHaptic()
    }

    func dismiss() {
        self.alert = nil// Clear published value
        GlobalAlertPresenter.dismiss()
    }

    private func triggerHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}

struct SharedAlertData: Identifiable, Equatable {
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
