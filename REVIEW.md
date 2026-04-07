# Code Review Guidelines — iStocks

These guidelines direct automated code review (Codex, Claude) on what to check and what to skip.

## Architecture (Clean Architecture + MVVM)

- **Layer violations**: Domain layer must have zero framework imports — pure Swift only. ViewModels must never access network/persistence directly; they go through use cases.
- **Dependency rule**: Inner layers (Domain) must not reference outer layers (Data, Presentation). Verify imports.
- **Repository protocol**: All data source access must go through protocol abstractions (`WatchlistRepository`, `StockRepositoryProtocol`). No concrete repository references in ViewModels or use cases.
- **DI container**: New dependencies should be wired through `WatchlistDIContainer` or `DashboardDIContainer`, not instantiated inline.

## Swift 6.2 Concurrency

- **defaultIsolation**: The app uses `defaultIsolation(MainActor.self)`. All types are MainActor by default unless explicitly `nonisolated`.
- **nonisolated required on**: Domain entities, DTOs, mappers, error types, networking infrastructure, constants, protocols, repository implementations, use cases — anything in Data or Domain layers.
- **nonisolated NOT needed on**: SwiftUI Views, ViewModels, DI containers — these should remain MainActor.
- **Actor safety**: Check that actor-isolated state is not accessed without `await`. Verify `executeTrade` rollback pattern and `refreshPrices` dedup pattern in `PortfolioActor`.
- **Sendable compliance**: Types crossing actor boundaries must be `Sendable`. Use `@unchecked Sendable` only with documented safety justification. Never on new code without reason.
- **@preconcurrency**: Only for Apple framework delegate protocols (e.g., `URLSessionWebSocketDelegate`).
- **nonisolated(unsafe)**: Only for `deinit` cleanup of non-Sendable properties and legacy `@Published` workarounds. Must have a comment explaining why.

## WebSocket

- **State machine**: All `connectionState` changes must go through `transition(to:)` — never assign directly. Check the transition table is respected.
- **Bounded buffer**: Message queue must use `AppConstants.maxWebSocketMessageQueueSize`, not hardcoded values.
- **Backpressure**: The Combine pipeline in `WebSocketStockRepositoryImpl.bindWebSocket()` must keep the collect + dedup pattern (latest per symbol only).

## Error Handling

- **Typed errors**: Use `AppError`, `NetworkError`, `TwelveDataAPIError`, etc. — not generic `Error` or string messages.
- **Recovery suggestions**: All error types should provide `errorDescription`, `failureReason`, and `recoverySuggestion`.
- **Graceful degradation**: Non-critical failures (news fetch) should return empty/cached data, not throw.

## Testing

- **New code needs tests**: Any new public method, use case, or actor pattern should have corresponding unit tests.
- **Mock pattern**: Use protocol-based mocks (e.g., `MockWatchlistPersistenceService`), not concrete subclasses.
- **SwiftData tests**: Must use in-memory `ModelConfiguration(isStoredInMemoryOnly: true)`.
- **@MainActor on test classes**: Test classes accessing MainActor-isolated types need `@MainActor` annotation.

## Logging

- Use `AppLogger` with appropriate category — never `print()`.
- Categories: `network`, `webSocket`, `persistence`, `viewModel`, `di`, `startup`, `ui`, `webView`.

## Skip

- `*.xcodeproj/` — generated project files
- `DerivedData/` — build artifacts
- `fastlane/` — CI/CD configuration (review separately)
- Third-party dependencies resolved via SPM
- `Round3_Interview_Deep_Dive_Prep.docx` — personal document
