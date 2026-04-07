//
//  StockResearchViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2026-03-21.
//

import Foundation
import Combine
import WebKit
import OSLog

/// ViewModel for the Stock Research web view feature.
/// Manages navigation state, bookmarks, browsing history, and JavaScript bridge callbacks.
/// Implicitly @MainActor via defaultIsolation(MainActor.self) — SE-0466
final class StockResearchViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var navigationState = WebNavigationState()
    @Published var urlString: String = ""
    @Published var bookmarks: [WebBookmark] = []
    @Published var history: [WebBookmark] = []
    @Published var detectedTicker: String?
    @Published var showTickerAlert: Bool = false

    // MARK: - Navigation Actions

    /// Signals the web view to go back
    let goBackSubject = PassthroughSubject<Void, Never>()

    /// Signals the web view to go forward
    let goForwardSubject = PassthroughSubject<Void, Never>()

    /// Signals the web view to reload
    let reloadSubject = PassthroughSubject<Void, Never>()

    /// Signals the web view to load a specific URL
    let loadURLSubject = PassthroughSubject<URL, Never>()

    // MARK: - Constants

    static let defaultURL = URL(string: "https://finance.yahoo.com")!

    // MARK: - Init

    init() {
        urlString = Self.defaultURL.absoluteString
    }

    // MARK: - Public API

    /// Attempts to load the URL currently entered in the URL bar
    func loadURL() {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var candidate = trimmed
        if !candidate.hasPrefix("http://") && !candidate.hasPrefix("https://") {
            candidate = "https://\(candidate)"
        }

        guard let url = URL(string: candidate) else {
            AppLogger.warning("Invalid URL entered: \(trimmed)", category: AppLogger.ui)
            return
        }

        urlString = url.absoluteString
        loadURLSubject.send(url)
    }

    /// Navigates backward in web history
    func goBack() {
        goBackSubject.send()
    }

    /// Navigates forward in web history
    func goForward() {
        goForwardSubject.send()
    }

    /// Reloads the current page
    func reload() {
        reloadSubject.send()
    }

    /// Loads the default financial news page
    func loadDefaultPage() {
        urlString = Self.defaultURL.absoluteString
        loadURLSubject.send(Self.defaultURL)
    }

    // MARK: - Bookmark Management

    /// Adds the current page to bookmarks if not already saved
    func addBookmark() {
        guard let url = navigationState.currentURL else { return }
        let title = navigationState.pageTitle ?? url.host ?? "Untitled"

        guard !bookmarks.contains(where: { $0.url == url }) else {
            AppLogger.debug("Bookmark already exists for \(url.absoluteString)", category: AppLogger.ui)
            return
        }

        let bookmark = WebBookmark(title: title, url: url)
        bookmarks.append(bookmark)
        AppLogger.info("Bookmark added: \(title)", category: AppLogger.ui)
    }

    /// Removes a bookmark at the given offsets
    func removeBookmarks(at offsets: IndexSet) {
        bookmarks.remove(atOffsets: offsets)
    }

    /// Whether the current page is already bookmarked
    var isCurrentPageBookmarked: Bool {
        guard let url = navigationState.currentURL else { return false }
        return bookmarks.contains { $0.url == url }
    }

    // MARK: - History

    /// Records a visited page in the browsing history (in-memory)
    func recordHistory(title: String?, url: URL) {
        let entry = WebBookmark(
            title: title ?? url.host ?? "Untitled",
            url: url
        )

        // Avoid consecutive duplicates
        if history.last?.url != url {
            history.append(entry)
        }
    }

    // MARK: - JavaScript Bridge Handling

    /// Processes messages received from the JavaScript bridge
    func handleJavaScriptMessage(_ message: [String: Any]) {
        guard let typeString = message["type"] as? String,
              let type = JavaScriptBridge.MessageType(rawValue: typeString) else {
            AppLogger.warning("Unknown JS message type", category: AppLogger.ui)
            return
        }

        switch type {
        case .tickerTapped:
            if let symbol = message["symbol"] as? String,
               symbol.range(of: #"^[A-Z]{1,5}$"#, options: .regularExpression) != nil {
                AppLogger.info("Ticker tapped: \(symbol)", category: AppLogger.ui)
                detectedTicker = symbol
                showTickerAlert = true
            } else {
                AppLogger.warning("Invalid ticker symbol received from JS bridge", category: AppLogger.ui)
            }

        case .pageLoaded:
            if let title = message["title"] as? String {
                AppLogger.debug("Page loaded: \(title)", category: AppLogger.ui)
            }

        case .error:
            let errorMessage = message["message"] as? String ?? "Unknown JS error"
            AppLogger.error("JS bridge error: \(errorMessage)", category: AppLogger.ui)
        }
    }

    // MARK: - Navigation State Updates

    /// Called by the Coordinator to update navigation state from WKWebView observations
    func updateNavigationState(
        canGoBack: Bool,
        canGoForward: Bool,
        isLoading: Bool,
        estimatedProgress: Double,
        currentURL: URL?,
        pageTitle: String?
    ) {
        navigationState.canGoBack = canGoBack
        navigationState.canGoForward = canGoForward
        navigationState.isLoading = isLoading
        navigationState.estimatedProgress = estimatedProgress
        navigationState.currentURL = currentURL
        navigationState.pageTitle = pageTitle

        if let url = currentURL {
            urlString = url.absoluteString
        }
    }
}
