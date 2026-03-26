//
//  DashboardView.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import SwiftUI

/// Portfolio dashboard showing holdings summary, individual positions, and news.
struct DashboardView: View {

    @StateObject private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.dashboard == nil {
                    loadingView
                } else if let error = viewModel.error, viewModel.dashboard == nil {
                    errorView(error)
                } else if let dashboard = viewModel.dashboard {
                    dashboardContent(dashboard)
                } else {
                    emptyView
                }
            }
            .navigationTitle("Portfolio")
            .refreshable {
                await viewModel.refresh()
            }
        }
        .task {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    // MARK: - Subviews

    private func dashboardContent(_ dashboard: Dashboard) -> some View {
        List {
            // Portfolio Summary
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Value")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(dashboard.totalValue, format: .currency(code: "USD"))
                        .font(.system(size: 32, weight: .bold))
                    HStack {
                        Image(systemName: dashboard.totalReturn >= 0 ? "arrow.up.right" : "arrow.down.right")
                        Text(dashboard.totalReturn, format: .currency(code: "USD"))
                        Text("(\(dashboard.totalReturnPercentage, specifier: "%.1f")%)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(dashboard.totalReturn >= 0 ? .green : .red)
                }
                .padding(.vertical, 4)
                .accessibilityIdentifier(AccessibilityID.Dashboard.portfolioSummary)
            }

            // Holdings
            Section("Holdings") {
                ForEach(dashboard.holdings) { holding in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(holding.symbol)
                                .font(.headline)
                            Text(holding.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(holding.marketValue, format: .currency(code: "USD"))
                                .font(.subheadline)
                            Text("\(holding.totalReturnPercentage, specifier: "%+.1f")%")
                                .font(.caption)
                                .foregroundStyle(holding.isPositive ? .green : .red)
                        }
                    }
                    .accessibilityIdentifier(AccessibilityID.Dashboard.holdingRow)
                }
            }

            // News
            if !dashboard.news.isEmpty {
                Section("News") {
                    ForEach(dashboard.news) { article in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(article.headline)
                                .font(.subheadline)
                            Text(article.source)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .accessibilityIdentifier(AccessibilityID.Dashboard.newsSection)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading portfolio...")
                .foregroundStyle(.secondary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .multilineTextAlignment(.center)
            Button("Retry") {
                viewModel.onAppear()
            }
            .accessibilityIdentifier(AccessibilityID.Dashboard.refreshButton)
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No holdings yet")
                .foregroundStyle(.secondary)
        }
    }
}
