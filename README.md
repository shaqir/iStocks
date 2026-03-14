# iStocks

A real-time iOS stock tracking app built for the way traders actually work — multiple watchlists, live price feeds, and fast symbol search. Inspired by Kite Zerodha's UX, architected with Clean Architecture + MVVM to support swapping between mock data, REST APIs, and WebSocket streams without touching the UI layer.

## The Problem

Most stock apps bundle everything into monolithic views with tightly coupled networking. iStocks takes a different approach: the data source is a configuration toggle, not a code change. Switch between offline mock data (for demos and testing), batched REST polling (Twelve Data API), or real-time WebSocket streaming (Finnhub) — all through a single DI container setting.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      PRESENTATION LAYER                        │
│                                                                 │
│  TabBarContainer → TabRouterView → WatchlistTabContainerView    │
│                                                                 │
│  ViewModels:                                                    │
│  ├── WatchlistsViewModel    (orchestrates all watchlists)       │
│  ├── WatchlistViewModel     (single watchlist + search)         │
│  └── EditWatchlistViewModel (create/edit with validation)       │
│                                                                 │
│  Views: WatchlistTabView, StockPickerView, WatchlistRow,        │
│         EditSingleWatchlistView, BatchProgressView              │
├─────────────────────────────────────────────────────────────────┤
│                        DOMAIN LAYER                             │
│                                                                 │
│  Entities: Stock, Watchlist, BatchProgress                      │
│  Protocols: WatchlistRepository, RestStockRepository,           │
│             StockLiveRepository, MockWatchlistRepository        │
│  Use Cases: ObserveMockStocks, ObserveTop50Stocks,              │
│             ObserveStockPrices, FetchStocksBySymbol              │
│  Errors: StockValidationError, WatchlistValidationError         │
├─────────────────────────────────────────────────────────────────┤
│                         DATA LAYER                              │
│                                                                 │
│  Repositories:                                                  │
│  ├── MockStockRepositoryImpl      (25 pre-loaded stocks)        │
│  ├── RestStockRepositoryImpl      (batched REST, retry logic)   │
│  └── WebSocketStockRepositoryImpl (Finnhub, 1s batch window)    │
│                                                                 │
│  Data Sources:                                                  │
│  ├── StockRemoteDataSource   (Twelve Data API, batch of 8)      │
│  ├── FinnhubWebSocketClient  (heartbeat, auto-reconnect)        │
│  └── WatchlistPersistenceService (SwiftData)                    │
│                                                                 │
│  DTOs → Mappers → Domain Entities                               │
│  StockQuoteDTO, StockPriceDTO, StockFinnPriceDTO                │
│  QuoteResponseMapper, PriceResponseMapper, FinnhubMapper        │
├─────────────────────────────────────────────────────────────────┤
│                     SHARED INFRASTRUCTURE                       │
│                                                                 │
│  NetworkClient (protocol) → URLSessionNetworkClient             │
│    Supports: Combine publishers + async/await                   │
│  SharedAlertManager (toast alerts, haptic feedback)              │
│  Logger (categorized, toggleable)                               │
│  WatchlistDIContainer (factory methods, mode switching)         │
└─────────────────────────────────────────────────────────────────┘
```

## Tech Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| Language | Swift | 5.10 |
| UI Framework | SwiftUI | iOS 17+ |
| Reactive | Combine | — |
| Architecture | MVVM + Clean Architecture | — |
| Persistence | SwiftData | iOS 17+ |
| REST API | Twelve Data API | v1 |
| WebSocket | Finnhub Streaming | — |
| Networking | URLSession (protocol-based) | — |
| Testing | XCTest + ViewInspector | — |
| CI/CD | GitHub Actions | macOS 14, Xcode 16.2 |

## Key Implementation Decisions

**Strategy Pattern for Data Sources** — Three interchangeable repository implementations (`Mock`, `REST`, `WebSocket`) behind a shared protocol. Swap with one line in `WatchlistDIContainer`. The UI layer has zero knowledge of which data source is active.

**Batched REST with Retry** — Top 50 NYSE stocks are fetched in batches of 8 to stay within API rate limits. Each batch retries up to 2 times with 60s cooldown. Only missing symbols are fetched on subsequent loads to avoid redundant calls.

**WebSocket Deduplication** — Finnhub sends high-frequency trade messages. The WebSocket repository collects incoming DTOs over a 1-second window, deduplicates by symbol (keeping the latest price), then emits a single batch update.

**DTO → Domain Mapping** — API response types never leak into the domain layer. Dedicated mappers (`QuoteResponseMapper`, `PriceResponseMapper`, `FinnhubResponseMapper`) handle the transformation, isolating the domain from API contract changes.

**Combine-Driven State** — ViewModels communicate through `PassthroughSubject` publishers. `WatchlistsViewModel` manages a global stock cache and coordinates price propagation across all child `WatchlistViewModel` instances. Search uses `.debounce(300ms)` to avoid excessive filtering.

**SwiftData Persistence** — `WatchlistEntity` and `StockEntity` with `@Relationship` for one-to-many mapping. Persistence service loads on launch and saves on watchlist mutations.

**Global Alert System** — `SharedAlertManager` (singleton) presents toast-style alerts with haptic feedback and 2.5s auto-dismiss. Domain errors conform to `LocalizedAlertConvertible` for consistent user messaging.

## Project Structure

```
iStocks/
├── App/
│   └── iStocksApp.swift
├── Core/
│   ├── Constants/          AppConstants, AppStrings, AppFonts, AppSizes
│   ├── Extensions/         Double+Currency, Color, Font, Array
│   └── Utilities/          AppError, MarketHoursHelper
├── Features/
│   └── Watchlist/
│       ├── Domain/
│       │   ├── Entities/       Stock, Watchlist
│       │   ├── Repositories/   Protocol definitions
│       │   ├── UseCases/       5 use cases (Mock, Top50, Prices, Symbols, Observe)
│       │   └── Shared/         BatchProgress
│       ├── Data/
│       │   ├── DataSources/
│       │   │   ├── Local/      SwiftData entities + persistence service
│       │   │   ├── Remote/     StockRemoteDataSource, endpoints, API errors
│       │   │   ├── WebSocket/  FinnhubWebSocketClient, ConnectionRetryManager
│       │   │   └── Mock/       MockStockData, MockStockStreamingService
│       │   ├── Repositories/   3 implementations (Mock, REST, WebSocket)
│       │   ├── DTOs/           StockQuoteDTO, StockPriceDTO, StockFinnPriceDTO
│       │   └── Mappers/        Quote, Price, Finnhub response mappers
│       └── Presentation/
│           ├── DI/             WatchlistDIContainer (3 app modes)
│           ├── ViewModel/      WatchlistsVM, WatchlistVM, EditWatchlistVM
│           └── View/           All SwiftUI views and components
├── Shared/
│   ├── Networking/         NetworkClient protocol, URLSession implementation
│   ├── TabBar/             Custom tab bar, routing
│   └── Components/         SharedAlertManager, Logger
└── Resources/              Assets, fonts
```

<img width="510" height="708" alt="Structure" src="https://github.com/user-attachments/assets/433ec79f-0ca7-4126-99c4-a35b4b48cdd9" />

## Setup

```bash
git clone https://github.com/shaqir/iStocks.git
cd iStocks
open iStocks.xcodeproj
```

### API Keys

The app runs in **mock mode by default** — no API keys needed. To enable live data:

1. Get a free API key from [Twelve Data](https://twelvedata.com) and/or [Finnhub](https://finnhub.io)
2. Set keys in `NetworkConstants.swift` or inject via CI/CD secrets
3. Change `WatchlistDIContainer.mode` to `.restAPI` or `.websocket`

### Data Source Modes

```swift
// In WatchlistDIContainer.swift
static let mode: WatchlistAppMode = .mock       // No API keys needed
static let mode: WatchlistAppMode = .restAPI    // Twelve Data REST
static let mode: WatchlistAppMode = .websocket  // Finnhub WebSocket
```

### Requirements

- macOS 14+
- Xcode 16+
- iOS 17+ Simulator or device
- Swift 5.10+

## Testing

18+ unit tests covering ViewModels, repositories, persistence, mappers, and UI (via ViewInspector).

```bash
xcodebuild test \
  -project iStocks.xcodeproj \
  -scheme iStocks \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

**Test coverage includes:**
- `WatchlistViewModelTests` — initialization, stock selection, price propagation
- `EditWatchlistViewModelTests` — validation rules, stock limits, deduplication
- `WatchlistsViewModelTests` — global watchlist orchestration
- `RestStockRepositoryImplTests` — batch fetching, retry behavior
- `MockStockRepositoryTests` — mock data emission
- `WatchlistPersistenceServiceTests` — SwiftData read/write
- `QuoteResponseMapperTests` — DTO-to-domain mapping
- `SharedAlertManagerTests` — alert lifecycle
- `StockPickerViewTests` — UI testing with ViewInspector

<table>
  <tr>
    <th>Test Plan</th>
    <th>Test Cases</th>
  </tr>
  <tr>
    <td><img width="250" src="https://github.com/user-attachments/assets/14ba78ee-24d3-4062-9cb8-b97633c3529a" alt="Test Plan Screenshot" /></td>
    <td><img width="250" src="https://github.com/user-attachments/assets/dd472407-c2a6-4d5e-b320-f43966d66ef4" alt="Test Cases Screenshot" /></td>
  </tr>
</table>

## CI/CD

GitHub Actions pipeline (`.github/workflows/ci.yml`):

- macOS 14 runner with Xcode 16.2
- DerivedData and SwiftPM dependency caching
- Clean build targeting iPhone 16 Simulator
- Unit test execution with code coverage
- Integration tests available (skipped in CI)

## Screenshots

<table>
  <tr>
    <th>Watchlist</th>
    <th>Stock Picker</th>
    <th>Edit Watchlist</th>
  </tr>
  <tr>
    <td><img width="250" src="https://github.com/user-attachments/assets/f47e92a0-8da8-4769-a04b-0d030031005c" alt="Watchlist Screenshot" /></td>
    <td><img width="250" src="https://github.com/user-attachments/assets/61051964-fc64-4f71-a75d-0c59e5bcd099" alt="Stock Picker Screenshot" /></td>
    <td><img width="250" src="https://github.com/user-attachments/assets/14c66f8d-09c5-4856-95e7-7f464780a426" alt="Edit Watchlist Screenshot" /></td>
  </tr>
</table>

**Demo Video:** https://youtube.com/shorts/u0Ma-Z8fVSY?feature=share

## Roadmap

- [x] Watchlist Module
- [ ] Stock Detail View
- [ ] Orders Module
- [ ] Portfolio Module
- [ ] Positions Module

## Author

**Sakir Saiyed** — Senior iOS Engineer
[LinkedIn](https://www.linkedin.com/in/sakirsaiyed/) | [GitHub](https://github.com/shaqir)

## License

MIT — see [LICENSE](LICENSE) for details.
