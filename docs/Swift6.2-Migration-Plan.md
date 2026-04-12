# Swift 6.2 Migration Plan — iStocks

**Branch**: `Swift6.2-migration`
**Date**: April 6, 2026
**Goal**: Migrate iStocks to Swift 6.2 with approachable concurrency and close all gaps between interview prep claims and actual codebase.

---

## Pre-Migration State

| Metric | Value |
|--------|-------|
| Swift Version | 5.0 |
| Strict Concurrency | Not enabled |
| defaultIsolation | Not enabled |
| @MainActor declarations | 17 across 13 files |
| @unchecked Sendable | 3 uses |
| Actors | 2 (PortfolioActor, StockStateActor) |
| DispatchQueue calls | 9 instances |
| .receive(on: DispatchQueue.main) | 13 instances |
| Test methods | 197 |
| @concurrent usage | 0 |

---

## Migration Steps

### Step 0: Swift 6.2 Foundation
- Update `SWIFT_VERSION` from 5.0 → 6 in `.pbxproj`
- Enable `SWIFT_STRICT_CONCURRENCY = complete`
- Enable `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (defaultIsolation)
- Fix all resulting compiler errors

### Step 0b: Remove Redundant @MainActor
- With defaultIsolation(MainActor.self), explicit @MainActor on ViewModels/DI factories is redundant
- Remove from 17 declarations across 13 files

### Step 0c: DispatchQueue → Task Migration
- Replace `DispatchQueue.main.asyncAfter` → `Task { try? await Task.sleep(...) }`
- Replace `DispatchQueue.main.async` → direct execution (already on MainActor)
- Replace `DispatchQueue.global().asyncAfter` → verify if legacy paths still needed

### Step 1: WebSocket State Machine
- Add `transition(to:)` method with enforced transition table
- Replace all 6 direct `connectionState` assignments
- Add unit tests for valid/invalid transitions

### Step 2: PortfolioActor Reentrancy
- Add `executeTrade()` with deduct-before-await + rollback on failure
- Add `refreshPrices()` with in-flight task deduplication
- Add `TradeExecutionService` and `PriceRefreshService` protocols
- Add unit tests for rollback and deduplication

### Step 3: MainActor.assertIsolated()
- Add runtime isolation assertions on critical paths
- WebSocket handler, delegate callbacks, ViewModel state mutations

### Step 4: Bounded Buffer Formalization
- Extract magic number 1000 → `AppConstants.maxWebSocketMessageQueueSize`
- Add backpressure logging
- Document collect + dedup strategy

### Step 5: @concurrent Annotations (SE-0461)
- Add `@concurrent` to `WatchlistsViewModel.buildWatchlists(from:existingWatchlists:)` — CPU-intensive sector grouping
- Extract shared `buildWatchlistsSync()` as `nonisolated static` pure function
- REST path (50+ stocks) uses async `rebuildWatchlistsOffMainActor()` → @concurrent
- Mock/test path keeps synchronous `rebuildWatchlistsFromMasterStocks()`

### Step 6: StockFormatter Utility
- Create centralized formatting with cached NumberFormatters

### Step 7: Sendable Conformances
- Add explicit Sendable to all DTOs crossing isolation boundaries
- Make `WebSocketConnectionState` explicitly `Sendable`
- Make `WebSocketClient` protocol require `Sendable` conformance

### Step 8: nonisolated / @concurrent Audit
- Ensure heavy computation is explicitly opted out of MainActor

### Step 9: WebSocket State → Actor Extraction
- Create `WebSocketConnectionActor` — owns all mutable WebSocket connection state
  - connectionState, subscribedSymbols, pendingSymbols, messageQueue, isReadyToSubscribe
  - State machine `transition(to:)` with enforced transition table
  - `markConnected()` / `markDisconnected()` return actions for the coordinator
  - `addSymbols()` returns whether to subscribe now or reconnect
  - `enqueueMessage()` with bounded buffer + backpressure
- `FinnhubWebSocketClient` becomes thin NSObject coordinator:
  - Retains NSObject only for URLSessionWebSocketDelegate (actors can't inherit)
  - All state access goes through `await connectionActor.*`
  - Delegate callbacks bridge sync → async via `Task { await }`
- Protocol becomes async: `connect() async`, `disconnect() async`, `subscribe() async`
- Repository bridges via `Task { await }` in synchronous interface methods

### Step 10: ConnectionRetryManager → Actor + Task.sleep
- Convert from `nonisolated final class` to `actor`
- Replace `DispatchQueue.asyncAfter` with `Task.sleep(for:)` — cancellation-aware
- Replace `DispatchWorkItem` with `Task<Void, Never>` — structured cancellation
- Retry closure becomes `@Sendable @escaping () async -> Void`
- Actor isolation protects mutable retry state (attempt count, active task)

### Step 11: Heartbeat Timer → Structured Concurrency
- Replace `Timer.scheduledTimer` with `Task` + `Task.sleep` loop
- Cooperative cancellation: `heartbeatTask?.cancel()` stops the loop cleanly
- No RunLoop dependency — works from any isolation context

---

## Challenges Log

_Challenges encountered during migration are documented below as they occur._

### Challenge 1: defaultIsolation cascades to ALL types in the module
- **Issue**: With `defaultIsolation(MainActor.self)`, every struct, enum, protocol, and class in the module becomes MainActor-isolated by default. This means domain entities (Stock, Watchlist, Holding), DTOs, mappers, error types, networking infrastructure, constants — ALL became MainActor-isolated, making them unusable from TaskGroups, actors, and background work.
- **Resolution**: Added `nonisolated` keyword to 50+ type declarations across the codebase. The pattern: anything that's a data type, utility, constant, or infrastructure must be explicitly `nonisolated`. Only Views and ViewModels should remain MainActor.
- **Lesson**: When enabling `defaultIsolation(MainActor.self)`, plan for a significant number of `nonisolated` annotations on non-UI types. This is the expected migration pattern — the default covers the "80% case" (UI code), and you explicitly opt out the "20%" (data/domain/infra).

### Challenge 2: Protocol conformance crossing isolation boundaries
- **Issue**: Types conforming to `nonisolated` protocols (like `APIEndpoint`, `WatchlistRepository`) had their protocol method implementations implicitly MainActor-isolated, causing "conformance crosses into main actor-isolated code" errors.
- **Resolution**: Both the protocol AND the conforming type (or its extension) must be `nonisolated`. Protocol extensions providing default implementations also need `nonisolated`.
- **Lesson**: In Swift 6.2, isolation is checked at conformance boundaries. If a protocol is `nonisolated`, all conforming types must satisfy requirements in a nonisolated context.

### Challenge 3: URLSession delegate conformance
- **Issue**: `FinnhubWebSocketClient` conforming to `URLSessionWebSocketDelegate` caused "conformance crosses into main actor-isolated code" errors because the delegate methods are called by URLSession's internal machinery.
- **Resolution**: Used `@preconcurrency URLSessionWebSocketDelegate` on the extension to bridge the pre-concurrency protocol.
- **Lesson**: Apple framework delegate protocols that predate Swift concurrency need `@preconcurrency` when the conforming type is in a module with strict concurrency.

### Challenge 4: `lazy var` not supported in nonisolated classes
- **Issue**: `FinnhubWebSocketClient` had `private lazy var session` which isn't allowed in `nonisolated` classes because `lazy` requires mutable state access which conflicts with isolation safety.
- **Resolution**: Changed to `private var session: URLSession!` initialized in `init()` after `super.init()`.
- **Lesson**: `lazy` properties are a common Swift pattern that doesn't work in nonisolated classes. Convert to explicit initialization in init.

### Challenge 5: PassthroughSubject is not Sendable
- **Issue**: `PassthroughSubject<[Stock], Never>` in `WebSocketStockRepositoryImpl` couldn't be captured in Task closures because Combine subjects aren't Sendable.
- **Resolution**: Made the repository class `@unchecked Sendable` with documentation that thread safety is guaranteed by the Combine pipeline running on RunLoop.main and the StockStateActor protecting shared state.
- **Lesson**: Combine types predate Swift concurrency and are not Sendable. Use `@unchecked Sendable` with documented safety justification, or `nonisolated(unsafe)` for specific properties.

### Challenge 6: deinit is always nonisolated
- **Issue**: `StockWebView.Coordinator.deinit` accessed `cancellables: Set<AnyCancellable>` which is non-Sendable, but `deinit` is always nonisolated even in MainActor classes.
- **Resolution**: Marked `cancellables` as `nonisolated(unsafe)` — safe because the coordinator is only used on the main thread.
- **Lesson**: `deinit` in MainActor classes is a known pain point in Swift 6. `nonisolated(unsafe)` is the standard workaround for properties accessed only in deinit cleanup.

### Challenge 7: Actors cannot inherit from NSObject
- **Issue**: `FinnhubWebSocketClient` inherits from `NSObject` for `URLSessionWebSocketDelegate` conformance. Actors cannot inherit from classes, so it can't be converted to an actor directly.
- **Resolution**: Composition over inheritance — extracted a `WebSocketConnectionActor` that owns all mutable state. The class retains NSObject only for delegate conformance and delegates all state management to the actor. This is the same pattern used with `StockStateActor`.
- **Lesson**: When migrating classes with delegate conformance to actors, use the "actor extraction" pattern: keep a thin class for the delegate protocol, move state into a dedicated actor.

### Challenge 8: Sync delegate callbacks → async actor access
- **Issue**: `URLSessionWebSocketDelegate` methods are synchronous, but accessing actor state requires `await`. You can't `await` from a synchronous context.
- **Resolution**: Bridge with `Task { await connectionActor.markConnected() }`. The delegate runs on .main (delegateQueue set in init), and the Task inherits MainActor context, so there's no reordering issue for the happy path. State changes that need immediate effect (like flushing queued messages) are handled in the Task continuation.
- **Lesson**: When bridging delegate-based APIs to actors, `Task { await }` is the standard pattern. Accept the one-hop delay — the alternative (keeping mutable state in a non-isolated class) is worse.

### Challenge 9: Timer → Task.sleep migration in heartbeat
- **Issue**: `Timer.scheduledTimer` requires RunLoop and isn't cancellation-aware. Also, Timer fire closures capture `self` and need careful weak-self management.
- **Resolution**: Replaced with a `Task` containing a `while !Task.isCancelled` loop with `Task.sleep(for:)`. Cancellation is cooperative and handled automatically. `heartbeatTask?.cancel()` cleanly stops the loop.
- **Lesson**: For periodic work, `Task.sleep` in a loop is the structured concurrency replacement for `Timer`. It's simpler (no RunLoop, no weak-self) and integrates with Swift's cancellation system.

---

## Post-Migration State

| Metric | Before | After |
|--------|--------|-------|
| Swift Version | 5.0 | 6.0 |
| Strict Concurrency | Off | Complete |
| defaultIsolation | Off | MainActor (SE-0466) |
| Explicit @MainActor | 17 | 13 (only where needed) |
| nonisolated types | 0 | 77 files |
| @unchecked Sendable | 3 | 7 (all documented) |
| nonisolated(unsafe) | 0 | 4 (deinit, legacy patterns) |
| DispatchQueue calls | 9 | 7 (retry + heartbeat migrated to Task.sleep) |
| Actors | 2 | 4 (+WebSocketConnectionActor, ConnectionRetryManager) |
| @concurrent methods | 0 | 1 (buildWatchlists sector grouping) |
| Timer usage | 1 | 0 (heartbeat → Task.sleep loop) |
| Test methods | 197 | 200 (+3 PortfolioActor reentrancy) |
| New files | - | StockFormatter.swift, TradeExecutionService.swift, WebSocketConnectionActor.swift |

## Key Patterns Demonstrated

1. **defaultIsolation(MainActor.self)** — Module-wide MainActor default, `nonisolated` for data/domain/infra
2. **State Machine** — WebSocket `transition(to:)` with enforced transition table
3. **Actor Reentrancy** — `executeTrade()` deduct-before-await with rollback, `refreshPrices()` in-flight dedup
4. **MainActor.assertIsolated()** — Runtime verification on delegate callbacks
5. **Bounded Buffer** — Documented collect + dedup backpressure strategy
6. **StockFormatter** — Centralized formatting with cached NumberFormatters
7. **@unchecked Sendable** — Used pragmatically with documented safety justification
8. **nonisolated(unsafe)** — For `deinit` and legacy `@Published` property wrapper limitations
9. **Actor Extraction** — WebSocketConnectionActor owns state, NSObject class handles delegates (actors can't inherit)
10. **DispatchQueue → Task.sleep** — ConnectionRetryManager exponential backoff with cooperative cancellation
11. **Timer → Task loop** — Heartbeat using `while !Task.isCancelled` + `Task.sleep(for:)`
12. **@concurrent (SE-0461)** — Off-MainActor CPU work for 50+ stock sector grouping in ViewModel
