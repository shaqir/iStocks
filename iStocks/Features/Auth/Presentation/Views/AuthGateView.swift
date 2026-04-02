//
//  AuthGateView.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import SwiftUI

/// Generic authentication gate that wraps app content behind biometric auth.
///
/// NOTE: Generic `Content` parameter means this view can wrap ANY SwiftUI view
/// hierarchy — from a single screen to the entire app's TabBar. The caller
/// decides what's protected, not the gate itself.
///
/// Usage:
/// ```swift
/// AuthGateView(viewModel: authVM) {
///     TabBarContainer()
/// }
/// ```
struct AuthGateView<Content: View>: View {

    @StateObject private var viewModel: AuthViewModel
    let content: () -> Content

    init(viewModel: AuthViewModel, @ViewBuilder content: @escaping () -> Content) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.content = content
    }

    var body: some View {
        Group {
            if viewModel.isAuthenticated {
                content()
            } else {
                authPrompt
            }
        }
        .onAppear {
            if !viewModel.isAuthenticated {
                viewModel.authenticate()
            }
        }
        .accessibilityIdentifier(AccessibilityID.Auth.authGate)
    }

    // MARK: - Auth Prompt

    private var authPrompt: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: biometryIcon)
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("iStocks")
                .font(.largeTitle.bold())

            Text("Authenticate to access your portfolio")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let error = viewModel.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                viewModel.authenticate()
            } label: {
                HStack {
                    if viewModel.isAuthenticating {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: biometryIcon)
                    }
                    Text(biometryLabel)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.isAuthenticating)
            .padding(.horizontal, 40)
            .accessibilityIdentifier(AccessibilityID.Auth.biometricButton)

            Spacer()
        }
    }

    // MARK: - Helpers

    /// NOTE: Display the correct icon based on device biometry type.
    /// Face ID shows a face scan icon, Touch ID shows a fingerprint.
    private var biometryIcon: String {
        switch viewModel.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .none: return "lock.shield"
        }
    }

    private var biometryLabel: String {
        switch viewModel.biometryType {
        case .faceID: return "Authenticate with Face ID"
        case .touchID: return "Authenticate with Touch ID"
        case .opticID: return "Authenticate with Optic ID"
        case .none: return "Authenticate"
        }
    }
}
