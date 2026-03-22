# iStocks — Codebase Analysis & Architecture Reference

> **Last updated:** March 2026
> **Analyzed by:** Senior iOS Architect review
> **Purpose:** Persistent architectural reference for full project context without re-crawling source files.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Technology Stack](#2-technology-stack)
3. [Architecture](#3-architecture)
4. [Project Structure](#4-project-structure)
5. [Data Flow & App Modes](#5-data-flow--app-modes)
6. [Key Components Deep Dive](#6-key-components-deep-dive)
7. [Dependency Injection](#7-dependency-injection)
8. [Persistence Layer](#8-persistence-layer)
9. [Networking Layer](#9-networking-layer)
10. [State Management](#10-state-management)
11. [Error Handling](#11-error-handling)
12. [Testing Strategy](#12-testing-strategy)
13. [Code Quality Findings](#13-code-quality-findings)
14. [Security Considerations](#14-security-considerations)
15. [Performance Notes](#15-performance-notes)
16. [Improvement Roadmap](#16-improvement-roadmap)
17. [File-Level Reference](#17-file-level-reference)

---

## 1. Project Overview

**iStocks** is a stock market watchlist iOS application built entirely with Swift and SwiftUI. Core capabilities:

- Create and manage multiple named watchlists
- Add/remove stocks per watchlist (capped at `AppConstants.maxStocksPerWatchlist`)
- View real-time or REST-polled price updates per stock
- Track price change percentage and direction (profit/loss color coding)
- Persist watchlists and stocks locally via SwiftData
- Switch between Mock, REST API, and WebSocket data modes

**Status:** Active development. Dashboard, Portfolio, Orders, and Positions tabs are placeholder stubs. Only the Watchlist feature is fully implemented.

**External APIs:**
- **TwelveData** — REST stock quotes and prices
- **Finnhub** — WebSocket real-time price streaming

**No third-party libraries.** Pure Apple frameworks only.

---

## 2. Technology Stack

| Technology | Usage |
|---|---|
| **Swift** | Primary language |
| **SwiftUI** | 100% UI — no UIKit |
| **SwiftData** | Local persistence (replaces CoreData) |
| **Combine** | Reactive data flow, primary async paradigm |
| **async/await** | Available in NetworkClient but underutilized |
| **URLSession** | HTTP networking |
| **URLSessionWebSocketTask** | WebSocket connection (Finnhub) |
| **XCTest / Swift Testing** | Unit + integration tests |

---

## 3. Architecture

### Pattern: Clean Architecture + MVVM

```
┌─────────────────────────────────────────────┐
│             Presentation Layer               │
│   SwiftUI Views ←→ ViewModels (@Published)  │
└────────────────────┬────────────────────────┘
                     │ Use Cases (protocols)
┌────────────────────▼────────────────────────┐
│               Domain Layer                   │
│   Entities (Stock, Watchlist)               │
│   Use Cases (Observe*, CRUD)                │
│   Repository Protocols                       │
└────────────────────┬────────────────────────┘
                     │ Repository implementations
┌────────────────────▼────────────────────────┐
│                Data Layer                    │
│   Repositories (REST, WebSocket, Mock)      │
│   Data Sources (Remote, Local, WebSocket)   │
│   DTOs + Mappers                            │
└─────────────────────────────────────────────┘
```

### Architecture Compliance: Good

The project genuinely follows Clean Architecture with real separation between layers. Domain entities don't import SwiftData or networking. Use cases depend only on repository protocols, not implementations. ViewModels don't touch network or persistence directly.

---

## 4. Project Structure

```
iStocks/
├── App/
│   └── iStocksApp.swift              # @main entry, SwiftData container, TabBarContainer
│
├── Core/
│   ├── Constants/
│   │   ├── AppConstants.swift        # maxStocksPerWatchlist, maxWatchlists
│   │   ├── AppFonts.swift            # Inter font family constants
│   │   ├── AppSizes.swift            # Tab label size (minimal — needs expansion)
│   │   └── AppStrings.swift          # Localized string keys (partially used)
│   ├── Extensions/
│   │   ├── Array+Extensions.swift    # safe subscript, chunked, uniqued(by:)
│   │   ├── Color+Extensions.swift    # .profitGreen, .lossRed
│   │   ├── Double+Extensions.swift   # .currencyFormatted
│   │   └── Font+Extensions.swift     # Inter font convenience
│   └── Utilities/
│       ├── AppConfiguration.swift    # Build-time config, WatchlistAppMode selection
│       ├── AppError.swift            # Top-level error enum (network/api/persistence/etc.)
│       ├── MarketHoursHelper.swift   # NYSE market hours check (EDT hardcoded)
│       └── SecureAPIKeyManager.swift # Reads API keys from env vars / Info.plist
│
├── Features/
│   ├── Watchlist/                    # ← Only fully-implemented feature
│   │   ├── Presentation/
│   │   │   ├── DI/
│   │   │   │   └── WatchlistDIContainer.swift       # Manual DI factory (static cached)
│   │   │   ├── View/
│   │   │   │   ├── SearchBar/
│   │   │   │   │   └── SearchBarView.swift
│   │   │   │   └── Watchlist/
│   │   │   │       ├── WatchListTabView/
│   │   │   │       │   ├── WatchlistTabContainerView.swift  # Top-level container
│   │   │   │       │   ├── WatchlistTabView.swift           # Tab bar with underline animation
│   │   │   │       │   └── BatchProgressView.swift          # REST loading progress bar
│   │   │   │       ├── WatchlistRow/
│   │   │   │       │   ├── WatchlistRow.swift               # Single stock row
│   │   │   │       │   └── WatchlistViewModelProvider.swift # ViewModel cache + bridge
│   │   │   │       ├── EditWatchlist/
│   │   │   │       │   ├── EditAllWatchlistsView.swift      # CRUD list of watchlists
│   │   │   │       │   ├── EditSingleWatchlistView.swift    # Rename + stock picker
│   │   │   │       │   └── StockPickerView.swift            # Search + toggle stocks
│   │   │   │       ├── WatchlistErrorAlert/
│   │   │   │       │   ├── StockValidationError.swift
│   │   │   │       │   ├── WatchlistErrorView.swift
│   │   │   │       │   └── WatchlistValidationError.swift
│   │   │   │       ├── WatchlistLoading/
│   │   │   │       │   ├── WatchlistLoadedView.swift        # Stock list display
│   │   │   │       │   ├── EmptyStateView.swift
│   │   │   │       │   └── LoadingOverlay.swift
│   │   │   │       └── EmptyWatchlistView.swift
│   │   │   └── ViewModel/
│   │   │       ├── WatchlistsViewModel.swift        # Parent: manages all watchlists
│   │   │       ├── WatchlistViewModel.swift         # Child: manages one watchlist
│   │   │       ├── EditWatchlistViewModel.swift     # Edit sheet logic + validation
│   │   │       └── WatchlistsViewModelTestable.swift # Protocol for testability
│   │   ├── Domain/
│   │   │   ├── Entities/
│   │   │   │   ├── Stock.swift        # Core domain model (symbol, name, price, change%)
│   │   │   │   └── Watchlist.swift    # Core domain model (id, name, [Stock])
│   │   │   ├── Repositories/
│   │   │   │   └── WatchlistRepository.swift  # Protocol: observe streams
│   │   │   ├── UseCases/
│   │   │   │   ├── ObserveMockStocksUseCase.swift
│   │   │   │   ├── ObserveStockPricesUseCase.swift
│   │   │   │   ├── ObserveStocksBySymbolUseCase.swift
│   │   │   │   ├── ObserveTop50StocksUseCase.swift
│   │   │   │   ├── ObserveWatchlistStocksUseCase.swift  # Returns Empty() — deprecated
│   │   │   │   └── WatchlistUseCases.swift              # Aggregation struct
│   │   │   └── Shared/
│   │   │       └── BatchProgress.swift   # Progress tracking for REST batch loads
│   │   └── Data/
│   │       ├── DataSources/
│   │       │   ├── Local/
│   │       │   │   ├── StockEntity.swift            # SwiftData @Model
│   │       │   │   ├── WatchlistEntity.swift        # SwiftData @Model
│   │       │   │   └── WatchlistPersistenceService.swift
│   │       │   ├── Remote/
│   │       │   │   ├── Services/
│   │       │   │   │   ├── StockRemoteDataSource.swift
│   │       │   │   │   ├── QuoteEndPoint.swift      # TwelveData quote endpoint
│   │       │   │   │   ├── PriceEndPoint.swift      # TwelveData price endpoint
│   │       │   │   │   ├── NYSETop50Symbols.swift   # Hardcoded 50 NYSE symbols
│   │       │   │   │   └── Meta/
│   │       │   │   │       └── StockMetaData.swift  # Static symbol → name mapping
│   │       │   │   └── Error/
│   │       │   │       ├── RepositoryError.swift
│   │       │   │       └── TwelveDataAPIError.swift
│   │       │   ├── WebSocket/
│   │       │   │   ├── FinnhubWebSocketClient.swift    # Singleton WSS client
│   │       │   │   └── ConnectionRetryManager.swift    # Exponential backoff
│   │       │   └── Mock/
│   │       │       ├── MockStockData.swift             # Static test fixtures
│   │       │       └── MockStockStreamingService.swift # Simulated price fluctuations
│   │       ├── DTOs/
│   │       │   ├── StockDTO.swift          # TwelveData quote response
│   │       │   ├── StockFinnPriceDTO.swift # Finnhub WebSocket trade message
│   │       │   ├── StockPriceDTO.swift     # TwelveData price response
│   │       │   └── StockQuoteDTO.swift     # TwelveData quote fields
│   │       ├── Mappers/
│   │       │   ├── FinnhubResponseMapper.swift
│   │       │   ├── PriceResponseMapper.swift
│   │       │   ├── QuoteResponseMapper.swift
│   │       │   └── StockResponseWrapper.swift
│   │       └── Repositories/
│   │           ├── RestStockRepositoryImpl.swift        # TwelveData REST
│   │           ├── WebSocketStockRepositoryImpl.swift   # Finnhub WebSocket
│   │           └── MockStockRepositoryImpl.swift        # Test/preview data
│   │
│   ├── Dashboard/
│   │   └── DashboardView.swift       # STUB — placeholder only
│   ├── Portfolio/
│   │   └── PortfolioView.swift       # STUB — placeholder only
│   ├── Orders/
│   │   └── OrderView.swift           # STUB — placeholder only
│   ├── Positions/
│   │   └── BidsView.swift            # STUB — placeholder only
│   └── Settings/
│       └── SettingsView.swift        # STUB — minimal (API key entry)
│
├── Shared/
│   ├── Networking/
│   │   ├── Endpoint.swift            # Value type: path, method, queryItems
│   │   ├── NetworkClient.swift       # Protocol (Combine + async/await)
│   │   ├── NetworkConstants.swift    # Base URLs
│   │   ├── NetworkError.swift        # HTTP-level errors
│   │   └── URLSessionNetworkClient.swift  # Concrete URLSession impl
│   ├── Components/
│   │   ├── Alert/
│   │   │   ├── GlobalAlertPresenter.swift     # Static presenter helper
│   │   │   ├── LocalizedAlertConvertible.swift # Protocol for typed alerts
│   │   │   ├── SharedAlertManager.swift        # @ObservableObject singleton
│   │   │   └── SharedAlertView.swift           # SwiftUI alert modifier
│   │   └── Logging/
│   │       └── Logger.swift          # Wraps os.Logger with categories
│   └── TabBar/
│       ├── CustomTabBar.swift        # Custom bottom tab bar (no system TabView)
│       ├── TabBarContainer.swift     # ZStack: content + custom tab bar
│       ├── TabItem.swift             # Individual tab item view
│       ├── TabRouterView.swift       # Routes tab enum → feature view
│       └── TabViewEnum.swift         # Enum: watchlist/orders/portfolio/bids/settings
│
└── Resources/
    ├── Assets.xcassets
    ├── Info.plist
    └── Fonts/                        # Inter 28pt family (8 weights)
```

---

## 5. Data Flow & App Modes

### Three Operating Modes (set via `AppConfiguration.watchlistMode`)

```swift
enum WatchlistAppMode {
    case mock       // DEBUG default — no API calls
    case restAPI    // RELEASE default — TwelveData REST
    case webSocket  // Opt-in — Finnhub WebSocket
}
```

**Mode selection logic** (`AppConfiguration.swift`):
```swift
#if DEBUG
return ProcessInfo.processInfo.environment["WATCHLIST_MODE"]
    .flatMap { WatchlistAppMode(rawValue: $0) } ?? .mock
#else
return .restAPI
#endif
```

### Mock Mode Flow
```
MockStockStreamingService
    → timer-based price fluctuations (async stream)
    → MockStockRepositoryImpl.observeMockStocks()
    → ObserveMockStocksUseCase
    → WatchlistsViewModel.loadStocks()
    → WatchlistViewModel.replaceStocks()
    → SwiftUI re-render
```

### REST Mode Flow
```
TwelveData API (HTTPS)
    → URLSessionNetworkClient.request()
    → StockRemoteDataSource.fetchBatch()
    → RestStockRepositoryImpl (batches of 8, with BatchProgress)
    → ObserveTop50StocksUseCase (AnyPublisher<[Stock], Never>)
    → WatchlistsViewModel.loadStocks()
    → WatchlistPersistenceService.saveAllStocks() [side-effect]
    → WatchlistViewModel.replaceStocks()
    → SwiftUI re-render
```

### WebSocket Mode Flow
```
Finnhub WSS
    → FinnhubWebSocketClient (singleton)
    → collect(for: .seconds(1)) [batching window]
    → FinnhubResponseMapper → [Stock]
    → WebSocketStockRepositoryImpl.observeLiveWebSocket()
    → ObserveStockPricesUseCase
    → WatchlistsViewModel.updatePrices()
    → WatchlistViewModel.replaceStocks(priceOnly: true)
    → SwiftUI re-render (price cells only)
```

### Price-Only vs Structural Update Distinction

A key optimization: `WatchlistViewModel` has an `isPriceOnlyUpdate: Bool` flag. When set, `WatchlistViewModelProvider` filters out the `$watchlist` published change to avoid triggering full watchlist reloads just for price ticks.

**Risk:** This flag is a non-atomic `Bool` set and read without synchronization. While unlikely to cause issues in current single-threaded Combine flows, it's a latent data race.

---

## 6. Key Components Deep Dive

### WatchlistsViewModel (Parent ViewModel)
**File:** `Features/Watchlist/Presentation/ViewModel/WatchlistsViewModel.swift`

Responsibilities:
- Owns `[Watchlist]` state and `selectedIndex`
- Orchestrates use case subscriptions based on app mode
- Handles watchlist CRUD (add, delete, rename, reorder)
- Distributes price updates to all child `WatchlistViewModel`s via `ViewModelProvider`
- Persists changes via `WatchlistPersistenceService`

Key properties:
```swift
@Published var watchlists: [Watchlist]
@Published var selectedIndex: Int
@Published var isLoading: Bool
@Published var batchProgress: BatchProgress?
var viewModelProvider: WatchlistViewModelProvider
```

**Issue:** ViewModel directly holds a reference to `WatchlistPersistenceService`. This couples the VM to the Data layer, bypassing the repository/use case abstraction for persistence operations.

---

### WatchlistViewModel (Child ViewModel)
**File:** `Features/Watchlist/Presentation/ViewModel/WatchlistViewModel.swift`

Responsibilities:
- Owns stocks for a single watchlist
- Publishes `watchlistStructuralUpdate: PassthroughSubject` for add/remove/rename events
- Exposes filtered/sorted stocks for display
- Manages `isPriceOnlyUpdate` flag for update classification

---

### WatchlistViewModelProvider
**File:** `Features/Watchlist/Presentation/View/Watchlist/WatchlistRow/WatchlistViewModelProvider.swift`

Acts as a ViewModel factory + cache + event bridge:
- Caches `[UUID: WatchlistViewModel]` to prevent recreation on tab switches
- Subscribes to each child VM's structural updates
- Forwards changes upstream via `watchlistDidUpdate: PassthroughSubject<Watchlist, Never>`
- Merges `$watchlist` (Combine) + `watchlistStructuralUpdate` (PassthroughSubject)

**Note:** `WatchlistViewModelProvider` is a protocol, with `DefaultWatchlistViewModelProvider` as the concrete implementation. Good for testability.

---

### WatchlistDIContainer
**File:** `Features/Watchlist/Presentation/DI/WatchlistDIContainer.swift`

Manual DI via static factory methods. Uses static cached instances:
```swift
static var cachedUseCases: WatchlistUseCases?
static func makeWatchlistUseCases(context: ModelContext) -> WatchlistUseCases
```

**Issue:** Static cached singletons make it harder to reset state between tests. A proper DI container or environment-based injection would be cleaner.

---

### FinnhubWebSocketClient
**File:** `Features/Watchlist/Data/DataSources/WebSocket/FinnhubWebSocketClient.swift`

- Singleton pattern (`shared`)
- Manages `URLSessionWebSocketTask`
- Subscribe/unsubscribe to symbols via JSON messages
- `ConnectionRetryManager` handles exponential backoff on disconnect
- Message parsing into `StockFinnPriceDTO` → `[Stock]`
- 1-second collect window to batch price updates

---

### WatchlistUseCases (Aggregation Struct)
**File:** `Features/Watchlist/Domain/UseCases/WatchlistUseCases.swift`

Bundles all use cases into a single injectable struct:
```swift
struct WatchlistUseCases {
    let observeMock: ObserveMockStocksUseCase
    let observeTop50: ObserveTop50StocksUseCase
    let observeLiveWebSocket: ObserveStockPricesUseCase
    let observeBySymbol: ObserveStocksBySymbolUseCase
    // persistence use cases...
}
```
Good pattern — avoids constructor explosion in ViewModels.

---

## 7. Dependency Injection

### Current Approach: Manual DI via `WatchlistDIContainer`

```
iStocksApp
    └── TabBarContainer
            └── WatchlistTabContainerView
                    └── WatchlistsViewModel(useCases: WatchlistDIContainer.makeWatchlistUseCases(context:))
```

**SwiftData ModelContext** is passed from the `@Environment` in the view layer down to the DI container. This is acceptable but means the DI container has a direct dependency on SwiftData.

### Problems:
1. `WatchlistDIContainer` uses static stored state — hard to replace in tests
2. No environment-based injection for cross-cutting concerns (logging, config)
3. `WatchlistsViewModel` initializer is concrete — not behind a protocol in production path (though `WatchlistsViewModelTestable` protocol exists)

### What's Working Well:
- `WatchlistViewModelProvider` is protocol-based — easily mockable
- `NetworkClient` is protocol-based — easily mockable
- `WatchlistRepository` is protocol-based — three swappable implementations exist

---

## 8. Persistence Layer

**Technology:** SwiftData (iOS 17+)

### Entities

**`WatchlistEntity`** (`@Model`):
- `id: UUID`
- `name: String`
- `stockSymbols: [String]` (stores only symbols, not full Stock objects)
- `createdAt: Date`

**`StockEntity`** (`@Model`):
- `symbol: String`
- `name: String`
- `price: Double`
- `changePercent: Double`
- etc.

### WatchlistPersistenceService
Wraps SwiftData `ModelContext` with domain-level operations:
- `saveWatchlists([Watchlist])`
- `loadWatchlists() -> [Watchlist]`
- `deleteWatchlist(Watchlist)`
- `saveAllStocks([Stock])`
- `loadAllStocks() -> [Stock]`
- `clearAllStocks()`

**Known Issue:** `saveAllStocks` calls `clearAllStocks()` first every time — this is a full replace strategy (not a merge/upsert). Acceptable for current scale but inefficient for large stock lists.

### SwiftData Container (App Entry Point)
```swift
.modelContainer(for: [WatchlistEntity.self, StockEntity.self])
```

---

## 9. Networking Layer

### NetworkClient Protocol
```swift
protocol NetworkClient {
    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, Error>
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}
```

Both Combine and async/await variants available. In practice, only the Combine version is used throughout the codebase.

### Endpoint
```swift
struct Endpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
}
```

### URLSessionNetworkClient
- Validates HTTP status (200-299)
- Maps 429 → `.rateLimited`, 401 → `.unauthorized`, 500+ → `.serverError`
- Prints raw JSON in DEBUG mode
- Thread-safe via Combine's `receive(on:)`

### API Key Management
`SecureAPIKeyManager` reads keys from:
1. Environment variables (preferred for CI/development)
2. `Info.plist` fallback (for device builds)

**Security Note:** API keys should NOT be committed to Info.plist in a public repo. Keys should use `.xcconfig` files excluded from version control.

### Endpoints
- **TwelveData Quote:** `GET /quote?symbol=AAPL&apikey=...`
- **TwelveData Price:** `GET /price?symbol=AAPL&apikey=...`
- **Finnhub WebSocket:** `wss://ws.finnhub.io?token=...`

---

## 10. State Management

### Primary Pattern: `@Published` + Combine

```swift
// WatchlistsViewModel
@Published var watchlists: [Watchlist] = []
@Published var selectedIndex: Int = 0
@Published var isLoading: Bool = false
@Published var batchProgress: BatchProgress?
@Published var errorMessage: String?
```

Views observe via `.onReceive()` or direct `@ObservedObject` bindings.

### Event Subjects
```swift
// Structural watchlist changes (add stock, rename, etc.)
var watchlistStructuralUpdate = PassthroughSubject<Watchlist, Never>()

// Price-only updates from live data
var priceUpdate = PassthroughSubject<[Stock], Never>()

// Parent notification of any watchlist change
var watchlistDidUpdate = PassthroughSubject<Watchlist, Never>()
```

### Cancellables Management
Both `WatchlistsViewModel` and `WatchlistViewModelProvider` maintain `Set<AnyCancellable>` and `[UUID: AnyCancellable]` dictionaries for proper cleanup.

---

## 11. Error Handling

### Error Hierarchy

```swift
enum AppError: LocalizedError {
    case network(NetworkError)
    case api(message: String)
    case persistence(PersistenceError)
    case validation(ValidationError)
    case webSocket(WebSocketError)
    case configuration(ConfigurationError)
    case unknown(Error)
}
```

Each case provides:
- `errorDescription` — user-facing message
- `failureReason` — technical detail
- `recoverySuggestion` — actionable next step

### Alert System
`SharedAlertManager` is a singleton `@ObservableObject` injected as an `@EnvironmentObject`. Views call `SharedAlertManager.shared.show(...)` to display alerts.

**Issue:** Two parallel alert presentation patterns exist:
1. `SharedAlertManager.shared.show(error:)` — environment-based
2. `GlobalAlertPresenter.present(...)` — static method

These can conflict. Should consolidate to one.

### Validation Errors
Separate typed errors for different validation contexts:
- `WatchlistValidationError` — name empty, duplicate, too many watchlists
- `StockValidationError` — duplicate stock, max stocks exceeded

---

## 12. Testing Strategy

### Test Targets
- `iStocksTests` — Unit tests (`WatchlistModuleTests/`)
- `iStocksIntegrationTests` — Integration tests

### What's Tested
- `EditWatchlistViewModel` — validation logic, add/remove stocks
- `AppConstants` — configuration values
- Array extension helpers

### Test Infrastructure
- `MockStockRepositoryImpl` — in-tree mock, reusable for tests
- `FailingNetworkClient` — tests error propagation
- `Array+Extensions` test helper in `WatchlistModuleTests/Helpers/`
- `WatchlistsViewModelTestable` protocol — abstracts ViewModel for testing

### What's Missing (Testing Gaps)
- `WatchlistsViewModel` has no unit tests
- `WatchlistViewModel` has no unit tests
- `RestStockRepositoryImpl` batch logic untested
- `WebSocketStockRepositoryImpl` has no tests
- `WatchlistPersistenceService` has no tests
- No snapshot tests for SwiftUI views
- No UI automation tests

---

## 13. Code Quality Findings

### Issues by Severity

#### HIGH
1. **`WatchlistsViewModel` directly calls `WatchlistPersistenceService`**
   - File: `WatchlistsViewModel.swift`
   - Breaks Clean Architecture — ViewModel should only touch use cases, not data layer
   - Fix: Wrap persistence operations in use cases

2. **Static cached DI container makes test isolation impossible**
   - File: `WatchlistDIContainer.swift`
   - `static var cachedUseCases` persists across test runs
   - Fix: Use instance-based DI or a proper DI container (e.g., `@Environment` keys)

#### MEDIUM
3. **`isPriceOnlyUpdate` flag is not thread-safe**
   - File: `WatchlistViewModel.swift`, `WatchlistViewModelProvider.swift`
   - Non-atomic Bool set and read potentially across actors
   - Fix: Mark ViewModel as `@MainActor` (recommended anyway for UI state)

4. **Dual alert presentation system**
   - Files: `SharedAlertManager.swift`, `GlobalAlertPresenter.swift`
   - Two patterns for showing alerts — can cause state inconsistency
   - Fix: Consolidate to `SharedAlertManager` only

5. **`ObserveWatchlistStocksUseCaseImpl` returns `Empty()`**
   - File: `ObserveWatchlistStocksUseCase.swift`
   - Dead code masquerading as a use case — confusing for new devs
   - Fix: Remove or properly implement

6. **`Double.currencyFormatted` creates a new `NumberFormatter` on every call**
   - File: `Double+Extensions.swift`
   - `NumberFormatter` is expensive to allocate — this will be called per-stock per-render
   - Fix: Use a static cached formatter

#### LOW
7. **`MarketHoursHelper` hardcodes EDT timezone**
   - File: `MarketHoursHelper.swift`
   - Does not correctly handle DST transitions (EDT vs EST)
   - Fix: Use `TimeZone(identifier: "America/New_York")`

8. **`AppStrings.tabNames` enum uses lowercase naming**
   - File: `AppStrings.swift`
   - `enum tabNames` should be `enum TabNames` per Swift conventions
   - Same issue with `tabImageNames`

9. **`Color+Extensions.swift` file is named `Untitled.swift` in header comment**
   - Minor — leftover from creation

10. **`AppSizes` is nearly empty**
    - File: `AppSizes.swift`
    - Only contains `Tab.labelSize = 12`. Many hardcoded sizes exist in views.
    - Fix: Consolidate all magic numbers here

11. **Commented-out code in `WatchlistViewModelProvider`**
    - Lines 65-67: `//if existing.watchlist != watchlist {` — dead guard
    - Clean up before portfolio presentation

12. **`WatchlistPersistenceService.saveAllStocks` uses full-replace strategy**
    - Calls `clearAllStocks()` then re-inserts everything on every REST refresh
    - Inefficient for large datasets; could lose data if save fails mid-operation

### Code Smells
- `NYSETop50Symbols.swift` contains a 50-element hardcoded array — should be a JSON/plist resource
- `StockMetaData.swift` contains a static dictionary for symbol→name mapping — fine for now, doesn't scale
- `WatchlistTabView` uses `ScrollViewReader` + `matchedGeometryEffect` for tab underline animation — correct approach but complex; could be simplified

---

## 14. Security Considerations

### API Key Handling
- Keys are read from environment variables (good) and Info.plist fallback (risky if plist is committed)
- `SecureAPIKeyManager` does NOT use Keychain — acceptable for API keys that can be rotated, but Keychain would be more secure for user-specific tokens
- **Action Required:** Ensure `Info.plist` API key values are not committed to version control. Use `.xcconfig` files with `.gitignore` coverage.

### Network Security
- All network calls use HTTPS (`https://`, `wss://`) — correct
- No certificate pinning — acceptable for portfolio apps, required for production financial apps
- No request signing or token refresh logic

### Data Security
- SwiftData stores plaintext — acceptable for stock watchlist data (not sensitive)
- No biometric authentication

---

## 15. Performance Notes

### Good
- Price update batching (1-second WebSocket collect window) prevents UI thrashing
- `WatchlistViewModel` cache prevents ViewModel recreation on tab switch
- `isPriceOnlyUpdate` flag prevents full structural reloads for price ticks
- `Array.chunked(into:)` used for REST batch requests (8 stocks/batch)

### Needs Improvement
- `Double.currencyFormatted` allocates `NumberFormatter` on every call (every stock row render)
- `WatchlistPersistenceService.saveAllStocks` does full replace on every REST refresh
- No lazy loading for large watchlists (all stocks rendered at once in `ScrollView`)
- `StockMetaData` static dictionary lookup on every stock creation — fine at 50 stocks, not at 500

---

## 16. Improvement Roadmap

### Priority 1 — Architecture / Correctness
- [ ] Mark all ViewModels with `@MainActor` to enforce main-thread UI updates
- [ ] Move persistence calls out of `WatchlistsViewModel` into dedicated use cases
- [ ] Replace static DI container with instance-based or `@Environment` key injection
- [ ] Remove or implement `ObserveWatchlistStocksUseCaseImpl` (currently returns `Empty()`)
- [ ] Consolidate dual alert system to `SharedAlertManager` only

### Priority 2 — Swift Best Practices
- [ ] Cache `NumberFormatter` in `Double+Extensions.swift`
- [ ] Fix `MarketHoursHelper` timezone to use `"America/New_York"` identifier
- [ ] Migrate `NetworkClient` callers from Combine to async/await (modern Swift)
- [ ] Fix naming convention: `tabNames` → `TabNames`, `tabImageNames` → `TabImageNames`
- [ ] Add `@MainActor` to `WatchlistViewModel` and `WatchlistsViewModel`

### Priority 3 — Testing
- [ ] Add unit tests for `WatchlistsViewModel`
- [ ] Add unit tests for `WatchlistViewModel`
- [ ] Add unit tests for `WatchlistPersistenceService`
- [ ] Add integration tests for `RestStockRepositoryImpl` batch loading
- [ ] Add snapshot tests for key views (WatchlistRow, BatchProgressView)

### Priority 4 — Code Cleanup
- [ ] Remove commented-out guard in `WatchlistViewModelProvider.viewModel(for:)`
- [ ] Move NYSE symbols to a JSON/plist resource instead of Swift source
- [ ] Expand `AppSizes` to capture all hardcoded layout values
- [ ] Remove verbose logging marked as "too verbose" in comments

### Priority 5 — Portfolio / GitHub Quality
- [ ] Write `README.md` with screenshots, architecture diagram, setup instructions
- [ ] Add architecture diagram (draw.io or Mermaid in README)
- [ ] Add `CONTRIBUTING.md`
- [ ] Tag v1.0 release when Watchlist feature is stable
- [ ] Add GitHub Actions CI (build + test on push)
- [ ] Add `CHANGELOG.md`

---

## 17. File-Level Reference

Quick lookup table for any file in the project:

| File | Layer | Purpose |
|---|---|---|
| `iStocksApp.swift` | App | Entry point, SwiftData container |
| `AppConfiguration.swift` | Core | Build config, mode selection |
| `AppConstants.swift` | Core | maxStocksPerWatchlist=10, maxWatchlists=5 |
| `AppError.swift` | Core | Top-level error enum |
| `SecureAPIKeyManager.swift` | Core | Reads Finnhub/TwelveData API keys |
| `MarketHoursHelper.swift` | Core | NYSE hours check (EDT — has DST bug) |
| `WatchlistDIContainer.swift` | Presentation/DI | Manual DI factory (static cached) |
| `WatchlistsViewModel.swift` | Presentation | Parent VM — all watchlists |
| `WatchlistViewModel.swift` | Presentation | Child VM — single watchlist |
| `EditWatchlistViewModel.swift` | Presentation | Edit sheet + validation |
| `WatchlistViewModelProvider.swift` | Presentation | ViewModel cache + event bridge |
| `WatchlistsViewModelTestable.swift` | Presentation | Protocol for ViewModel testability |
| `WatchlistTabContainerView.swift` | View | Top-level watchlist container |
| `WatchlistTabView.swift` | View | Animated tab bar with underline |
| `WatchlistLoadedView.swift` | View | Stock list display |
| `WatchlistRow.swift` | View | Single stock row |
| `BatchProgressView.swift` | View | REST loading progress bar |
| `EditAllWatchlistsView.swift` | View | CRUD list of watchlists |
| `EditSingleWatchlistView.swift` | View | Rename + stock picker sheet |
| `StockPickerView.swift` | View | Search + toggle stocks |
| `Stock.swift` | Domain | Core entity: symbol, name, price, changePercent |
| `Watchlist.swift` | Domain | Core entity: id, name, [Stock] |
| `WatchlistRepository.swift` | Domain | Repository protocol |
| `WatchlistUseCases.swift` | Domain | Use case aggregation struct |
| `ObserveMockStocksUseCase.swift` | Domain | Mock data use case |
| `ObserveTop50StocksUseCase.swift` | Domain | REST data use case |
| `ObserveStockPricesUseCase.swift` | Domain | WebSocket use case |
| `ObserveWatchlistStocksUseCase.swift` | Domain | DEAD CODE — returns Empty() |
| `BatchProgress.swift` | Domain | Progress value type |
| `RestStockRepositoryImpl.swift` | Data | TwelveData REST (batch 8/req) |
| `WebSocketStockRepositoryImpl.swift` | Data | Finnhub WebSocket |
| `MockStockRepositoryImpl.swift` | Data | Test/preview fake data |
| `WatchlistPersistenceService.swift` | Data | SwiftData CRUD wrapper |
| `WatchlistEntity.swift` | Data | SwiftData @Model for Watchlist |
| `StockEntity.swift` | Data | SwiftData @Model for Stock |
| `FinnhubWebSocketClient.swift` | Data | Singleton WSS client |
| `ConnectionRetryManager.swift` | Data | Exponential backoff |
| `StockRemoteDataSource.swift` | Data | REST fetch orchestration |
| `StockMetaData.swift` | Data | Static symbol→name dictionary |
| `NYSETop50Symbols.swift` | Data | Hardcoded 50 NYSE symbols |
| `StockDTO.swift` | Data | TwelveData quote DTO |
| `StockFinnPriceDTO.swift` | Data | Finnhub trade message DTO |
| `StockPriceDTO.swift` | Data | TwelveData price DTO |
| `StockQuoteDTO.swift` | Data | TwelveData quote fields DTO |
| `FinnhubResponseMapper.swift` | Data | Finnhub DTO → Domain |
| `PriceResponseMapper.swift` | Data | TwelveData price → Domain |
| `QuoteResponseMapper.swift` | Data | TwelveData quote → Domain |
| `StockResponseWrapper.swift` | Data | Batch response wrapper |
| `NetworkClient.swift` | Shared | Protocol (Combine + async) |
| `URLSessionNetworkClient.swift` | Shared | Concrete URLSession impl |
| `Endpoint.swift` | Shared | Request value type |
| `NetworkError.swift` | Shared | HTTP-level error enum |
| `NetworkConstants.swift` | Shared | Base URLs |
| `SharedAlertManager.swift` | Shared | Alert singleton (@EnvironmentObject) |
| `GlobalAlertPresenter.swift` | Shared | Static alert helper (DUPLICATE — remove) |
| `Logger.swift` | Shared | os.Logger wrapper with categories |
| `CustomTabBar.swift` | Shared | Custom bottom tab bar UI |
| `TabBarContainer.swift` | Shared | ZStack content + tab bar |
| `TabRouterView.swift` | Shared | Tab enum → feature view router |
| `TabViewEnum.swift` | Shared | Tab cases: watchlist/orders/portfolio/bids/settings |

---

*End of analysis. Update this document when significant architectural changes are made.*
