# iStocks

> iOS stock tracking app with real-time prices, multiple data sources, and Clean Architecture.

[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Strict Concurrency](https://img.shields.io/badge/Strict_Concurrency-complete-brightgreen.svg)](#swift-6-strict-concurrency)
[![iOS](https://img.shields.io/badge/iOS-18.5+-blue.svg)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-100%25-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![Dependencies](https://img.shields.io/badge/Dependencies-0-brightgreen.svg)](#tech-stack)
[![Tests](https://img.shields.io/badge/Tests-203_passing-brightgreen.svg)](#testing)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**[Demo Video](https://youtube.com/shorts/u0Ma-Z8fVSY?feature=share)** · **[Architecture](docs/ARCHITECTURE.md)** · **[Setup Guide](docs/SETUP.md)** · **[Tech Decisions](docs/TECH_DECISIONS.md)**

---

## Features

- **Multiple Watchlists** — Up to 10 watchlists, 10 stocks each
- **4 Data Sources** — Mock, REST (TwelveData), WebSocket (Finnhub), GraphQL — swap with one env var
- **Real-time Streaming** — WebSocket prices with 1s batching, deduplication, auto-reconnect
- **Batched API Calls** — 8 symbols/request, exponential backoff, max 2 retries
- **Persistence** — SwiftData with bidirectional entity relationships and migration-safe schema
- **Stock Research** — Integrated WKWebView with bookmarks, history, JavaScript bridge
- **Swift 6 Strict Concurrency** — Compiled with `complete` checking + `defaultIsolation(MainActor)`; shared state isolated behind actors
- **Accessibility** — VoiceOver identifiers across all interactive elements
- **Zero Dependencies** — Pure Apple frameworks only (no CocoaPods, no SPM packages)

---

## Architecture

**Clean Architecture + MVVM** with strict layer separation:

```
Presentation          Domain                 Data
───────────────       ──────────────         ─────────────────────
SwiftUI Views    ──►  Entities (Stock,  ──►  Mock Repository
@MainActor VMs        Watchlist)             REST Repository
Manual DI             Use Cases              WebSocket Repository
                      Repository             GraphQL Repository
                      Protocols              SwiftData Persistence
                      (zero imports)         DTOs + Mappers
```

**Key principles:**
- Domain layer has **zero framework imports** — pure Swift protocols and entities
- 4 interchangeable repository implementations behind one protocol
- ViewModels depend on use case protocols, never on concrete data sources
- Manual DI containers with caching and mode validation

### Data Source Strategy

Controlled via `WATCHLIST_MODE` environment variable:

| Mode | Source | API Keys | Default |
|------|--------|----------|---------|
| `mock` | Simulated prices | No | Debug builds |
| `rest` | TwelveData REST API | Yes | Release builds |
| `websocket` | Finnhub real-time | Yes | — |
| `graphql` | GraphQL endpoint | Yes | — |

---

## Quick Start

```bash
git clone https://github.com/shaqir/iStocks.git
cd iStocks
open iStocks.xcodeproj
# ⌘R — runs in mock mode, no setup needed
```

**For live data:** Set `FINNHUB_API_KEY` and `TWELVE_DATA_API_KEY` as environment variables or in the Xcode scheme. Free keys from [twelvedata.com](https://twelvedata.com) and [finnhub.io](https://finnhub.io). See [Setup Guide](docs/SETUP.md).

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
| Logging | os.Logger with category-based filtering |
| Testing | XCTest + Swift Testing, protocol-based mocking |
| Dependencies | **None** — zero external packages |

---

## Testing

**203 tests** (193 XCTest + 10 Swift Testing) across 25 suites, all passing under Swift 6 strict concurrency — 0 crashes, 0 concurrency warnings.

```bash
xcodebuild test \
  -scheme iStocks \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.2'
```

| Area | Coverage |
|------|----------|
| ViewModels | Watchlists, Watchlist, Edit, Tab, Provider, Dashboard |
| Repositories | REST, Mock, GraphQL |
| Concurrency | `PortfolioActor` (async, isolation, optimistic-rollback) — Swift Testing |
| Domain | Holding/Dashboard P&L math (parameterized) — Swift Testing |
| Persistence | SwiftData CRUD (in-memory) |
| Networking | Client, endpoints, error mapping, response mappers |
| UI Components | StockPickerView, SharedAlertManager |
| Utilities | AppConstants, Array extensions |

Both frameworks run in one target: legacy suites in **XCTest**, newer value/actor tests in **Swift Testing** (`@Suite`, parameterized `@Test(arguments:)`, `#expect`/`#require`, `await #expect(throws:)`).

---

## Project Structure

```
iStocks/                              107 Swift source files
├── App/                              Entry point
├── Core/
│   ├── Accessibility/                VoiceOver identifiers
│   ├── Constants/                    AppConstants, AppStrings, AppFonts
│   ├── Extensions/                   Double, Color, Font, Array
│   └── Utilities/                    AppConfiguration, AppError, SecureAPIKeyManager
├── Features/
│   ├── Watchlist/                    ★ Fully implemented
│   │   ├── Domain/                   Entities, UseCases, Repository protocols
│   │   ├── Data/                     4 repos, DTOs, Mappers, DataSources
│   │   └── Presentation/            ViewModels, Views, DI container
│   ├── Research/                     WKWebView + Domain layer
│   ├── Dashboard/                    Actor-based concurrency (PortfolioActor), mocked data
│   └── Portfolio, Orders,            Placeholders (scaffolding)
│       Positions, Settings
├── Shared/
│   ├── Networking/                   NetworkClient, Endpoint, URLSession impl
│   ├── Components/                   AppLogger, SharedAlertManager
│   └── TabBar/                       Custom tab navigation
└── Resources/                        Assets, Inter fonts

iStocksTests/                         32 test files (XCTest + Swift Testing)
iStocksIntegrationTests/              Integration suite
```

---

## Key Implementations

### Swift 6 Strict Concurrency

Compiled with `SWIFT_VERSION = 6.0`, `SWIFT_STRICT_CONCURRENCY = complete`, and
`defaultIsolation(MainActor.self)` (SE-0466 approachable concurrency).

| Pattern | Where |
|---------|-------|
| **Module-wide MainActor default** | UI (Views, ViewModels) is MainActor by default; Domain/Data types are explicitly `nonisolated` so they're usable from actors and `TaskGroup`s |
| **Actors for shared state** | `StockStateActor` (live prices) and `PortfolioActor` (holdings) replace serial `DispatchQueue`s — no locks, races caught at compile time |
| **Actor reentrancy** | `PortfolioActor.executeTrade` uses optimistic-mutation-then-rollback; `refreshPrices` deduplicates in-flight tasks |
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
4 interchangeable repository implementations behind a single `WatchlistRepository` protocol. Selected at build time via `AppConfiguration.watchlistMode` — swap between Mock, REST, WebSocket, or GraphQL without changing a single line of ViewModel or View code.

### WebSocket Resilience
`FinnhubWebSocketClient` manages real-time price streaming with multiple layers of fault tolerance:

| Layer | Mechanism |
|-------|-----------|
| **Connection** | State machine: disconnected → connecting → connected → reconnecting |
| **Retry** | `ConnectionRetryManager` with exponential backoff (max 5 attempts, 60s cap) |
| **Keep-alive** | Heartbeat ping every 10 seconds |
| **Recovery** | Message queue — subscriptions sent while disconnected are flushed on reconnect |
| **Performance** | `collect(.byTime(1s))` batches updates, deduplicates per symbol before hitting UI |

### Typed Error Hierarchy
Layered error types with user-facing messages and recovery suggestions:

```
AppError
├── .network(NetworkError)        — invalidURL, timeout, rateLimited, serverError, ...
├── .persistence(PersistenceError) — saveFailed, loadFailed, migrationFailed, ...
├── .validation(ValidationError)   — invalidSymbol, duplicateEntry, limitExceeded, ...
├── .webSocket(WebSocketError)     — connectionFailed, disconnected, authFailed, ...
└── .configuration(ConfigError)    — missingAPIKey, invalidConfiguration, ...
```
Each case provides `errorDescription`, `failureReason`, `recoverySuggestion`, and `isRetryable`.

### Production Logging
`AppLogger` wraps `os.Logger` with category-based filtering:

| Category | Tracks |
|----------|--------|
| `network` | API calls, responses, errors |
| `webSocket` | Connection state, subscriptions, heartbeat |
| `persistence` | SwiftData save/load/delete operations |
| `viewModel` | State transitions, user actions |
| `startup` | App configuration, mode selection |

Privacy-safe formatting. Filterable in Console.app by subsystem and category.

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
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layer diagrams, data flow, threading model |
| [SETUP.md](docs/SETUP.md) | Prerequisites, API keys, build configurations |
| [TECH_DECISIONS.md](docs/TECH_DECISIONS.md) | Technology choices, trade-offs, lessons learned |
| [IMPROVEMENTS.md](docs/IMPROVEMENTS.md) | Code quality improvements and roadmap |
| [CODEBASE_ANALYSIS.md](docs/CODEBASE_ANALYSIS.md) | Comprehensive architectural reference |

---

## Author

**Sakir Saiyed** — Senior iOS Engineer

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat&logo=linkedin)](https://www.linkedin.com/in/sakirsaiyed/)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-black?style=flat&logo=github)](https://github.com/shaqir)

---

## License

MIT License — see [LICENSE](LICENSE) for details.
