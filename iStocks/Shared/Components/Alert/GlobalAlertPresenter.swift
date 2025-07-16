//
//  GlobalAlertPresenter.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2025-07-06.
//
import SwiftUI
import UIKit
 
final class GlobalAlertPresenter {
    private static var window: UIWindow?

    static func present(_ data: SharedAlertData) {

        Logger.log("Presenting alert with title:\(data.title)", category: "GlobalAlert")

        guard let windowScene = UIApplication.shared
            .connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            Logger.log("No active window scene found.", category: "GlobalAlert")
            return
        }

        let alertView = SharedAlertView(data: data) {
            dismiss()
        }

        let hosting = UIHostingController(rootView: alertView)
        hosting.view.backgroundColor = .clear

        let newWindow = UIWindow(windowScene: windowScene)
        newWindow.rootViewController = hosting
        newWindow.windowLevel = .alert + 1
        newWindow.makeKeyAndVisible()

        self.window = newWindow
    }

    static func dismiss() {
        window?.isHidden = true
        window = nil
    }
}
