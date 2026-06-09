# iStocks — Project Overview (Tech, Tools & Architecture at a Glance)

> Current as of June 2026, verified against the code on branch
> `fix/interview-bugs-vm-cache-continuation-ws`. Where this doc and the older
> files in `docs/` disagree, trust this one — it was written from the source,
> not from memory.

## What the app is

A SwiftUI **stock watchlist + dashboard** app. The engineering *is* the product:
it's a showcase of modern iOS architecture — Clean Architecture, Swift 6 strict
concurrency, and four interchangeable data backends behind a single protocol.

The user browses sector-grouped watchlists with live-ish prices, edits them
(up to 10 stocks/watchlist, 10 watchlists), views a portfolio dashboard with
holdings + news, and does in-app research in an embedded web view. One feature
(**Watchlist**) is built to full Clean Architecture depth; the rest demonstrate
range (actors, structured concurrency, WKWebView bridging) without over-building
placeholder tabs.

---

## Tech, tools & architecture — at a glance

| Layer / Concern | Tech & Tools | Where (representative paths) |
|---|---|---|
| **UI** | SwiftUI (iOS 18.5), enum-driven tab router (no Coordinator), `.sheet(item:)` modals | `Shared/TabBar/`, `Features/*/Presentation/` |
| **Pattern** | Clean Architecture (Domain / Data / Presentation) + MVVM, manual DI via per-feature containers | `Features/*/`, `*DIContainer.swift` |
| **Concurrency** | **Swift 6, strict concurrency = complete**: `defaultIsolation(MainActor.self)`, `nonisolated` domain/data types, 4 actors, `@concurrent` for CPU work | repo-wide; see `WatchlistsViewModel.swift:258`, `PortfolioActor.swift` |
| **Reactive** | Combine **+** async/await hybrid, bridged via `withCheckedThrowingContinuation` | `URLSessionNetworkClient.swift`, `StockRemoteDataSource.swift` |
| **Data backends** | **4 swappable repositories** behind one `WatchlistRepository` protocol: Mock / REST (TwelveData) / WebSocket (Finnhub) / GraphQL — chosen at runtime | `Watchlist/Data/Repositories/`, `WatchlistDIContainer.swift:101-150` |
| **Networking** | Struct `Endpoint` builder + PAT `APIEndpoint`; typed `NetworkError` with `isRetryable`; unified `AppError` hierarchy (`LocalizedError` + `recoverySuggestion`) | `Shared/Networking/`, `Core/Utilities/AppError.swift` |
| **Persistence** | SwiftData (`WatchlistEntity` / `StockEntity`); in-memory `ModelContainer` for tests | `Watchlist/Data/DataSources/Local/` |
| **Resilience** | Sequential batched REST (rate-limit aware, 60s delay, retries), WebSocket exponential backoff + heartbeat, `collect(.byTime)` + per-symbol dedup throttling | `StockRemoteDataSource.swift:104-181`, `ConnectionRetryManager.swift`, `WebSocketStockRepositoryImpl.swift:36-52` |
| **Security** | Face ID / Touch ID gate (`LAContext`); AES-GCM + CSPRNG salt | `Features/Auth/` |
| **Logging** | `AppLogger` over `os.Logger` (categories: network, webSocket, persistence, …), `nonisolated` so it's callable from actors / `@concurrent` | `Shared/Components/Logging/Logger.swift` |
| **Testing** | XCTest (193) + Swift Testing suite + **XCUITest** + live integration; ViewInspector for SwiftUI; shared `iStocksTestPlan.xctestplan` | `iStocksTests/`, `iStocksUITests/`, `iStocksIntegrationTests/` |
| **CI/CD & tooling** | Fastlane (`test` / `beta`), `xcodeproj` Ruby gem, git hooks (commit-msg / pre-push) | `fastlane/`, `.git/hooks/` |

---

## Architecture shape

```
App/            composition root — iStocksApp, modelContainer, AuthGate (device only)
Core/           cross-cutting — AppError, AppConfiguration, SecureAPIKeyManager, AppConstants, a11y IDs
Shared/         Networking, Logging, TabBar (navigation shell), Alert coordination
Features/{F}/
  Domain/       entities, repository protocols, use cases   ← pure Swift, no frameworks
  Data/         repo impls, DataSources (Local/Remote/WebSocket/Mock/GraphQL), DTOs, Mappers
  Presentation/ SwiftUI Views, ViewModels, DI container
```

Dependency rule: `Presentation → Domain ← Data`. Domain is the stable center;
ViewModels depend on use cases, use cases depend on repository *protocols*, never
on concrete networking or persistence.

**Implemented features:** Watchlist (full Clean Architecture), Dashboard
(concurrency showcase, data mocked in DEBUG), Research (WKWebView + JS bridge),
Auth gate (biometric). Orders / Portfolio-tab / Positions / Settings are honest
placeholder scaffolding.

---

## Data source modes

A strategy pattern swaps the backend with zero ViewModel changes. In Debug,
mode defaults to `.mock` (no API keys needed); Release always uses `.restAPI`.

- **Env var:** `WATCHLIST_MODE` = `mock` | `rest` | `websocket` | `graphql`
- **Code:** `AppConfiguration.watchlistMode` (`Core/Utilities/AppConfiguration.swift`)
- **API keys (non-mock):** `FINNHUB_API_KEY`, `TWELVE_DATA_API_KEY` via env var or Info.plist
  (resolved by `SecureAPIKeyManager`)

---

## Build & test

```bash
# Build
xcodebuild build -scheme iStocks -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Unit tests only (fast, no API keys)
xcodebuild test -scheme iStocks -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -skip-testing:iStocksIntegrationTests

# UI tests
xcodebuild test -scheme iStocks -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:iStocksUITests

# Fastlane
bundle exec fastlane test     # coverage + junit/html
bundle exec fastlane beta     # build + TestFlight
```

> **Simulator note:** the build commands above reference `iPhone 16`; that
> simulator may not be installed locally — `iPhone 16 Pro` / `iPhone 17 Pro` work.
>
> **Integration tests** hit the **live** TwelveData API and return HTTP 401
> without a real `TWELVE_DATA_API_KEY`. That's environmental — run unit-only with
> `-skip-testing:iStocksIntegrationTests` for a clean local pass.

---

## Honest known gaps

Documented deliberately — these are real and worth knowing:

- **Persistence** (`WatchlistPersistenceService.swift`) swallows all errors
  (logs, returns `[]`) and silently drops empty watchlists; not `@ModelActor`.
- **Abstraction leak:** `WatchlistsViewModel` downcasts a use case to the concrete
  `RestStockRepositoryImpl` to reach `progressPublisher` (`WatchlistsViewModel.swift:75-77`).
- **Security:** `KeychainManager` is fully built but **dead code**; `CryptoManager`
  uses HKDF as a password KDF (no work factor — should be PBKDF2/Argon2). API keys
  live in env/Info.plist, not the Keychain.
- **No product analytics** — only structured logging via `AppLogger`.
- **CI disabled** (`.github/workflows/ci.yml.disabled`) — runners don't yet support
  the required Xcode.
- **State management** uses `ObservableObject`/Combine; the modern move is the
  `@Observable` macro.
