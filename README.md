# iStocks

> iOS stock tracking app with real-time prices, multiple data sources, and Clean Architecture.

[![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-18.5+-blue.svg)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-100%25-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![Dependencies](https://img.shields.io/badge/Dependencies-0-brightgreen.svg)](#tech-stack)
[![Tests](https://img.shields.io/badge/Tests-159_passing-brightgreen.svg)](#testing)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**[Demo Video](https://youtube.com/shorts/u0Ma-Z8fVSY?feature=share)** · **[Architecture](docs/ARCHITECTURE.md)** · **[Setup Guide](docs/SETUP.md)** · **[Tech Decisions](docs/TECH_DECISIONS.md)**

---

## Features

- **Multiple Watchlists** — Up to 10 watchlists, 10 stocks each
- **4 Data Sources** — Mock, REST (TwelveData), WebSocket (Finnhub), GraphQL — swap with one env var
- **Real-time Streaming** — WebSocket prices with 1s batching, deduplication, auto-reconnect
- **Batched API Calls** — 8 symbols/request, exponential backoff, max 2 retries
- **Persistence** — SwiftData with bidirectional entity relationships
- **Stock Research** — Integrated WKWebView with bookmarks, history, JavaScript bridge
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
| Concurrency | @MainActor, DispatchQueue, async/await bridge |
| Persistence | SwiftData (WatchlistEntity ↔ StockEntity) |
| Networking | URLSession (HTTP + WebSocket) |
| Logging | os.Logger with category-based filtering |
| Testing | XCTest with protocol-based mocking |
| Dependencies | **None** — zero external packages |

---

## Testing

**159 tests** across 22 test suites, all passing.

```bash
xcodebuild test \
  -scheme iStocks \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=26.2'
```

| Area | Coverage |
|------|----------|
| ViewModels | Watchlists, Watchlist, Edit, Tab, Provider |
| Repositories | REST, Mock, GraphQL |
| Persistence | SwiftData CRUD (in-memory) |
| Networking | Client, endpoints, error mapping, response mappers |
| UI Components | StockPickerView, SharedAlertManager |
| Utilities | AppConstants, Array extensions |

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
│   └── Dashboard, Portfolio,         Placeholders (scaffolding)
│       Orders, Positions, Settings
├── Shared/
│   ├── Networking/                   NetworkClient, Endpoint, URLSession impl
│   ├── Components/                   AppLogger, SharedAlertManager
│   └── TabBar/                       Custom tab navigation
└── Resources/                        Assets, Inter fonts

iStocksTests/                         31 test files
iStocksIntegrationTests/              Integration suite
```

---

## Key Implementations

**Strategy Pattern** — 4 data source implementations behind `WatchlistRepository` protocol, selected at build time via `AppConfiguration.watchlistMode`.

**WebSocket Resilience** — `FinnhubWebSocketClient` with state machine (disconnected → connecting → connected → reconnecting), `ConnectionRetryManager` (exponential backoff, max 5 attempts), heartbeat keep-alive, message queuing across reconnections, `collect(.byTime())` for UI batching.

**Typed Error Hierarchy** — `AppError` wraps `NetworkError`, `PersistenceError`, `ValidationError`, `WebSocketError`, `ConfigurationError` — each with `errorDescription`, `failureReason`, `recoverySuggestion`, and `isRetryable`.

**Production Logging** — `AppLogger` wraps `os.Logger` with categories (network, webSocket, persistence, viewModel, startup, UI) and privacy-safe formatting. Filterable in Console.app.

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
