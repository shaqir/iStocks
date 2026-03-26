# iStocks Architecture Documentation

## Overview

iStocks is an iOS stock market tracking application built using Clean Architecture principles with MVVM pattern. The app supports multiple data sources (Mock, REST API, WebSocket) and provides real-time stock price updates.

## Architecture Layers

### 1. Domain Layer (Business Logic)
**Location**: `Features/Watchlist/Domain/`

The domain layer contains pure Swift code with no external dependencies.

#### Entities
- **Stock**: Core business model representing a stock with price, quantity, P&L calculations
- **Watchlist**: Collection of stocks grouped by sector or user preference

#### Use Cases
- `ObserveMockStocksUseCase`: Observe mock stock data for testing
- `ObserveTop50StocksUseCase`: Fetch top 50 NYSE stocks
- `ObserveStockPricesUseCase`: Real-time price updates via WebSocket
- `ObserveWatchlistStocksUseCase`: Watch specific stocks
- `FetchStocksBySymbolUseCase`: Fetch quotes for specific symbols

#### Repositories (Protocols)
- `WatchlistRepository`: Base protocol
- `RestStockRepository`: REST API operations
- `StockLiveRepository`: WebSocket operations
- `MockWatchlistRepository`: Mock data for testing

### 2. Data Layer (Data Management)
**Location**: `Features/Watchlist/Data/`

#### Data Sources
- **Local**: SwiftData persistence (WatchlistEntity, StockEntity)
- **Remote**: REST API integration (TwelveData)
- **WebSocket**: Real-time updates (Finnhub)
- **Mock**: Testing and development

#### DTOs (Data Transfer Objects)
- `StockDTO`: API response mapping
- `StockPriceDTO`: Price data from REST
- `StockFinnPriceDTO`: Price data from WebSocket
- `StockQuoteDTO`: Quote information

#### Mappers
- Convert DTOs to domain models
- Handle response wrapping and error mapping

#### Repository Implementations
- `MockStockRepositoryImpl`: Returns mock data
- `RestStockRepositoryImpl`: REST API with batch processing
- `WebSocketStockRepositoryImpl`: WebSocket subscriptions

### 3. Presentation Layer (UI & ViewModels)
**Location**: `Features/Watchlist/Presentation/`

#### ViewModels
- **WatchlistsViewModel**: Manages multiple watchlists, coordinates data loading
- **WatchlistViewModel**: Single watchlist with stock updates
- **EditWatchlistViewModel**: Watchlist creation and editing

#### Views
- SwiftUI views organized by feature
- Reusable components (WatchlistRow, SearchBar, etc.)
- Error and loading states

### 4. Shared/Core Layer
**Location**: `Shared/` and `Core/`

#### Networking
- `NetworkClient`: Protocol for network operations
- `URLSessionNetworkClient`: Implementation with Combine/async-await
- Error handling with `NetworkError`

#### Logging
- `AppLogger`: Production-grade logging using os.Logger
- Category-based logging (network, websocket, persistence, etc.)

#### Configuration
- `AppConfiguration`: Environment-based settings
- Feature flags and build configurations

#### Utilities
- Extensions for Double, Color, Font, Array
- Constants for app-wide values
- Error types and validation

## Data Flow

### Mock Mode
```
WatchlistsViewModel
    ↓
ObserveMockStocksUseCase
    ↓
MockStockRepositoryImpl
    ↓
MockStockData (static data)
```

### REST API Mode
```
WatchlistsViewModel
    ↓
ObserveTop50StocksUseCase
    ↓
RestStockRepositoryImpl
    ↓
StockRemoteDataSource
    ↓
URLSessionNetworkClient
    ↓
TwelveData API
```

### WebSocket Mode
```
WatchlistsViewModel
    ↓
ObserveStockPricesUseCase
    ↓
WebSocketStockRepositoryImpl
    ↓
FinnhubWebSocketClient
    ↓
Finnhub WebSocket
```

## Dependency Injection

The app uses a centralized DI container:

```swift
@MainActor
final class WatchlistDIContainer {
    static func makeWatchlistUseCases(context: ModelContext) -> WatchlistUseCases
    static func makeWatchlistsViewModel(...) -> WatchlistsViewModel
}
```

**Benefits**:
- Testability: Easy to inject mocks
- Flexibility: Switch between data sources
- Thread Safety: @MainActor annotation
- Caching: Singleton repositories

## Threading Model

### Main Thread (@MainActor)
- All ViewModels marked with @Published
- DI Container operations
- UI updates

### Background Threads
- Network requests automatically dispatched
- Results returned to main thread via `.receive(on: DispatchQueue.main)`

### WebSocket
- Dedicated URLSession delegate queue
- Message processing on main thread

## State Management

### Published Properties
ViewModels expose state via `@Published` properties:
- `watchlists`: Current watchlist data
- `isLoading`: Loading state
- `errorMessage`: Error display
- `selectedIndex`: Current tab

### Combine Publishers
- Price updates flow through Combine pipelines
- PassthroughSubject for events
- AnyPublisher for exposed streams

## Persistence

### SwiftData
- `WatchlistEntity`: Persistent watchlist storage
- `StockEntity`: Stock data with relationships
- In-memory contexts for testing

### Strategy
- Save on mutations (add/update/delete)
- Load on app launch
- Incremental updates for REST mode

## Error Handling

### Error Types
- `NetworkError`: HTTP and network issues
- `PersistenceError`: Database failures
- `ValidationError`: Business rule violations
- `WebSocketError`: WebSocket connection issues
- `ConfigurationError`: Missing or invalid configuration

### Error Recovery
- Automatic retry for retryable errors
- User-facing error messages with suggestions
- Logging for debugging

## Configuration Management

### Build Configurations
- **Development**: Mock data, verbose logging
- **Staging**: REST API, moderate logging
- **Production**: REST API, minimal logging

### Feature Flags
- `isWebSocketEnabled`: Toggle WebSocket support
- `isMockDataEnabled`: Allow mock data
- Environment variables for runtime config

## Testing Strategy

### Unit Tests
- ViewModels with mock repositories
- Repository implementations
- Use cases
- Mappers and DTOs

### Integration Tests
- End-to-end data flow
- Persistence layer
- Network layer

### Test Helpers
- In-memory SwiftData contexts
- Mock implementations
- Test fixtures

## Security

### API Key Management
- `SecureAPIKeyManager`: Centralized key access
- Environment variables preferred
- Info.plist fallback
- No hardcoded keys in source

### Data Protection
- SwiftData encryption (when enabled)
- No sensitive data in logs (production)

## Performance Optimizations

### Caching
- Repository singleton pattern
- ViewModel reuse via provider
- Symbol-based stock lookup dictionary

### Batch Processing
- REST API batch requests (8 stocks at a time)
- Progress tracking for UX
- Rate limit handling

### WebSocket
- Selective symbol subscription
- Heartbeat for connection keep-alive
- Automatic reconnection with backoff

## Future Improvements

1. **GraphQL Integration**: Planned data source
2. **Offline Mode**: Enhanced local caching
3. **Push Notifications**: Price alerts
4. **SwiftUI Lifecycle**: Full async/await migration
5. **Accessibility**: VoiceOver and Dynamic Type
6. **Analytics**: User behavior tracking
7. **Crash Reporting**: Production monitoring

## Code Style Guidelines

- PascalCase for types
- camelCase for properties/methods
- 4-space indentation
- Protocol-oriented design
- Value types (structs) preferred
- Comprehensive documentation comments
- Error handling over force unwrapping

## Resources

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [MVVM Pattern](https://www.swiftbysundell.com/articles/different-flavors-of-view-models-in-swift/)
- [SwiftUI Best Practices](https://developer.apple.com/tutorials/swiftui)
- [Combine Framework](https://developer.apple.com/documentation/combine)
