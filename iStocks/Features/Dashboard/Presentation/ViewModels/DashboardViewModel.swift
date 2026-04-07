//
//  DashboardViewModel.swift
//  iStocks
//
//  Created by Sakir Saiyed
//

import Foundation

/// Portfolio dashboard ViewModel with structured concurrency and task lifecycle management.
///
/// NOTE: @MainActor guarantees ALL @Published property updates happen on the main thread.
/// Without this, setting `isLoading = true` from a background task would crash.
/// This replaces the old pattern of wrapping every update in DispatchQueue.main.async {}.
/// Implicitly @MainActor via defaultIsolation(MainActor.self) — SE-0466
final class DashboardViewModel: ObservableObject {

    @Published private(set) var dashboard: Dashboard?
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private let fetchDashboardUseCase: FetchDashboardUseCaseProtocol
    private var loadTask: Task<Void, Never>?

    /// NOTE: Dependency injection via protocol — the ViewModel never knows whether
    /// it's using a real API or a mock. Tests inject MockFetchDashboardUseCase.
    init(fetchDashboardUseCase: FetchDashboardUseCaseProtocol) {
        self.fetchDashboardUseCase = fetchDashboardUseCase
    }

    /// Called when the view appears. Cancels any in-flight request and starts fresh.
    ///
    /// NOTE: Task cancellation pattern — if the user rapidly switches tabs,
    /// we cancel the previous load to avoid stale data overwriting fresh data.
    func onAppear() {
        loadTask?.cancel()
        loadTask = Task {
            isLoading = true
            error = nil

            do {
                dashboard = try await fetchDashboardUseCase.execute(userId: "current-user")
            } catch is CancellationError {
                // NOTE: User navigated away — don't show an error.
                // This is the correct way to handle structured cancellation.
                return
            } catch {
                self.error = error.localizedDescription
            }

            isLoading = false
        }
    }

    /// Called when the view disappears. Cancels any in-flight load.
    ///
    /// NOTE: Without this, the Task continues running even after the view is gone,
    /// wasting network resources and potentially updating a deallocated ViewModel.
    func onDisappear() {
        loadTask?.cancel()
    }

    /// Pull-to-refresh handler — doesn't use Task lifecycle (SwiftUI manages it).
    func refresh() async {
        isLoading = true
        error = nil

        do {
            dashboard = try await fetchDashboardUseCase.execute(userId: "current-user")
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    /// NOTE: deinit logging is my standard practice to catch retain cycles early.
    /// If this message never prints when navigating away, there's a leak.
    /// Use Instruments > Allocations to investigate further.
    deinit {
        #if DEBUG
        print("[DEBUG] DashboardViewModel deallocated — no retain cycle")
        #endif
    }
}
