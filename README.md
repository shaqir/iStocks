# iStocks

> **Production-ready iOS stock tracking app** with real-time price updates, multiple data sources, and Clean Architecture.

[![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-18.5+-blue.svg)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![Xcode](https://img.shields.io/badge/Xcode-26.3-blue.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://img.shields.io/badge/CI-Disabled-red.svg)](TECH_DECISIONS.md#march-14-2026-cicd-temporarily-disabled)

A modern iOS stock market app featuring multiple watchlists, real-time price tracking, and flexible data sources. Built with **133 Swift files** using Clean Architecture + MVVM for maintainability and testability.

**[📺 Demo Video](https://youtube.com/shorts/u0Ma-Z8fVSY?feature=share)** | **[📖 Architecture Docs](ARCHITECTURE.md)** | **[🚀 Setup Guide](SETUP.md)** | **[🔧 Tech Decisions](TECH_DECISIONS.md)**

---

## ✨ Features

- **Multiple Watchlists** - Create up to 10 watchlists with up to 10 stocks each
- **Real-time Updates** - Live price feeds via WebSocket (Finnhub) or REST API (TwelveData)
- **Offline Mode** - Mock data for testing and demos (no API keys needed)
- **Fast Search** - Debounced symbol search (300ms) across all stocks
- **Batch Operations** - Add/remove multiple stocks with progress tracking
- **Persistence** - SwiftData storage with automatic sync
- **P&L Tracking** - Real-time profit/loss and percentage gain calculations
- **Stock Research** - Integrated WebView-based research with bookmarks and navigation
- **Accessibility** - VoiceOver foundation with dedicated accessibility identifiers
- **Tab Navigation** - Custom tab bar with 7 feature modules
- **Clean UI** - Inspired by professional trading platforms (Kite by Zerodha)

---

## 🏗️ Architecture

Built with **Clean Architecture** principles for separation of concerns and testability:

```
┌─────────────────────────────────────────────────────┐
│  PRESENTATION LAYER (SwiftUI + MVVM)                │
│  • WatchlistsViewModel (orchestration)               │
│  • WatchlistViewModel (single list)                 │
│  • EditWatchlistViewModel (CRUD operations)         │
└─────────────────────────────────────────────────────┘
                       ↓ ↑
┌─────────────────────────────────────────────────────┐
│  DOMAIN LAYER (Business Logic)                      │
│  • Entities: Stock, Watchlist                       │
│  • Use Cases: ObserveTop50, FetchQuotes, etc.       │
│  • Protocols: Repository interfaces                 │
└─────────────────────────────────────────────────────┘
                       ↓ ↑
┌─────────────────────────────────────────────────────┐
│  DATA LAYER (Implementation)                        │
│  • Repositories: Mock, REST, WebSocket              │
│  • Data Sources: Remote API, WebSocket, Local DB    │
│  • DTOs & Mappers: API response transformations     │
└─────────────────────────────────────────────────────┘
```

**Key Benefits:**
- **Testability** - Business logic isolated from UI and data sources
- **Flexibility** - Swap data sources without changing UI code
- **Maintainability** - Clear separation of responsibilities
- **Scalability** - Easy to add new features or data sources

**[→ Full Architecture Documentation](ARCHITECTURE.md)**

---

## 🚀 Quick Start

### Prerequisites

- **macOS**: Latest (14.0+)
- **Xcode**: 26.3+ (project format version 77)
- **iOS**: 18.5+ (Simulator or Device)
- **Swift**: 5.10+

### Installation

```bash
# Clone repository
git clone https://github.com/shaqir/iStocks.git
cd iStocks

# Open in Xcode
open iStocks.xcodeproj

# Build and run (⌘R)
# App runs in mock mode by default - no setup needed!
```

### Data Source Modes

The app supports three modes (configurable in `AppConfiguration.swift`):

| Mode | Description | API Keys Required |
|------|-------------|-------------------|
| **Mock** | Pre-loaded stock data | ❌ No |
| **REST API** | TwelveData batch requests | ✅ Yes |
| **WebSocket** | Finnhub real-time streaming | ✅ Yes |

**[→ Complete Setup Guide](SETUP.md)**

---

## 🔧 Configuration

### Switching Data Modes

The app automatically selects the mode based on build configuration:

```swift
// Debug builds → Mock mode (no API keys needed)
// Release builds → REST API mode

// Override via environment variable:
export WATCHLIST_MODE="mock"      // or "rest" or "websocket"
```

### API Keys (REST/WebSocket only)

```bash
# Option 1: Environment variables (recommended)
export FINNHUB_API_KEY="your_finnhub_key"
export TWELVE_DATA_API_KEY="your_twelve_data_key"

# Option 2: Add to Info.plist (don't commit!)
# See SETUP.md for details
```

Get free API keys:
- **TwelveData**: [twelvedata.com](https://twelvedata.com)
- **Finnhub**: [finnhub.io](https://finnhub.io)

---

## 📊 Tech Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Language** | Swift 5.10 | Modern, safe, performant |
| **UI** | SwiftUI (100%) | Declarative, reactive UI |
| **Architecture** | Clean Architecture + MVVM | Separation of concerns |
| **Reactive** | Combine | Async data streams (publishers, subjects) |
| **Persistence** | SwiftData | Local database with relationships |
| **Networking** | URLSession | HTTP + WebSocket (Finnhub) |
| **Logging** | os.Logger | Category-based production-grade logs |
| **Testing** | XCTest + ViewInspector | Unit, integration, and UI tests |
| **CI/CD** | GitHub Actions | Automated testing (temporarily disabled) |
| **Fonts** | Inter 28pt | Custom typography |
| **Dependencies** | None (native only) | Zero external runtime dependencies |

---

## 🧪 Testing

**18 test files** (26 total test + helper files) covering ViewModels, repositories, persistence, mappers, networking, and UI components.

```bash
# Run all tests
xcodebuild test \
  -project iStocks.xcodeproj \
  -scheme iStocks \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Or in Xcode: ⌘U
```

**Test Coverage:**
- ✅ ViewModels — `WatchlistsViewModel`, `WatchlistViewModel`, `EditWatchlistViewModel`, `WatchlistViewModelProvider`, `WatchlistTabViewModel`
- ✅ Repositories — Mock and REST implementations, data fetching, retry logic
- ✅ Networking — `URLSessionNetworkClient`, `NetworkError`, `Endpoint`, `QuoteEndpoint`
- ✅ Data Sources — `StockRemoteDataSource` with mock network client
- ✅ Persistence — SwiftData CRUD operations
- ✅ Mappers — `QuoteResponseMapper` (standard + extended)
- ✅ UI Components — `StockPickerView` (ViewInspector), `SharedAlertManager`
- ✅ Utilities — `AppConstants`, `Array+Extensions`

<details>
<summary><b>📸 Test Screenshots</b></summary>

<table>
  <tr>
    <th>Test Plan</th>
    <th>Test Results</th>
  </tr>
  <tr>
    <td><img width="350" src="https://github.com/user-attachments/assets/14ba78ee-24d3-4062-9cb8-b97633c3529a" alt="Test Plan" /></td>
    <td><img width="350" src="https://github.com/user-attachments/assets/dd472407-c2a6-4d5e-b320-f43966d66ef4" alt="Test Results" /></td>
  </tr>
</table>

</details>

---

## 📱 Screenshots

<table>
  <tr>
    <th>Watchlist View</th>
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

## 📁 Project Structure

```
iStocks/                              # 104 source files
├── App/                              # App entry point (iStocksApp.swift)
├── Core/                             # Shared utilities
│   ├── Accessibility/                # AccessibilityIdentifiers
│   ├── Constants/                    # AppConstants, AppStrings, AppFonts
│   ├── Extensions/                   # Double, Color, Font, Array extensions
│   └── Utilities/                    # AppConfiguration, AppError, SecureAPIKeyManager
├── Features/
│   ├── Watchlist/                    # Main feature (fully implemented)
│   │   ├── Domain/                   # Business logic
│   │   │   ├── Entities/             # Stock, Watchlist models
│   │   │   ├── Repositories/         # Repository protocols
│   │   │   ├── UseCases/             # ObserveStocks, FetchQuotes, etc.
│   │   │   └── Shared/              # Shared domain types
│   │   ├── Data/                     # Data layer
│   │   │   ├── DataSources/          # Remote, WebSocket, Local, Mock
│   │   │   ├── Repositories/         # Mock, REST, WebSocket, GraphQL impls
│   │   │   ├── DTOs/                 # API response models
│   │   │   └── Mappers/             # DTO → Domain transformations
│   │   └── Presentation/            # UI layer
│   │       ├── DI/                   # Dependency injection container
│   │       ├── ViewModel/            # 4 ViewModels + provider
│   │       └── View/                 # SwiftUI views
│   ├── Research/                     # WebView-based stock research
│   ├── Dashboard/                    # Dashboard (placeholder)
│   ├── Portfolio/                    # Portfolio (placeholder)
│   ├── Orders/                       # Orders (placeholder)
│   ├── Positions/                    # Positions (placeholder)
│   └── Settings/                     # Settings (placeholder)
├── Shared/                           # Cross-cutting concerns
│   ├── Networking/                   # NetworkClient, Endpoint, URLSession impl
│   ├── Components/                   # Alert, Logging (SharedAlertManager, AppLogger)
│   └── TabBar/                       # Custom tab navigation (5 files)
└── Resources/                        # Assets, Inter fonts, Info.plist

iStocksTests/                         # 26 test + helper files
iStocksIntegrationTests/              # Integration test suite
```

**Visual Diagram:**

<img width="510" alt="Project Structure" src="https://github.com/user-attachments/assets/433ec79f-0ca7-4126-99c4-a35b4b48cdd9" />

---

## 🎯 Key Implementations

### Strategy Pattern for Data Sources
Three interchangeable repository implementations behind a unified protocol:
```swift
protocol WatchlistRepository {
    func observeStocks() -> AnyPublisher<[Stock], Error>
}

// Switch with one line:
static let mode: WatchlistAppMode = .mock  // or .restAPI or .websocket
```

### Batched API Requests
REST API fetches 50 stocks in batches of 8 to respect rate limits:
- Automatic retry with exponential backoff
- Progress tracking for UX feedback
- Incremental loading (only fetch missing stocks)

### WebSocket Price Streaming
Real-time updates with smart batching:
- 1-second collection window
- Deduplication by symbol (latest price wins)
- Automatic reconnection with backoff
- Heartbeat to maintain connection

### Error Handling
Comprehensive error types with recovery suggestions:
```swift
enum AppError: LocalizedError {
    case network(NetworkError)
    case persistence(PersistenceError)
    case validation(ValidationError)
    case webSocket(WebSocketError)
    case configuration(ConfigurationError)
}
```

### Logging
Production-grade logging with `os.Logger`:
- Category-based filtering (network, websocket, persistence, etc.)
- Log levels (debug, info, warning, error, fault)
- Privacy-safe logging
- Filterable in Console.app

---

## 🔄 CI/CD Pipeline

GitHub Actions workflow (`.github/workflows/ci.yml`) — **temporarily disabled** due to Xcode 26.3 incompatibility with GitHub Actions runners (see [TECH_DECISIONS.md](TECH_DECISIONS.md#march-14-2026-cicd-temporarily-disabled)):

```yaml
✓ macOS 14 runner with Xcode 16.2
✓ Dependency caching (SwiftPM + DerivedData)
✓ Clean build validation
✓ Unit test execution with coverage
✓ Code quality checks
```

**Future CI/CD options under evaluation**: Bitrise, Jenkins + Fastlane

[![CI Status](https://github.com/shaqir/iStocks/workflows/CI/badge.svg)](https://github.com/shaqir/iStocks/actions)

---

## 📈 Code Quality

**Architecture Score: 9.3/10**

| Metric | Score | Details |
|--------|-------|---------|
| **Architecture** | 9.5/10 | Clean Architecture + MVVM with strict layer separation |
| **Error Handling** | 9.5/10 | 5 error domains: Network, Persistence, Validation, WebSocket, Configuration |
| **Thread Safety** | 9.0/10 | @MainActor + actor isolation, proper Combine cancellable management |
| **Security** | 9.5/10 | SecureAPIKeyManager (env vars > Info.plist), no hardcoded keys |
| **Documentation** | 9.0/10 | 5 documentation files (40+ pages), inline docs |
| **Testing** | 8.5/10 | 18 test files covering all layers, growing coverage |

**Design Patterns Used:**
Strategy (data sources) · Repository · Dependency Injection · Singleton · Observer (Combine) · Factory

**[→ See Full Improvements Report](IMPROVEMENTS.md)**

---

## 🗺️ Roadmap

**Completed:**
- [x] **Watchlist Module** - Multiple watchlists with real-time updates
- [x] **Search & Filter** - Debounced symbol search (300ms)
- [x] **Data Sources** - Mock, REST API (TwelveData), WebSocket (Finnhub)
- [x] **Persistence** - SwiftData integration with relationships
- [x] **Research Module** - WebView-based stock research with bookmarks
- [x] **Testing** - 18 test files across all architecture layers
- [x] **CI/CD** - GitHub Actions pipeline (temporarily disabled)
- [x] **Accessibility** - VoiceOver foundation with identifiers
- [x] **Tab Navigation** - Custom tab bar with 7 modules
- [x] **Logging** - Production-grade os.Logger with categories

**In Progress / Planned:**
- [ ] **Stock Detail View** - Charts, news, fundamentals
- [ ] **Orders Module** - Place and track orders (UI scaffold exists)
- [ ] **Portfolio Module** - Holdings overview (UI scaffold exists)
- [ ] **Positions Module** - Active positions tracking (UI scaffold exists)
- [ ] **Settings Module** - App preferences (UI scaffold exists)
- [ ] **Dashboard Module** - Market overview (UI scaffold exists)
- [ ] **Price Alerts** - Push notifications
- [ ] **Dark Mode** - Full theme support
- [ ] **iPad Support** - Optimized layout
- [ ] **Localization** - Multi-language support
- [ ] **Async/Await Migration** - Replace Combine with async/await + AsyncSequence
- [ ] **Observation Framework** - iOS 18+ modern state management

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the existing code style and architecture
4. Add tests for new functionality
5. Update documentation as needed
6. Submit a pull request

**See [ARCHITECTURE.md](ARCHITECTURE.md) for code style guidelines.**

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Sakir Saiyed**
Senior iOS Engineer | Clean Architecture Advocate

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-blue?style=flat&logo=linkedin)](https://www.linkedin.com/in/sakirsaiyed/)
[![GitHub](https://img.shields.io/badge/GitHub-Follow-black?style=flat&logo=github)](https://github.com/shaqir)

---

## 📚 Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed architecture guide with layer diagrams
- **[SETUP.md](SETUP.md)** - Complete setup and configuration instructions
- **[TECH_DECISIONS.md](TECH_DECISIONS.md)** - Technology choices, trade-offs, and future paths
- **[IMPROVEMENTS.md](IMPROVEMENTS.md)** - Code quality improvements and changelog

---

## 🙏 Acknowledgments

- **UI Inspiration**: Kite by Zerodha
- **API Providers**: TwelveData, Finnhub
- **Architecture**: Clean Architecture by Uncle Bob

---

<p align="center">
  <b>Built with ❤️ using Swift and SwiftUI</b>
  <br>
  <sub>⭐ Star this repo if you found it helpful!</sub>
</p>
