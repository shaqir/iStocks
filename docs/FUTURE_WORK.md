# Future Work

Deferred deliberately to keep the project small and focused on learning. Removed code is
still in git history — the last commit that contains each item is noted.

## GraphQL data source (removed)

**What existed:** a hand-rolled GraphQL client (`GraphQLClient`, `GraphQLQuery`,
`GraphQLError`), `StockGraphQLDataSource`, DTOs, `GraphQLResponseMapper`,
`GraphQLStockRepositoryImpl`, a `graphql` value for `WATCHLIST_MODE`, and tests with a mock
data source. Last present in commit `7d16c49`.

**Why removed:** it pointed at `https://api.twelvedata.com/graphql`, but Twelve Data has
no GraphQL API, so the mode could never run against a real server. It also sent no auth.

**To bring it back properly:**
1. Choose a provider with a real GraphQL API, or write a small local GraphQL server
   to test against.
2. Restore the files from `7d16c49` (`git checkout 7d16c49 -- <paths>`).
3. Add an auth header and an `isRetryable` mapping for GraphQL errors.
4. Re-add the `.graphQL` case to `WatchlistAppMode` and `AppConfiguration`.

## Strengthen the demo

- **CI:** add a GitHub Actions workflow on `macos-26` with Xcode pinned, unit + UI tests,
  `-skip-testing:iStocksIntegrationTests`, `CODE_SIGNING_ALLOWED=NO`. (The old workflows
  targeted Xcode 16 and always failed, so they were removed.)
- **REST freshness:** store a fetch timestamp, refetch when stale, and show "as of …".
- **ViewModel provider:** `viewModel(for:)` mutates state while `body` is evaluated
  ("Publishing changes from within view updates"); make it side-effect free and give the
  provider a single owner.
- **SwiftData:** separate the top-50 cache from watchlist stocks, surface errors, keep
  `orderIndex`, consider `@ModelActor`.
- **Abstraction leak:** expose batch progress through a protocol instead of downcasting.
- **PortfolioActor:** roll back only the new holding (by id) after a failed trade.
- **WebSocket:** remaining data-race surface in `FinnhubWebSocketClient`
  (`@unchecked Sendable`), one unstructured `Task` per trade (ordering), tests with a
  fake socket.
- **Logging:** default `AppLogger` to private formatting with an explicit public variant.
- **Auth:** `.deviceOwnerAuthentication` (passcode fallback), re-lock on background.
- **Observation:** migrate ViewModels to `@Observable`.
- **Fastlane:** `test` targets `iPhone 16` (not available under Xcode 27); `Appfile` and
  `Matchfile` hold placeholders, and the Matchfile bundle id (`com.sakirsaiyed.iStocks`)
  differs from the app's (`com.iosRoadMapDemos.iStocks`). Fix the `test` lane and either
  configure or remove `beta`/`match`.
- **`@unchecked Sendable`:** 8 types use it (use cases, repositories, data sources,
  `APIClient`, `FinnhubWebSocketClient`). Document why each is safe, or make them
  `Sendable` by construction.
- **Project settings:** the project-level deployment target is 18.5 (every target
  overrides it to 18.2); the integration test bundle id is `com.example.download…`.

## Removed as unused

- `CryptoManager` and `KeychainManager` (never called by the app; HKDF was the wrong
  primitive for passwords — use PBKDF2/Argon2 if this returns). Last present in `7d16c49`.
- `PortfolioView`, `BidsView` (never shown).
- `Configurations/*.xcconfig` (never wired into the project) and duplicate `CI-CD/` copies.
