//
//  WebNavigationState.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2026-03-21.
//

import Foundation

/// Tracks the current navigation state of the research web view
struct WebNavigationState: Equatable {
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var isLoading: Bool = false
    var estimatedProgress: Double = 0.0
    var currentURL: URL?
    var pageTitle: String?
}
