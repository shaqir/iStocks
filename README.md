# iStocks

> A SwiftUI stock watchlist app I built to learn and practice Clean Architecture, MVVM, Combine, and Swift 6 concurrency.

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Strict Concurrency](https://img.shields.io/badge/Strict_Concurrency-complete-brightgreen.svg)](#swift-6-strict-concurrency)
[![iOS](https://img.shields.io/badge/iOS-18.2+-blue.svg)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-100%25-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![Dependencies](https://img.shields.io/badge/Dependencies-0-brightgreen.svg)](#tech-stack)
[![Tests](https://img.shields.io/badge/Tests-202_passing-brightgreen.svg)](#testing)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**[Demo Video](https://youtube.com/shorts/u0Ma-Z8fVSY?feature=share)** · **[Architecture](docs/ARCHITECTURE.md)** · **[Future Work](docs/FUTURE_WORK.md)**

---

## Features

- **Multiple Watchlists** — Up to 10 watchlists, 10 stocks each
- **3 Data Sources** — Mock, REST (Twelve Data), WebSocket (Finnhub) — swap with one env var in Debug
- **Real-time Streaming** — WebSocket prices with 1s batching, latest-per-symbol dedup, reconnect with backoff and resubscribe
- **Batched API Calls** — 8 symbols/request, up to 2 retries with a fixed 60s delay (free-tier rate limit)
- **Persistence** — SwiftData with a bidirectional `WatchlistEntity` ↔ `StockEntity` relationship (local only)
- **Stock Research** — Integrated WKWebView with bookmarks, history, JavaScript bridge
- **Swift 6 Strict Concurrency** — Compiled with `complete` checking + `defaultIsolation(MainActor)`; shared state isolated behind actors
- **Accessibility identifiers** — on interactive elements, used by the XCUITest suite
- **Zero Dependencies** — Pure Apple frameworks only (no CocoaPods, no SPM packages)

---

## Architecture

**Clean Architecture + MVVM**, with Domain / Data / Presentation layers per feature:

```
Presentation          Domain                 Data
───────────────       ──────────────         ─────────────────────
SwiftUI Views    ──►  Entities (Stock,  ◄──  Mock Repository
ObservableObject      Watchlist)             REST Repository
ViewModels            Use Cases              WebSocket Repository
Manual DI             Repository             SwiftData Persistence
                      Protocols              DTOs + Mappers
```

**Key principles:**
- Domain has no UI or persistence imports; it uses Combine (`AnyPublisher`) as its stream type — a deliberate trade-off
- 3 interchangeable repository implementations behind one protocol
- ViewModels receive use-case protocols through their initializer
- Manual DI containers that cache repositories per mode

### Data Source Strategy

Controlled via the `WATCHLIST_MODE` environment variable (Debug builds only):

| Mode | Source | API Keys | Default |
|------|--------|----------|---------|
| `mock` | Simulated prices | No | Debug builds |
| `rest` | TwelveData REST API | Yes | Release builds |
| `websocket` | Finnhub real-time (currently `BINANCE:BTCUSDT`) | Yes | — |

---

## Quick Start

```bash
git clone https://github.com/shaqir/iStocks.git
cd iStocks
open iStocks.xcodeproj
# ⌘R — runs in mock mode, no setup needed
```

**For live data:** Set `FINNHUB_API_KEY` and `TWELVE_DATA_API_KEY` as environment variables or in the Xcode scheme. Free keys from [twelvedata.com](https://twelvedata.com) and [finnhub.io](https://finnhub.io).

**Requirements:** Xcode 26 or later (Swift 6, project format 77), iOS 18.2+ simulator.

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| UI | SwiftUI (100%) |
| Architecture | Clean Architecture + MVVM |
| Reactive | Combine (publishers, subjects, operators) |
| Concurrency | Swift 6 strict (`complete`), `defaultIsolation(MainActor)`, actors, structured concurrency, `Sendable` |
| Persistence | SwiftData (WatchlistEntity ↔ StockEntity) |
| Networking | URLSession (HTTP + WebSocket) |
| Logging | `AppLogger` over `os_log`, category-based filtering |
| Testing | XCTest + Swift Testing (unit), XCUITest (UI), protocol-based mocks, `MockURLProtocol` |
| Dependencies | **None** — zero external packages |

---

## Testing

**202 tests passing** (197 unit + 5 UI), plus a live integration suite that needs a Twelve Data key.

```bash
xcodebuild test \
  -scheme iStocks \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skip-testing:iStocksIntegrationTests
```

| Area | Coverage |
|------|----------|
| ViewModels | Watchlists, Watchlist, Edit, Tab, Provider, Dashboard |
| Repositories | REST, Mock |
| Concurrency | `PortfolioActor`, `WebSocketConnectionActor` state machine — Swift Testing |
| Domain | Holding/Dashboard P&L math (parameterized) — Swift Testing |
| Persistence | SwiftData CRUD (in-memory) |
| Networking | Client, endpoints, error mapping, response mappers |
| UI Components | StockPickerView, SharedAlertManager |
| UI flows | Tab bar, tab switching, watchlist load, search — XCUITest (mock mode) |

Both frameworks run in one target: legacy suites in **XCTest**, newer value/actor tests in **Swift Testing** (`@Suite`, parameterized `@Test(arguments:)`, `#expect`/`#require`, `await #expect(throws:)`).

---

## Project Structure

```
iStocks/                              119 Swift source files
├── App/                              Entry point
├── Core/
│   ├── Accessibility/                Accessibility identifiers
│   ├── Constants/                    AppConstants, AppStrings, AppFonts
│   ├── Extensions/                   Double, Color, Font, Array
│   └── Utilities/                    AppConfiguration, AppError, SecureAPIKeyManager
├── Features/
│   ├── Watchlist/                    ★ Fully implemented
│   │   ├── Domain/                   Entities, UseCases, Repository protocols
│   │   ├── Data/                     3 repos, DTOs, Mappers, DataSources
│   │   └── Presentation/            ViewModels, Views, DI container
│   ├── Research/                     WKWebView + Domain layer
│   ├── Dashboard/                    Portfolio tab — actors + async let/TaskGroup, mocked data
│   ├── Auth/                         Face ID / Touch ID gate
│   └── Orders, Settings              Placeholders
├── Shared/
│   ├── Networking/                   NetworkClient, Endpoint, URLSession impl
│   ├── Components/                   AppLogger, SharedAlertManager
│   └── TabBar/                       Custom tab navigation
└── Resources/                        Assets, Inter fonts

iStocksTests/                         Unit tests (XCTest + Swift Testing)
iStocksUITests/                       XCUITest flows
iStocksIntegrationTests/              Live Twelve Data integration suite
```

---

## Key Implementations

### Swift 6 Strict Concurrency

Compiled with `SWIFT_VERSION = 6.0`, `SWIFT_STRICT_CONCURRENCY = complete`, and
default isolation `MainActor` (SE-0466) on the app target.

| Pattern | Where |
|---------|-------|
| **Module-wide MainActor default** | UI (Views, ViewModels) is MainActor by default; Domain/Data types are explicitly `nonisolated` so they're usable from actors and `TaskGroup`s |
| **Actors for shared state** | `StockStateActor` (live prices) and `PortfolioActor` (holdings) replace serial `DispatchQueue`s — no locks, races caught at compile time |
| **Actor reentrancy** | `PortfolioActor.executeTrade` uses optimistic-mutation-then-rollback; `refreshPrices` cancels the previous in-flight refresh |
| **Structured concurrency** | `async let` + `withThrowingTaskGroup` in `FetchDashboardUseCase`; GCD retry/heartbeat loops migrated to cancellation-aware `Task.sleep` |
| **Sendable discipline** | DTOs/entities are `Sendable`; `@preconcurrency import Combine` bridges non-Sendable `PassthroughSubject` at the framework boundary |

**War story (the migration's hardest bug):** turning on strict concurrency surfaced a libmalloc
double-free that crashed ~56 tests. The crash backtrace pointed at
`swift_task_deinitOnExecutorMainActorBackDeploy` — under `defaultIsolation`, every MainActor
class gets an *isolated deinit* that hops to the executor via a back-deployment shim, which is
buggy when the deployment target predates the native runtime symbol. Fix: `nonisolated deinit`
on the ViewModels and `nonisolated` on Domain/Data types (where they belong anyway). See
[docs/Swift6.2-Migration-Plan.md](docs/Swift6.2-Migration-Plan.md).

### Strategy Pattern — Data Source Swapping
3 interchangeable repository implementations behind a single `WatchlistRepository` protocol, selected at launch via `AppConfiguration.watchlistMode` — swap between Mock, REST, or WebSocket without changing ViewModel or View code. (A GraphQL mode was removed; see [Future Work](docs/FUTURE_WORK.md).)

### WebSocket Resilience
`FinnhubWebSocketClient` manages real-time price streaming with multiple layers of fault tolerance:

| Layer | Mechanism |
|-------|-----------|
| **Connection** | Actor-owned state machine (disconnected / connecting / connected / reconnecting) with a validated transition table |
| **Retry** | `ConnectionRetryManager` actor: 1, 2, 4, 8, 16s backoff, 60s cap, gives up after 5 attempts |
| **Keep-alive** | App-level heartbeat message every 10 seconds |
| **Recovery** | Subscriptions are restored after reconnect; queued messages (max 1000) flush on connect |
| **Performance** | `collect(.byTime(1s))` batches updates, deduplicates per symbol before hitting UI |

### Typed Error Hierarchy
Layered error types with user-facing messages and recovery suggestions:

```
AppError
├── .network(NetworkError)        — invalidURL, timeout, rateLimited, serverError, ...
├── .persistence(PersistenceError) — saveFailed, loadFailed, migrationFailed, ...
├── .validation(ValidationError)   — invalidSymbol, duplicateEntry, limitExceeded, ...
├── .webSocket(WebSocketError)     — connectionFailed, disconnected, authFailed, ...
└── .configuration(ConfigurationError) — missingAPIKey, invalidConfiguration, ...
```
Each case provides `errorDescription`, `failureReason`, `recoverySuggestion`, and `isRetryable`.

### Logging
`AppLogger` wraps `os_log` with category-based filtering:

| Category | Tracks |
|----------|--------|
| `network` | API calls, responses, errors |
| `webSocket` | Connection state, subscriptions, heartbeat |
| `persistence` | SwiftData save/load/delete operations |
| `viewModel` | State transitions, user actions |
| `startup` | App configuration, mode selection |

Filterable in Console.app by subsystem and category. Messages are logged with `%{public}` so they stay readable in Console.app — which means callers must never log secrets (API keys, tokens).

---

## Screenshots

<table>
  <tr>
    <th>Watchlist</th>
    <th>Stock Picker</th>
    <th>Edit Watchlist</th>
  </tr>
  <tr>
    <td><img width="250" src="https://github.com/user-attachments/assets/f47e92a0-8da8-4769-a04b-0d030031005c" alt="Watchlist" /></td>
    <td><img width="250" src="https://github.com/user-attachments/assets/61051964-fc64-4f71-a75d-0c59e5bcd099" alt="Stock Picker" /></td>
    <td><img width="250" src="https://github.com/user-attachments/assets/14c66f8d-09c5-4856-95e7-7f464780a426" alt="Edit Watchlist" /></td>
  </tr>
</table>

---

## Documentation

| Doc | Description |
|-----|-------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layers, data sources, concurrency, known gaps |
| [FUTURE_WORK.md](docs/FUTURE_WORK.md) | Deferred work, including the removed GraphQL mode |
| [Swift6.2-Migration-Plan.md](docs/Swift6.2-Migration-Plan.md) | Swift 6 migration log and lessons learned |

---

## Author

**Sakir Saiyed** — Senior iOS Engineer

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat&logo=linkedin)](https://www.linkedin.com/in/sakirsaiyed/)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-black?style=flat&logo=github)](https://github.com/shaqir)

---

## License

MIT License — see [LICENSE](LICENSE) for details.
