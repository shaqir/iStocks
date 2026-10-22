# iStocks — Architecture

> Written from the source on `main` (October 2026). Known gaps are listed at the end and
> deferred work is in [FUTURE_WORK.md](FUTURE_WORK.md).

## What the app is

A SwiftUI stock watchlist app built as a personal learning project: Clean Architecture,
MVVM, Combine, Swift 6 strict concurrency, and actors, applied to a real-ish domain.

**Implemented**
- **Watchlist** (full Clean Architecture): up to 10 watchlists × 10 stocks, add / rename /
  delete, a stock picker over 50 preset NYSE symbols, and a local symbol filter.
- **Portfolio tab** (`DashboardView`): holdings, P&L and news. Holdings and news are
  always mock data; prices are mock in Debug builds. It exists to show `async let`,
  `TaskGroup` and actor isolation.
- **Research**: `WKWebView` with a JavaScript bridge, bookmarks and history.
- **Auth gate**: Face ID / Touch ID via `LAContext` (skipped on the simulator).

**Placeholders**: Orders and Settings tabs.

## At a glance

| Concern | Approach | Where |
|---|---|---|
| UI | SwiftUI, custom enum-driven tab bar | `Shared/TabBar/`, `Features/*/Presentation/` |
| Pattern | Clean Architecture layers + MVVM, manual DI containers | `Features/*/`, `*DIContainer.swift` |
| State | `ObservableObject` + `@Published` ViewModels | `Features/*/Presentation/ViewModel*/` |
| Concurrency | Swift 6, strict concurrency `complete`, default isolation `MainActor` (app target), `nonisolated` Domain/Data types, 4 actors, `@concurrent` | `WatchlistsViewModel.swift`, `Data/DataSources/WebSocket/`, `PortfolioActor.swift` |
| Reactive | Combine for Watchlist streams; async/await for Dashboard and Auth; `withCheckedThrowingContinuation` bridges | `StockRemoteDataSource.swift`, `FetchDashboardUseCase.swift` |
| Networking | `Endpoint` builder + `NetworkClient` protocol (Combine and async), generic `APIClient` with associated-type endpoints | `Shared/Networking/` |
| Errors | `AppError` hierarchy with `NetworkError`, `PersistenceError`, `ValidationError`, `WebSocketError`, `ConfigurationError` | `Core/Utilities/AppError.swift` |
| Persistence | SwiftData (`WatchlistEntity` ↔ `StockEntity`), local only | `Watchlist/Data/DataSources/Local/` |
| Logging | `AppLogger` over `os_log`, per-category | `Shared/Components/Logging/Logger.swift` |
| Testing | XCTest + Swift Testing (unit), XCUITest (UI), live integration suite | `iStocksTests/`, `iStocksUITests/`, `iStocksIntegrationTests/` |

## Layers

```
App/            composition root — iStocksApp, modelContainer, AuthGate
Core/           AppError, AppConfiguration, SecureAPIKeyManager, AppConstants, a11y IDs
Shared/         Networking, Logging, TabBar, Alert coordination
Features/{F}/
  Domain/       entities, repository protocols, use cases
  Data/         repository impls, DataSources (Local / Remote / WebSocket / Mock), DTOs, Mappers
  Presentation/ SwiftUI Views, ViewModels, DI container
```

Dependency rule: `Presentation → Domain ← Data`. ViewModels receive use-case protocols
through their initializer; use cases depend on repository protocols.

**Deliberate trade-off:** Domain uses Combine as its stream abstraction — repository
protocols return `AnyPublisher` — so Domain imports Foundation and Combine, not UIKit,
SwiftUI or SwiftData.

## Data source modes

One `WatchlistRepository` protocol, three implementations, chosen at launch:

| `WATCHLIST_MODE` | Source | Notes |
|---|---|---|
| `mock` (Debug default) | `MockStockRepositoryImpl` | Simulated prices, no keys |
| `rest` (Release always) | `RestStockRepositoryImpl` | Twelve Data `/quote` and `/price` |
| `websocket` | `WebSocketStockRepositoryImpl` | Finnhub stream (currently `BINANCE:BTCUSDT`) + REST for the initial list |

The env var is read only in Debug builds (`AppConfiguration.watchlistMode`). API keys
`TWELVE_DATA_API_KEY` / `FINNHUB_API_KEY` come from the environment or Info.plist.

### REST (Twelve Data)
- 50 preset symbols are fetched in batches of 8. A failed batch is retried up to 2 times
  with a fixed 60s delay (free-tier rate limit) — not exponential backoff.
- HTTP status mapping: 401 → `unauthorized`, 429 → `rateLimited`, 5xx → `serverError`;
  everything surfaces as `AppError`.

### WebSocket (Finnhub)
- States: `disconnected → connecting → connected`, with `reconnecting` on a drop. The
  transitions are validated in `WebSocketConnectionActor.transition(to:)`.
- Reconnect: `ConnectionRetryManager` actor, delay = 2ⁿ s (1, 2, 4, 8, 16), 60s cap,
  gives up after 5 attempts, resets on a successful connect.
- Subscriptions survive a reconnect (subscribed symbols move back to pending).
- An app-level heartbeat message every 10s; outgoing messages queue (max 1000) while
  disconnected.
- Updates are batched with `collect(.byTime(1s))`, reduced to the latest price per symbol,
  then applied atomically in `StockStateActor`.

## Build & test

```bash
# Build
xcodebuild build -scheme iStocks -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Unit + UI tests (no API keys needed)
xcodebuild test -scheme iStocks -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skip-testing:iStocksIntegrationTests
```

Integration tests call the live Twelve Data API and fail with HTTP 401 without a real
`TWELVE_DATA_API_KEY`.

## Known gaps

- **Persistence** swallows errors, drops empty watchlists, isn't a `@ModelActor`, and
  `saveAllStocks` also clears stocks that belong to watchlists.
- **REST prices aren't refreshed** once all 50 symbols are cached; there's no
  "last updated" timestamp.
- **Abstraction leak:** `WatchlistsViewModel` downcasts to `RestStockRepositoryImpl` for
  batch progress.
- **`PortfolioActor.executeTrade`** rolls back to a pre-`await` snapshot, which can drop
  trades made concurrently.
- **Logging** marks messages `%{public}`; callers must not log secrets.
- **Auth** is biometrics-only (no passcode fallback).
- **No CI** at the moment (see FUTURE_WORK).
