//
//  WebViewToolbar.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2026-03-21.
//

import SwiftUI

/// Bottom toolbar providing web navigation controls, progress indicator, and URL display
struct WebViewToolbar: View {

    @ObservedObject var viewModel: StockResearchViewModel

    var body: some View {
        VStack(spacing: 0) {
            progressBar
            urlBar
            navigationControls
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                if viewModel.navigationState.isLoading {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(
                            width: geometry.size.width * viewModel.navigationState.estimatedProgress,
                            height: 2
                        )
                        .animation(.linear(duration: 0.2), value: viewModel.navigationState.estimatedProgress)
                }
            }
        }
        .frame(height: 2)
    }

    // MARK: - URL Bar

    private var urlBar: some View {
        HStack(spacing: 8) {
            if viewModel.navigationState.isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Image(systemName: lockIconName)
                    .font(.caption)
                    .foregroundColor(isSecure ? .green : .secondary)
            }

            TextField("Enter URL", text: $viewModel.urlString)
                .textFieldStyle(.plain)
                .font(.system(.footnote, design: .monospaced))
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .keyboardType(.URL)
                .textContentType(.URL)
                .submitLabel(.go)
                .onSubmit {
                    viewModel.loadURL()
                }

            if !viewModel.urlString.isEmpty {
                Button {
                    viewModel.urlString = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    // MARK: - Navigation Controls

    private var navigationControls: some View {
        HStack(spacing: 0) {
            toolbarButton(
                systemName: "chevron.left",
                isEnabled: viewModel.navigationState.canGoBack,
                action: viewModel.goBack
            )

            toolbarButton(
                systemName: "chevron.right",
                isEnabled: viewModel.navigationState.canGoForward,
                action: viewModel.goForward
            )

            Spacer()

            toolbarButton(
                systemName: viewModel.isCurrentPageBookmarked ? "bookmark.fill" : "bookmark",
                isEnabled: viewModel.navigationState.currentURL != nil,
                action: viewModel.addBookmark
            )

            toolbarButton(
                systemName: "arrow.clockwise",
                isEnabled: true,
                action: viewModel.reload
            )

            shareButton
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    private func toolbarButton(systemName: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .regular))
                .frame(width: 44, height: 44)
                .foregroundColor(isEnabled ? .blue : .secondary.opacity(0.4))
        }
        .disabled(!isEnabled)
    }

    private var shareButton: some View {
        Button {
            guard let url = viewModel.navigationState.currentURL else { return }
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 18, weight: .regular))
                .frame(width: 44, height: 44)
                .foregroundColor(viewModel.navigationState.currentURL != nil ? .blue : .secondary.opacity(0.4))
        }
        .disabled(viewModel.navigationState.currentURL == nil)
    }

    // MARK: - Helpers

    private var isSecure: Bool {
        viewModel.navigationState.currentURL?.scheme == "https"
    }

    private var lockIconName: String {
        isSecure ? "lock.fill" : "lock.open.fill"
    }
}
