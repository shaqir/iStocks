//
//  StockWebView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2026-03-21.
//

import SwiftUI
import WebKit
import Combine
import OSLog

/// UIViewRepresentable wrapper for WKWebView with full navigation delegate,
/// JavaScript bridge, custom configuration, and cookie management support.
struct StockWebView: UIViewRepresentable {

    @ObservedObject var viewModel: StockResearchViewModel

    // MARK: - UIViewRepresentable

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: context.coordinator.makeConfiguration())
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true

        context.coordinator.webView = webView
        context.coordinator.observeWebView(webView)
        context.coordinator.bindViewModelActions()

        // Load default page
        let request = URLRequest(url: StockResearchViewModel.defaultURL)
        webView.load(request)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Intentionally empty — navigation is driven by Combine subjects
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {

        private let viewModel: StockResearchViewModel
        weak var webView: WKWebView?
        private var cancellables = Set<AnyCancellable>()
        private var progressObservation: NSKeyValueObservation?
        private var titleObservation: NSKeyValueObservation?
        private var urlObservation: NSKeyValueObservation?
        private var loadingObservation: NSKeyValueObservation?
        private var canGoBackObservation: NSKeyValueObservation?
        private var canGoForwardObservation: NSKeyValueObservation?

        init(viewModel: StockResearchViewModel) {
            self.viewModel = viewModel
            super.init()
        }

        deinit {
            // Remove script message handler to break the retain cycle
            webView?.configuration.userContentController.removeScriptMessageHandler(
                forName: JavaScriptBridge.handlerName
            )
        }

        // MARK: - Configuration

        func makeConfiguration() -> WKWebViewConfiguration {
            let config = WKWebViewConfiguration()
            config.allowsInlineMediaPlayback = true
            config.mediaTypesRequiringUserActionForPlayback = []

            let preferences = WKPreferences()
            preferences.javaScriptCanOpenWindowsAutomatically = false
            config.preferences = preferences

            let contentController = WKUserContentController()
            contentController.add(self, name: JavaScriptBridge.handlerName)
            contentController.addUserScript(JavaScriptBridge.extractTickerScript)
            contentController.addUserScript(JavaScriptBridge.customStyleScript)
            config.userContentController = contentController

            // Configure cookie storage for session persistence
            config.websiteDataStore = WKWebsiteDataStore.default()

            return config
        }

        // MARK: - KVO Observations

        func observeWebView(_ webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress, options: .new) { [weak self] wv, _ in
                self?.syncNavigationState(wv)
            }

            titleObservation = webView.observe(\.title, options: .new) { [weak self] wv, _ in
                self?.syncNavigationState(wv)
            }

            urlObservation = webView.observe(\.url, options: .new) { [weak self] wv, _ in
                self?.syncNavigationState(wv)
            }

            loadingObservation = webView.observe(\.isLoading, options: .new) { [weak self] wv, _ in
                self?.syncNavigationState(wv)
            }

            canGoBackObservation = webView.observe(\.canGoBack, options: .new) { [weak self] wv, _ in
                self?.syncNavigationState(wv)
            }

            canGoForwardObservation = webView.observe(\.canGoForward, options: .new) { [weak self] wv, _ in
                self?.syncNavigationState(wv)
            }
        }

        private func syncNavigationState(_ webView: WKWebView) {
            Task { @MainActor in
                viewModel.updateNavigationState(
                    canGoBack: webView.canGoBack,
                    canGoForward: webView.canGoForward,
                    isLoading: webView.isLoading,
                    estimatedProgress: webView.estimatedProgress,
                    currentURL: webView.url,
                    pageTitle: webView.title
                )
            }
        }

        // MARK: - ViewModel Bindings

        func bindViewModelActions() {
            viewModel.goBackSubject
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.webView?.goBack() }
                .store(in: &cancellables)

            viewModel.goForwardSubject
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.webView?.goForward() }
                .store(in: &cancellables)

            viewModel.reloadSubject
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.webView?.reload() }
                .store(in: &cancellables)

            viewModel.loadURLSubject
                .receive(on: DispatchQueue.main)
                .sink { [weak self] url in
                    self?.webView?.load(URLRequest(url: url))
                }
                .store(in: &cancellables)
        }

        // MARK: - WKNavigationDelegate

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            // Block non-HTTP(S) schemes (e.g. tel:, mailto:) — open them externally
            if let scheme = url.scheme, !["http", "https", "about"].contains(scheme) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            AppLogger.debug("Navigating to: \(url.absoluteString)", category: AppLogger.ui)
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            AppLogger.debug("Started loading: \(webView.url?.absoluteString ?? "unknown")", category: AppLogger.ui)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            AppLogger.debug("Finished loading: \(webView.url?.absoluteString ?? "unknown")", category: AppLogger.ui)

            // Record in history
            if let url = webView.url {
                Task { @MainActor in
                    viewModel.recordHistory(title: webView.title, url: url)
                }
            }

            // Re-inject ticker script after page load to catch dynamically loaded content
            webView.evaluateJavaScript(JavaScriptBridge.extractTickerScript.source) { _, error in
                if let error = error {
                    AppLogger.debug("Ticker re-injection note: \(error.localizedDescription)", category: AppLogger.ui)
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            let nsError = error as NSError
            // Ignore cancellation errors (triggered by rapid navigation)
            guard nsError.code != NSURLErrorCancelled else { return }
            AppLogger.error("Navigation failed: \(error.localizedDescription)", category: AppLogger.ui)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let nsError = error as NSError
            guard nsError.code != NSURLErrorCancelled else { return }
            AppLogger.error("Provisional navigation failed: \(error.localizedDescription)", category: AppLogger.ui)
        }

        // MARK: - WKUIDelegate

        /// Handles target="_blank" links by loading them in the same web view
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil || !(navigationAction.targetFrame?.isMainFrame ?? true) {
                webView.load(navigationAction.request)
            }
            return nil
        }

        // MARK: - WKScriptMessageHandler

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == JavaScriptBridge.handlerName else { return }

            guard let body = message.body as? [String: Any] else {
                AppLogger.warning("JS message body is not a dictionary", category: AppLogger.ui)
                return
            }

            Task { @MainActor in
                viewModel.handleJavaScriptMessage(body)
            }
        }
    }
}
