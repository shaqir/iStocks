//
//  StockResearchView.swift
//  iStocks
//
//  Created by Sakir Saiyed on 2026-03-21.
//

import SwiftUI

/// Main view for the Stock Research feature.
/// Embeds a WKWebView with navigation toolbar, URL bar, and ticker detection alerts.
struct StockResearchView: View {

    @StateObject private var viewModel = StockResearchViewModel()
    @State private var showBookmarks = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                StockWebView(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.horizontal)

                WebViewToolbar(viewModel: viewModel)
            }
            .navigationTitle(viewModel.navigationState.pageTitle ?? "Research")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.loadDefaultPage()
                    } label: {
                        Image(systemName: "house")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showBookmarks = true
                    } label: {
                        Image(systemName: "book")
                    }
                }
            }
            .sheet(isPresented: $showBookmarks) {
                bookmarksList
            }
            .alert("Stock Detected", isPresented: $viewModel.showTickerAlert) {
                Button("View in Watchlist") {
                    // Future: navigate to watchlist filtered by ticker
                }
                Button("Dismiss", role: .cancel) {}
            } message: {
                if let ticker = viewModel.detectedTicker {
                    Text("Ticker symbol $\(ticker) detected. Would you like to view it in your watchlist?")
                }
            }
        }
    }

    // MARK: - Bookmarks Sheet

    private var bookmarksList: some View {
        NavigationStack {
            Group {
                if viewModel.bookmarks.isEmpty {
                    ContentUnavailableView(
                        "No Bookmarks",
                        systemImage: "bookmark.slash",
                        description: Text("Pages you bookmark will appear here.")
                    )
                } else {
                    List {
                        ForEach(viewModel.bookmarks) { bookmark in
                            Button {
                                viewModel.urlString = bookmark.url.absoluteString
                                viewModel.loadURL()
                                showBookmarks = false
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(bookmark.title)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    Text(bookmark.url.absoluteString)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .onDelete(perform: viewModel.removeBookmarks)
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showBookmarks = false
                    }
                }
            }
        }
    }
}

#Preview {
    StockResearchView()
}
