# iStocks Architecture — Interview Reference

## Branch Overview

| Branch | Purpose | Key Patterns |
|--------|---------|-------------|
| `main` | Production watchlist with Combine | Clean Architecture, MVVM, WebSocket, Combine, SwiftData |
| `feat/structured-concurrency-migration` | Concurrency modernization | Actor, TaskGroup, async/await migration |
| `feature/clean-architecture-refactor` | Full architecture showcase | Biometric auth, CryptoKit, CI/CD, protocol generics |

---

## Branch 1: `main` — Production Watchlist

### Architecture: Clean Architecture + MVVM (Combine-based)

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                          │
│                                                                 │
│  iStocksApp ──► TabBarContainer ──► TabRouterView               │
│                                        │                        │
│                    ┌───────────────────┼────────────────┐       │
│                    ▼                   ▼                ▼       │
│              WatchlistTab        ResearchView      Placeholders │
│                    │                   │                        │
│         WatchlistsViewModel    StockResearchVM                  │
│         (@MainActor)           (@MainActor)                     │
│         @Published + Combine   @Published + KVO                 │
│              │                                                  │
│    WatchlistViewModelProvider                                   │
│    (caches child ViewModels)                                    │
│         │                                                       │
│    WatchlistViewModel ──► EditWatchlistViewModel                 │
│    (per-watchlist)        (CRUD validation)                     │
└────────────┬────────────────────────────────────────────────────┘
             │
             │  PassthroughSubject / @Published
             │  Publishers.Merge (structural + price updates)
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                              │
│                   (zero framework imports)                       │
│                                                                 │
│  Entities:  Stock (struct, Codable, Equatable)                  │
│             Watchlist (struct)                                   │
│                                                                 │
│  Use Cases: ObserveMockStocksUseCase                            │
│             ObserveTop50StocksUseCase                            │
│             ObserveStockPricesUseCase                            │
│             FetchStocksBySymbolUseCase                           │
│             SaveWatchlistsUseCase / LoadWatchlistsUseCase        │
│                                                                 │
│  Protocols: WatchlistRepository (base)                          │
│             └── StockLiveRepository (streaming)                 │
│                 └── RestStockRepository (+ fetchStockQuotes)    │
│             MockWatchlistRepository (dual conformance)           │
│                                                                 │
│  Default implementations via protocol extensions (no-op)        │
└────────────┬────────────────────────────────────────────────────┘
             │
             │  Protocol-based abstraction
             │  4 interchangeable implementations
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                               │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │   Mock        │  │   REST API   │  │   WebSocket          │  │
│  │   MockStock   │  │   TwelveData │  │   Finnhub            │  │
│  │   Repository  │  │   Batched    │  │   Real-time prices   │  │
│  │   Impl        │  │   8/request  │  │   URLSessionWS       │  │
│  └──────────────┘  │   60s delay   │  │   Heartbeat + Retry  │  │
│                     │   2 retries   │  │   collect(.byTime()) │  │
│  ┌──────────────┐  └──────────────┘  └──────────────────────┘  │
│  │   GraphQL    │                                               │
│  │   (planned)  │  ┌──────────────────────────────────────────┐ │
│  └──────────────┘  │  Local Persistence (SwiftData)           │ │
│                     │  WatchlistEntity ◄──► StockEntity        │ │
│                     │  Bidirectional @Relationship              │ │
│                     │  WatchlistPersistenceService              │ │
│                     └──────────────────────────────────────────┘ │
│                                                                 │
│  Networking: NetworkClient (protocol)                           │
│              URLSessionNetworkClient (Combine + async/await)    │
│              Endpoint (struct), QuoteEndPoint, PriceEndpoint    │
│                                                                 │
│  DI: WatchlistDIContainer (static factories, cached singletons)│
│      Mode selection: AppConfiguration.watchlistMode             │
│      .mock / .restAPI / .websocket / .graphQL                   │
│                                                                 │
│  Shared: AppLogger (os.Logger), SharedAlertManager,             │
│          SecureAPIKeyManager, ConnectionRetryManager             │
│          (exponential backoff with DispatchWorkItem)             │
└─────────────────────────────────────────────────────────────────┘
```

### Key Data Flows

**Watchlist loading (REST mode):**
```
WatchlistsViewModel.loadWatchlists()
  → useCases.loadWatchlists.loadWatchlists()      // Check SwiftData cache
  → useCases.observeTop50.execute()                // Fetch from API
    → RestStockRepositoryImpl.observeTop50Stocks()
      → Check persistence cache (skip API if all symbols cached)
      → StockRemoteDataSource.fetchRealtimePricesForTop50InBatches()
        → symbols.chunked(into: 8)                // Batch into groups of 8
        → fetchSequentiallyWithRetry()             // Recursive Combine chain
          → fetchPrices(for: batch)                // Single API call
          → Success: subject.send(stocks), schedule next batch after 60s
          → Failure: retry up to 2x, then skip batch
```

**WebSocket price streaming:**
```
FinnhubWebSocketClient
  → URLSessionWebSocketTask.receive()              // Recursive listening
  → PassthroughSubject<StockFinnPriceDTO, Never>   // Emits raw DTOs
      │
      ▼
WebSocketStockRepositoryImpl
  → .collect(.byTime(RunLoop.main, .seconds(1)))   // Batch 1 second
  → Dictionary(grouping:by:\.symbol).last           // Deduplicate per symbol
  → stocksQueue.sync { currentStocks[symbol] = stock } // Thread-safe update
  → subject.send(allStocks)                         // Publish to ViewModel
```

### Concurrency Model
- **Combine**: All data flow (publishers, subjects, sink, store)
- **@MainActor**: All ViewModels
- **DispatchQueue**: Serial queue for WebSocket state, global queue for batch delays
- **Timer**: Heartbeat keep-alive (10s interval)
- **No actors, no TaskGroup** — this is the baseline for the migration story

---

## Branch 2: `feat/structured-concurrency-migration` — Concurrency Modernization

### What Changed (4 files, additive — both paradigms coexist)

```
┌─────────────────────────────────────────────────────────────────┐
│  BEFORE (main)                    AFTER (migration branch)      │
│                                                                 │
│  WebSocketStockRepositoryImpl:                                  │
│  ┌──────────────────────────┐    ┌───────────────────────────┐  │
│  │ stocksQueue.sync {       │ ──►│ await stateActor.update() │  │
│  │   currentStocks[s] = v   │    │                           │  │
│  │ }                        │    │ actor StockStateActor {    │  │
│  │ (DispatchQueue — runtime │    │   var currentStocks: ...  │  │
│  │  safety only)            │    │ } (compile-time safety)   │  │
│  └──────────────────────────┘    └───────────────────────────┘  │
│                                                                 │
│  StockRemoteDataSource:                                         │
│  ┌──────────────────────────┐    ┌───────────────────────────┐  │
│  │ fetchSequentiallyWith    │ ──►│ fetchTop50InBatchesAsync() │  │
│  │ Retry() — recursive,    │    │ — for loop, Task.sleep,   │  │
│  │ DispatchQueue.asyncAfter,│    │ Task.checkCancellation(), │  │
│  │ weak self, 70 lines      │    │ linear, 50 lines          │  │
│  └──────────────────────────┘    └───────────────────────────┘  │
│                                                                 │
│  Both versions COEXIST — Combine is still the production path.  │
│  This IS the migration story: incremental, not rewrite.         │
└─────────────────────────────────────────────────────────────────┘
```

### StockStateActor (NEW)
```swift
actor StockStateActor {
    private var currentStocks: [String: Stock] = [:]

    func update(symbol:, stock:) -> [Stock]   // Returns snapshot after mutation
    func snapshot() -> [Stock]                 // Read-only access
    func reset()                               // Clear all
}
```

### Async Batch Fetching (NEW — alongside existing Combine version)
```
fetchTop50InBatchesAsync(symbols, batchSize: 8)
  for (index, batch) in batches.enumerated() {
      try Task.checkCancellation()          ← Cooperative cancellation
      for attempt in 0...maxRetries {
          batchResult = try await fetchBatchAsync(symbols: batch)
          break on success
          catch → Task.sleep(for: .seconds(60))  ← Cancellable delay!
      }
      allStocks.append(contentsOf: batchResult)
      try await Task.sleep(for: .seconds(60))    ← Rate limit between batches
  }
  return allStocks
```

### Why This Matters for the Interview
- Shows you can **evolve** existing code, not just write greenfield
- Demonstrates understanding of **when Combine stays** (reactive streams) vs **when async/await wins** (request-response)
- The `didResume` guard in continuation bridges fixes a real bug (double-resume crash)

---

## Branch 3: `feature/clean-architecture-refactor` — Full Architecture Showcase

### Architecture: Clean Architecture + MVVM (async/await-based)

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                          │
│                                                                 │
│  iStocksApp                                                     │
│    └── AuthGateView<Content> ◄── NEW: biometric gate            │
│          │                                                      │
│          ├── isAuthenticated = false → Biometric prompt          │
│          │     Face ID / Touch ID icon based on biometryType    │
│          │     Button → AuthViewModel.authenticate()            │
│          │                                                      │
│          └── isAuthenticated = true → TabBarContainer            │
│                └── TabRouterView                                │
│                      ├── .watchlist → WatchlistTabContainer     │
│                      ├── .portfolio → DashboardView  ◄── NEW   │
│                      ├── .research  → StockResearchView        │
│                      └── .orders/.settings → Placeholders       │
│                                                                 │
│  ViewModels (all @MainActor):                                   │
│  ┌───────────────────────┐  ┌──────────────────────┐           │
│  │ DashboardViewModel    │  │ AuthViewModel         │           │
│  │ • loadTask: Task?     │  │ • isAuthenticated     │           │
│  │ • onAppear/onDisappear│  │ • biometryType        │           │
│  │ • refresh() async     │  │ • authenticate()      │           │
│  │ • deinit logging      │  │ • deinit logging      │           │
│  └───────────┬───────────┘  └──────────┬───────────┘           │
└──────────────┼──────────────────────────┼───────────────────────┘
               │                          │
               ▼                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                       DOMAIN LAYER                              │
│                   (zero framework imports)                       │
│                                                                 │
│  Models (all Sendable):                                         │
│  ┌──────────┐  ┌───────────┐  ┌──────┐                        │
│  │ Holding  │  │ Dashboard │  │ News │                         │
│  │ • symbol │  │ • holdings│  │ • id │                         │
│  │ • qty    │  │ • news    │  │ • url│                         │
│  │ • price  │  │ • total   │  └──────┘                         │
│  │ • P&L    │  │ • updated │                                    │
│  └──────────┘  └───────────┘                                    │
│                                                                 │
│  Use Cases:                                                     │
│  ┌────────────────────────────────────────────────────────┐     │
│  │ FetchDashboardUseCase                                  │     │
│  │                                                        │     │
│  │ Phase 1: holdings = await repo.fetchHoldings()         │     │
│  │          try Task.checkCancellation()                   │     │
│  │                                                        │     │
│  │ Phase 2: async let prices = refreshPrices(holdings)    │     │
│  │          async let news = fetchNewsSafely(symbols)      │     │
│  │                                                        │     │
│  │ Inside refreshPrices:                                  │     │
│  │   withThrowingTaskGroup { for holding in holdings {    │     │
│  │     group.addTask { await repo.fetchPrice(symbol) }    │     │
│  │   }}                                                   │     │
│  │                                                        │     │
│  │ Phase 3: await portfolio.update(finalHoldings)         │     │
│  └────────────────────────────────────────────────────────┘     │
│  ┌────────────────────────────────────────────────────────┐     │
│  │ AuthenticateUserUseCase                                │     │
│  │   execute() → repo.authenticate() → boolean result     │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                 │
│  Protocols:                                                     │
│    StockRepositoryProtocol: Sendable (fetchHoldings/Price/News) │
│    AuthRepositoryProtocol (authenticate/isBiometricsAvailable)  │
└────────────┬──────────────────────────────┬─────────────────────┘
             │                              │
             ▼                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DATA LAYER                               │
│                                                                 │
│  Networking:                                                    │
│  ┌──────────────────────────────────────────────────────┐       │
│  │ protocol APIEndpoint {                                │       │
│  │   associatedtype Response: Decodable & Sendable       │       │
│  │   var path, method, queryItems, baseURL               │       │
│  │ }                                                     │       │
│  │                                                       │       │
│  │ protocol APIClientProtocol: Sendable {                │       │
│  │   func request<E: APIEndpoint>(_ e: E) -> E.Response  │       │
│  │ }                                                     │       │
│  │                                                       │       │
│  │ URLSessionAPIClient ◄──► MockAPIClient (tests)        │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                 │
│  Actors:                                                        │
│  ┌──────────────────────────────────────────────────────┐       │
│  │ PortfolioActor                                        │       │
│  │   update(), addHolding(), removeHolding()             │       │
│  │   totalValue(), holding(for:)                         │       │
│  │   nonisolated isMarketOpen()                          │       │
│  └──────────────────────────────────────────────────────┘       │
│                                                                 │
│  Security:                                                      │
│  ┌────────────────┐  ┌──────────────┐  ┌──────────────────┐    │
│  │BiometricAuth   │  │ CryptoManager│  │ KeychainManager  │    │
│  │Manager         │  │              │  │                  │    │
│  │• LAContext     │  │• AES-GCM     │  │• SecItemAdd      │    │
│  │• evaluatePolicy│  │• HKDF<SHA256>│  │• SecItemCopy     │    │
│  │• Full LAError  │  │• HMAC        │  │• SecAccessControl│    │
│  │  mapping       │  │• Salt gen    │  │• .biometryCurrent│    │
│  │• Fallback chain│  │              │  │  Set             │    │
│  └────────────────┘  └──────────────┘  └──────────────────┘    │
│                                                                 │
│  Repositories:                                                  │
│    StockRepository (APIClient → mock data / real API)           │
│    AuthRepository (BiometricAuthManager wrapper)                │
│                                                                 │
│  DI: DashboardDIContainer, AuthDIContainer                      │
│      (static factories, cached singletons)                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      CI/CD & CONFIG                             │
│                                                                 │
│  GitHub Actions:  Build Debug → Build Release → Test → Coverage │
│  Fastlane:        test lane, beta lane (TestFlight)             │
│  xcconfig:        Dev / Staging / Production environments       │
└─────────────────────────────────────────────────────────────────┘
```

### Test Coverage Map

```
┌──────────────────────────────────────────────────────────────┐
│  DashboardViewModelTests          │ onAppear success/error   │
│  (@MainActor, async)              │ onDisappear cancellation │
│                                   │ refresh updates state    │
├───────────────────────────────────┼──────────────────────────┤
│  PortfolioActorTests              │ update, add, remove      │
│  (actor concurrency)              │ concurrent access (10    │
│                                   │ tasks via TaskGroup)     │
├───────────────────────────────────┼──────────────────────────┤
│  FetchDashboardUseCaseTests       │ sequential→parallel flow │
│  (graceful degradation)           │ news failure → empty []  │
│                                   │ price failure → cached   │
├───────────────────────────────────┼──────────────────────────┤
│  CryptoManagerTests               │ encrypt/decrypt roundtrip│
│  (CryptoKit)                      │ wrong key throws         │
│                                   │ HMAC integrity + tamper  │
│                                   │ key derivation determin. │
├───────────────────────────────────┼──────────────────────────┤
│  AuthViewModelTests               │ success, failure         │
│  (MockBiometricAuthManager)       │ userCancelled → no error │
├───────────────────────────────────┼──────────────────────────┤
│  APIClientTests                   │ decode success           │
│  (MockAPIClient)                  │ HTTP error, no data      │
└───────────────────────────────────┴──────────────────────────┘
```

---

## Quick Reference: Interview Topic → File → Branch

| Topic | File to Open | Branch |
|-------|-------------|--------|
| **Combine pipelines** | `WebSocketStockRepositoryImpl.swift` | `main` |
| **collect(.byTime()) batching** | `WebSocketStockRepositoryImpl.swift:29` | `main` |
| **Recursive batch fetching** | `StockRemoteDataSource.swift:101-172` | `main` |
| **ConnectionRetryManager** | `ConnectionRetryManager.swift` | `main` |
| **Protocol hierarchy + defaults** | `WatchlistRepository.swift` | `main` |
| **Mode-based DI** | `WatchlistDIContainer.swift` | `main` |
| **SwiftData persistence** | `WatchlistPersistenceService.swift` | `main` |
| **Parent↔Child ViewModel comms** | `WatchlistViewModelProvider.swift` | `main` |
| **Actor replacing DispatchQueue** | `StockStateActor.swift` | `feat/structured-concurrency-migration` |
| **TaskGroup batch fetching** | `StockRemoteDataSource.swift:236-292` | `feat/structured-concurrency-migration` |
| **async let + TaskGroup** | `FetchDashboardUseCase.swift` | `feature/clean-architecture-refactor` |
| **PortfolioActor** | `PortfolioActor.swift` | `feature/clean-architecture-refactor` |
| **Associated type generics** | `APIEndpoint.swift` + `APIClient.swift` | `feature/clean-architecture-refactor` |
| **@MainActor + Task cancel** | `DashboardViewModel.swift` | `feature/clean-architecture-refactor` |
| **LocalAuthentication** | `BiometricAuthManager.swift` | `feature/clean-architecture-refactor` |
| **CryptoKit AES-GCM** | `CryptoManager.swift` | `feature/clean-architecture-refactor` |
| **Keychain + biometric guard** | `KeychainManager.swift` | `feature/clean-architecture-refactor` |
| **Protocol-based test mocking** | `DashboardViewModelTests.swift` | `feature/clean-architecture-refactor` |
| **CI/CD pipeline** | `.github/workflows/ci.yml` | `feature/clean-architecture-refactor` |
| **Fastlane** | `fastlane/Fastfile` | `feature/clean-architecture-refactor` |
