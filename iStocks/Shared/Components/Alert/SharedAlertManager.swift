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

    let watchlistDidSave = PassthroughSubject<Watchlist, Never>()

    //@Published var alert: SharedAlertData? = nil

    func show(_ alert: SharedAlertData, autoDismissAfter seconds: Double? = 2.5) {
        GlobalAlertPresenter.present(alert)
        print("SharedAlertManager.show called")
        if let seconds = seconds {
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                GlobalAlertPresenter.dismiss()
            }
        }

        triggerHaptic()
    }

    func dismiss() {
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
