//
//  FetchDashboardUseCase.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Use case protocol — Sendable for safe passage across actor boundaries.
nonisolated protocol FetchDashboardUseCaseProtocol: Sendable {
    func execute(userId: String) async throws -> Dashboard
}

/// NOTE: Orchestrates dashboard loading with structured concurrency.
///
///
///   1. Sequential → Parallel flow (need holdings before fetching prices)
///   2. async let for fixed parallel tasks (prices + news simultaneously)
///   3. TaskGroup for dynamic parallel tasks (N symbols, each fetched concurrently)
///   4. Task.checkCancellation for cooperative cancellation
///   5. Graceful degradation (price failure keeps cached, news failure returns empty)
/// NOTE (Swift 6.2): nonisolated — domain use cases should be callable from any context.
nonisolated final class FetchDashboardUseCase: FetchDashboardUseCaseProtocol, @unchecked Sendable {

    private let stockRepository: StockRepositoryProtocol
    private let portfolio: PortfolioActor

    init(stockRepository: StockRepositoryProtocol, portfolio: PortfolioActor) {
        self.stockRepository = stockRepository
        self.portfolio = portfolio
    }

    func execute(userId: String) async throws -> Dashboard {
        // PHASE 1: Sequential — we need holdings first to know which symbols to fetch.
        // NOTE: This MUST complete before Phase 2 because symbols come from holdings.
        AppLogger.info("▶ Phase 1 — fetching holdings (sequential)", category: AppLogger.viewModel)
        let holdings = try await stockRepository.fetchHoldings(userId: userId)
        let symbols = holdings.map(\.symbol)
        AppLogger.info("✓ Phase 1 complete — \(holdings.count) holdings: \(symbols.joined(separator: ", "))", category: AppLogger.viewModel)

        // NOTE: Check cancellation between phases — if the user navigated away
        // during the holdings fetch, don't waste resources on Phase 2.
        try Task.checkCancellation()

        // PHASE 2: Parallel — fetch prices and news simultaneously.
        // NOTE: async let fires both requests concurrently. The runtime starts
        // both tasks immediately; `await` later collects the results.
        AppLogger.info("▶ Phase 2 — launching prices + news in parallel (async let)", category: AppLogger.viewModel)
        let phase2Start = Date()
        async let refreshedHoldings = refreshPrices(holdings: holdings)
        async let news = fetchNewsSafely(symbols: symbols)

        // PHASE 3: Collect results.
        // NOTE: Critical data (prices) can throw — we want to fail if prices fail.
        // Non-critical data (news) uses a safe wrapper that returns empty on failure.
        let finalHoldings = try await refreshedHoldings
        let finalNews = await news
        let elapsed = String(format: "%.2f", Date().timeIntervalSince(phase2Start))
        AppLogger.info("✓ Phase 2 complete — prices + news in \(elapsed)s (parallel, not sequential)", category: AppLogger.viewModel)

        // Update actor state — thread-safe, no locks needed.
        AppLogger.info("▶ Updating PortfolioActor state (thread-safe, no locks)", category: AppLogger.viewModel)
        await portfolio.update(finalHoldings)

        let totalValue = finalHoldings.reduce(0.0) { $0 + $1.marketValue }
        AppLogger.info("✓ Dashboard ready — total value: $\(String(format: "%.2f", totalValue))", category: AppLogger.viewModel)

        return Dashboard(
            holdings: finalHoldings,
            news: finalNews,
            totalValue: totalValue,
            lastUpdated: Date()
        )
    }

    // MARK: - Private

    /// Refreshes prices for all holdings in parallel using TaskGroup.
    ///
    /// NOTE: TaskGroup vs async let — use TaskGroup when you have a DYNAMIC
    /// number of tasks (N holdings). Use async let when you have a FIXED
    /// number of known tasks (prices + news = always 2).
    private func refreshPrices(holdings: [Holding]) async throws -> [Holding] {
        AppLogger.info("  ↳ TaskGroup — adding \(holdings.count) tasks concurrently", category: AppLogger.viewModel)
        return try await withThrowingTaskGroup(of: Holding.self) { group in
            for holding in holdings {
                // NOTE: [stockRepository] capture list avoids capturing `self`
                group.addTask { [stockRepository] in
                    AppLogger.info("    → [\(holding.symbol)] price fetch started", category: AppLogger.viewModel)
                    do {
                        let price = try await stockRepository.fetchPrice(for: holding.symbol)
                        AppLogger.info("    ✓ [\(holding.symbol)] price: $\(String(format: "%.2f", price))", category: AppLogger.viewModel)
                        return holding.withUpdatedPrice(price)
                    } catch {
                        // NOTE: Graceful degradation — if one price fails,
                        // keep the cached price rather than failing the entire dashboard.
                        AppLogger.warning("    ⚠ [\(holding.symbol)] price failed — using cached", category: AppLogger.viewModel)
                        return holding
                    }
                }
            }

            var results: [Holding] = []
            for try await holding in group {
                results.append(holding)
            }
            return results
        }
    }

    /// Fetches news with graceful failure — returns empty array instead of throwing.
    ///
    /// NOTE: News is non-critical data. A failed news fetch should never
    /// prevent the user from seeing their portfolio.
    private func fetchNewsSafely(symbols: [String]) async -> [News] {
        (try? await stockRepository.fetchNews(for: symbols)) ?? []
    }
}
