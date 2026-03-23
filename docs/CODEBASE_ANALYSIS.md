# iStocks — Codebase Analysis & Architecture Reference

> **Last updated:** March 22, 2026
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
13. [Accessibility (VoiceOver)](#13-accessibility-voiceover)
14. [Stock Research Module (WKWebView)](#14-stock-research-module-wkwebview)
15. [Code Quality Findings](#15-code-quality-findings)
16. [Security Considerations](#16-security-considerations)
17. [Performance Notes](#17-performance-notes)
18. [Improvement Roadmap](#18-improvement-roadmap)
19. [File-Level Reference](#19-file-level-reference)

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
| **WebKit / WKWebView** | Stock Research web view (UIViewRepresentable) |

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
│   Repositories (REST, WebSocket, GraphQL, Mock) │
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
│   ├── Accessibility/
│   │   └── AccessibilityIdentifiers.swift  # Centralized AccessibilityID enum for UI testing
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
│   ├── Research/                     # Stock Research — WKWebView integration
│   │   ├── Domain/
│   │   │   └── Entities/
│   │   │       ├── WebBookmark.swift              # Bookmark model (Identifiable, Codable)
│   │   │       └── WebNavigationState.swift       # Navigation state value type
│   │   └── Presentation/
│   │       ├── View/
│   │       │   ├── StockResearchView.swift        # Main research view with toolbar
│   │       │   ├── StockWebView.swift             # UIViewRepresentable WKWebView wrapper
│   │       │   ├── WebViewToolbar.swift           # Back/forward/reload/bookmark toolbar
│   │       │   └── JavaScriptBridge.swift          # JS↔Swift message handlers + scripts
│   │       └── ViewModel/
│   │           └── StockResearchViewModel.swift   # Navigation, bookmarks, JS callbacks
│   │
│   ├── Watchlist/                    # Primary fully-implemented feature
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
│   │       │   │   │   ├── Meta/
│   │       │   │   │   │   └── StockMetaData.swift  # Static symbol → name mapping
│   │       │   │   │   └── GraphQL/
│   │       │   │   │       ├── GraphQLClient.swift        # Lightweight GraphQL client (URLSession)
│   │       │   │   │       ├── GraphQLQuery.swift          # Query struct + variable encoding
│   │       │   │   │       ├── GraphQLError.swift          # GraphQL-specific error types
│   │       │   │   │       ├── StockGraphQLQueries.swift   # Predefined stock queries
│   │       │   │   │       └── StockGraphQLDataSource.swift # GraphQL data source impl
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
│   │       │   ├── StockQuoteDTO.swift     # TwelveData quote fields
│   │       │   └── GraphQL/
│   │       │       └── StockGraphQLDTO.swift  # GraphQL response DTOs
│   │       ├── Mappers/
│   │       │   ├── FinnhubResponseMapper.swift
│   │       │   ├── PriceResponseMapper.swift
│   │       │   ├── QuoteResponseMapper.swift
│   │       │   ├── StockResponseWrapper.swift
│   │       │   └── GraphQLResponseMapper.swift  # GraphQL DTO → Domain mapper
│   │       └── Repositories/
│   │           ├── RestStockRepositoryImpl.swift        # TwelveData REST
│   │           ├── WebSocketStockRepositoryImpl.swift   # Finnhub WebSocket
│   │           ├── GraphQLStockRepositoryImpl.swift     # GraphQL data source
│   │           └── MockStockRepositoryImpl.swift        # Test/preview data
│   │
│   ├── Dashboard/
│   │   └── DashboardView.swift       # STUB — placeholder only
│   ├── Portfolio/
│   │   └── PortfolioView.swift       # STUB — placeholder only
│   ├── Orders/
│   │   └── OrderView.swift           # STUB — placeholder only
│   └── Settings/
│       └── SettingsView.swift        # STUB — minimal (API key entry)
│
├── Shared/
│   ├── Networking/
│   │   ├── Endpoint.swift            # Value type: path, method, queryItems, httpBody
│   │   ├── NetworkClient.swift       # Protocol (Combine + async/await)
│   │   ├── NetworkConstants.swift    # Base URLs (REST + GraphQL)
│   │   ├── NetworkError.swift        # HTTP-level errors
│   │   └── URLSessionNetworkClient.swift  # Concrete URLSession impl (GET + POST)
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
│       └── TabViewEnum.swift         # Enum: watchlist/orders/portfolio/research/settings
│
└── Resources/
    ├── Assets.xcassets
    ├── Info.plist
    └── Fonts/                        # Inter 28pt family (8 weights)
```

---

## 5. Data Flow & App Modes

### Four Operating Modes (set via `AppConfiguration.watchlistMode`)

```swift
enum WatchlistAppMode {
    case mock       // DEBUG default — no API calls
    case restAPI    // RELEASE default — TwelveData REST
    case webSocket  // Opt-in — Finnhub WebSocket
    case graphQL    // Opt-in — GraphQL endpoint
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

### GraphQL Mode Flow
```
GraphQL API (HTTPS POST)
    → GraphQLClient.execute(query:)
    → StockGraphQLDataSource.fetchStockQuotes()
    → GraphQLResponseMapper → [Stock]
    → GraphQLStockRepositoryImpl (conforms to RestStockRepository)
    → Use Cases (same as REST)
    → SwiftUI re-render
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
    let queryItems: [URLQueryItem]?
    let httpBody: Data?   // Optional — used for GraphQL POST requests
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
- **GraphQL:** `POST /graphql` with JSON body `{ query, variables, operationName }`

### GraphQL Client
A lightweight, protocol-based GraphQL client (`GraphQLClientProtocol`) built on pure URLSession — no Apollo or third-party dependencies. Supports both Combine (`AnyPublisher<T, Error>`) and async/await. Constructs HTTP POST requests with JSON-encoded `GraphQLQuery` structs containing type-safe `GraphQLVariable` values.

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
- `iStocksTests` — Unit tests (`WatchlistModuleTests/` + `NetworkingTests/`)
- `iStocksIntegrationTests` — Integration tests

### What's Tested (155 tests, all passing)

**WatchlistModuleTests/ (87 tests):**
- `WatchlistsViewModelTests` — CRUD, validation, price updates, persistence
- `WatchlistViewModelTests` — add/remove stocks, filtered search, price updates
- `WatchlistViewModelProviderTests` — ViewModel caching, independence
- `WatchlistTabViewModelTests` — tab operations, refresh, replace
- `EditWatchlistViewModelTests` — validation logic, add/remove stocks
- `RestStockRepositoryImplTests` — API calls, caching, progress updates
- `MockStockRepositoryTests` — mock data flow
- `QuoteResponseMapperTests` — DTO→Domain mapping
- `WatchlistPersistenceServiceTests` — SwiftData CRUD
- `SharedAlertManagerTests` — alert presentation
- `AppConstantsTests` — configuration values
- `StockPickerViewTests` — ViewModel interaction

**NetworkingTests/ (68 tests):**
- `URLSessionNetworkClientTests` — Combine Decodable/Raw Data, async/await, HTTP status codes (200/401/429/500/503), TwelveDataAPIError detection, JSON decode failures, HTTP method forwarding
- `EndpointTests` — URL construction, query items, HTTP methods
- `NetworkErrorTests` — errorDescription, failureReason, recoverySuggestion, isRetryable for all 11 cases
- `StockRemoteDataSourceTests` — success/error mapping with MockNetworkClient
- `QuoteEndpointTests` — QuoteEndPoint and PriceEndpoint URL construction
- `QuoteResponseMapperExtendedTests` — edge cases: single stock, mixed valid/errors, all-invalid

### Test Infrastructure
- `MockURLProtocol` — URLProtocol subclass for intercepting URLSession requests
- `MockNetworkClient` — protocol-based mock with configurable responses + call tracking
- `MockRemoteDataSource` — mock StockRemoteDataSourceProtocol
- `MockStock` — helper for constructing test Stock objects
- `MockWatchlistPersistenceService` — mock persistence layer
- `WatchlistsViewModelTestable` protocol — abstracts ViewModel for testing

### Remaining Test Gaps
- `WebSocketStockRepositoryImpl` has no tests
- GraphQL client/data source/mapper not yet tested
- No snapshot tests for SwiftUI views
- No UI automation tests (AccessibilityID enum is ready for this)

---

## 13. Accessibility (VoiceOver)

All views have comprehensive VoiceOver support:

### Approach
- **Semantic grouping** via `.accessibilityElement(children: .combine)` for stock rows, loading overlays
- **Descriptive labels** — WatchlistRow reads: "Apple, AAPL, price up, profit 50, 2.5 percent, quantity 10, average 145"
- **Dynamic values** — `.accessibilityValue("Price $150.00")` updates with live price changes
- **Outcome-based hints** — e.g. "Opens stock picker to select stocks" (not gesture descriptions)
- **Traits** — `.isSelected` on active tab, `.isHeader` on titles, `.updatesFrequently` on loading
- **Announcements** — `AccessibilityNotification.Announcement` for batch progress, errors, loading

### AccessibilityID Enum
Centralized identifiers in `Core/Accessibility/AccessibilityIdentifiers.swift` for UI automation:
```swift
enum AccessibilityID {
    enum Watchlist { static let stockRow, searchField, addStocksButton, addWatchlistButton, stockPicker, progressBar, tabBar }
    enum General { static let loadingOverlay, emptyState, errorView, retryButton }
}
```

### Covered Views
WatchlistRow, WatchlistTabView, WatchlistLoadedView, SearchBarView, BatchProgressView, EmptyStateView, WatchlistErrorView, StockPickerView, EditSingleWatchlistView, EditAllWatchlistsView, LoadingOverlay, EmptyWatchlistView, DashboardView, PortfolioView, OrderView

---

## 14. Stock Research Module (WKWebView)

### Architecture
Follows Clean Architecture — Domain entities (`WebBookmark`, `WebNavigationState`), ViewModel (`StockResearchViewModel`), Views (`StockWebView`, `StockResearchView`, `WebViewToolbar`).

### Key Components
- **StockWebView** — `UIViewRepresentable` wrapping `WKWebView` with `Coordinator` implementing `WKNavigationDelegate`, `WKScriptMessageHandler`, `WKUIDelegate`
- **JavaScriptBridge** — Injects scripts to detect `$TICKER` patterns on web pages, wraps them in tappable spans, sends messages to native via `window.webkit.messageHandlers.iStocksHandler.postMessage()`
- **StockResearchViewModel** — `@MainActor ObservableObject` managing navigation state, bookmarks (in-memory), browsing history, and JS bridge callbacks
- **WebViewToolbar** — Back/forward/reload/bookmark/share buttons with progress bar

### Security
- Ticker symbols validated against `^[A-Z]{1,5}$` regex before processing
- DOM manipulation uses `textContent` and `createDocumentFragment` (no `innerHTML`) to prevent XSS
- Non-HTTP schemes (tel:, mailto:) blocked from WebView and opened externally
- JavaScript cannot open windows automatically

### Tab Integration
Research tab replaces the former Bids placeholder tab in the app's tab bar.

---

## 15. Code Quality Findings

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

## 16. Security Considerations

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

## 17. Performance Notes

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

## 18. Improvement Roadmap

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
- [x] Add comprehensive networking layer tests (68 tests — URLSessionNetworkClient, Endpoint, NetworkError, StockRemoteDataSource, QuoteResponseMapper)
- [x] Add unit tests for `WatchlistsViewModel` (18 tests)
- [x] Add unit tests for `WatchlistViewModel` (10 tests)
- [x] Add unit tests for `WatchlistPersistenceService`
- [x] Add unit tests for `RestStockRepositoryImpl` (4 tests)
- [ ] Add unit tests for GraphQL client/data source/mapper
- [ ] Add integration tests for `RestStockRepositoryImpl` batch loading
- [ ] Add snapshot tests for key views (WatchlistRow, BatchProgressView)
- [ ] Add UI automation tests using AccessibilityID identifiers

### Priority 4 — Code Cleanup
- [ ] Remove commented-out guard in `WatchlistViewModelProvider.viewModel(for:)`
- [ ] Move NYSE symbols to a JSON/plist resource instead of Swift source
- [ ] Expand `AppSizes` to capture all hardcoded layout values
- [ ] Remove verbose logging marked as "too verbose" in comments

### Priority 5 — New Features (Completed March 2026)
- [x] VoiceOver accessibility — all views annotated with labels, hints, traits, identifiers
- [x] GraphQL data source — lightweight client, DTOs, mapper, repository, DI wiring
- [x] XCTest networking coverage — 68 tests, MockURLProtocol, MockNetworkClient
- [x] WKWebView Research module — UIViewRepresentable, JS↔Swift bridge, ticker detection
- [ ] Persist bookmarks in Research module (currently in-memory)
- [ ] Preserve Research tab state across tab switches

### Priority 6 — Portfolio / GitHub Quality
- [ ] Write `README.md` with screenshots, architecture diagram, setup instructions
- [ ] Add architecture diagram (draw.io or Mermaid in README)
- [ ] Add `CONTRIBUTING.md`
- [ ] Tag v1.0 release when Watchlist feature is stable
- [ ] Add GitHub Actions CI (build + test on push)
- [ ] Add `CHANGELOG.md`

---

## 19. File-Level Reference

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
| `TabViewEnum.swift` | Shared | Tab cases: watchlist/orders/portfolio/research/settings |
| `AccessibilityIdentifiers.swift` | Core | Centralized AccessibilityID enum for UI testing |
| `GraphQLClient.swift` | Data | Lightweight GraphQL client (URLSession, Combine + async) |
| `GraphQLQuery.swift` | Data | GraphQL query struct + variable encoding |
| `GraphQLError.swift` | Data | GraphQL-specific error types |
| `StockGraphQLQueries.swift` | Data | Predefined stock queries |
| `StockGraphQLDataSource.swift` | Data | GraphQL data source implementation |
| `StockGraphQLDTO.swift` | Data | GraphQL response DTOs |
| `GraphQLResponseMapper.swift` | Data | GraphQL DTO → Domain mapper |
| `GraphQLStockRepositoryImpl.swift` | Data | GraphQL repository (RestStockRepository) |
| `StockResearchView.swift` | View | Main research view with bookmarks/toolbar |
| `StockWebView.swift` | View | UIViewRepresentable WKWebView wrapper |
| `WebViewToolbar.swift` | View | Navigation toolbar + progress bar |
| `JavaScriptBridge.swift` | View | JS↔Swift message handlers + ticker scripts |
| `StockResearchViewModel.swift` | Presentation | Research navigation, bookmarks, JS callbacks |
| `WebBookmark.swift` | Domain | Bookmark entity (Identifiable, Codable) |
| `WebNavigationState.swift` | Domain | WebView navigation state value type |

---

*End of analysis. Update this document when significant architectural changes are made.*
