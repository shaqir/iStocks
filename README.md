# iStocks – Real-Time Stock Tracker App

[![Codemagic build status](https://api.codemagic.io/apps/YOUR_APP_ID/status_badge.svg)](https://codemagic.io/apps/6882e167f99be74b07eb63d1)

iStocks is a professional, scalable, and test-driven iOS app built with **Swift**, **SwiftUI**, **Combine**, and **Clean Architecture**. It mimics the experience of top trading platforms like Zerodha Kite, delivering real-time stock updates, custom watchlists, and a beautifully responsive UI.

---

## 🚀 Features

- ✅ Real-time stock updates via WebSocket (Twelve Data API)
- ✅ Watchlist creation, editing, and persistence
- ✅ Smooth animations for price changes
- ✅ Search bar with instant filtering
- ✅ Add/remove stocks with validation and limits
- ✅ Offline storage using SwiftData
- ✅ Custom UI with top tabs, themes, and error handling
- ✅ Modular MVVM with Clean Architecture
- ✅ CI/CD via **Codemagic**
- ✅ 90%+ Unit Test Coverage with ViewInspector

---

## 🧠 Architecture

This app follows a strict Clean Architecture with MVVM, designed for large-scale, maintainable projects.

📦 iStocks
┣ 📁 Core                 # Models, DTOs, Mappers
┣ 📁 Data                 # Remote APIs, Repositories, Persistence
┣ 📁 Domain               # UseCases, Protocols, Entities
┣ 📁 Presentation         # Views, ViewModels, UI State
┗ 📁 Shared               # Utilities, Alerts, Constants

**Principles Used:**
- ✅ MVVM + Combine
- ✅ Clean Code & SOLID
- ✅ Dependency Injection
- ✅ Separation of Concerns
- ✅ Reactive UI + Testable Layers

---

## 📸 Screenshots

> *(Insert screenshots of the Watchlist tab, Search bar, Add/Edit Watchlist modal, and Real-time update UI)*

---

## 🧪 Testing

This project is written to be **100% testable** with deep coverage of ViewModels, Repositories, and even SwiftUI views.

| Layer         | Coverage |
|---------------|----------|
| `WatchlistsViewModelTests`         | ✅ |
| `WatchlistViewModelTests`          | ✅ |
| `EditWatchlistViewModelTests`      | ✅ |
| `StockRemoteDataSourceTests`       | ✅ |
| `Persistence Layer` (SwiftData)    | ✅ |
| `QuoteResponseMapperTests`         | ✅ |
| `View Tests (ViewInspector)`       | ✅ |
| `Integration Tests (REST + WebSocket)` | ✅ |

> 📊 Coverage: 90%+ via `xcodebuild` + `ViewInspector`

---

## ⚙️ Requirements

- macOS 13+ (Ventura or later)
- Xcode 15.2 or later (🔁 Downgraded from Xcode 16/26 for CI compatibility)
- iOS 17.0+
- Simulator: iPhone 15 (or any compatible)
- Swift Package Manager

---

## 🛠️ Getting Started

### 1. Clone the Repo

```bash
git clone https://github.com/YOUR_USERNAME/iStocks.git
cd iStocks

2. Open in Xcode

xed .

3. Resolve Packages

xcodebuild -resolvePackageDependencies -project iStocks.xcodeproj -scheme iStocks

4. Build & Run
	•	Select iPhone 15 Simulator (or any)
	•	Press ⌘ + R

⸻

🧪 Running Tests

xcodebuild test \
  -project iStocks.xcodeproj \
  -scheme iStocks \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2'


⸻

🔁 CI/CD – Codemagic

This project is powered by Codemagic for continuous integration and test automation.

✅ Features
	•	Build + test on every push to main
	•	Xcode 15.2 compatibility
	•	Codemagic badge in README
	•	Fastlane-ready (optional)

For setup, see codemagic.yaml

⸻

🌐 APIs Used
	•	Twelve Data for real-time stock prices
	•	Supports REST and WebSocket modes
	•	Mock data mode available for development/testing

⸻

🔍 Watchlist Features
	•	Create up to 10 watchlists
	•	Each watchlist can contain up to 50 stocks
	•	Stocks grouped by sector
	•	Local persistence and sync
	•	Live price refresh with animation
	•	Edit safely while background updates are paused

⸻

📦 Folder Highlights

Folder	Description
Presentation/	SwiftUI views, ViewModels
Domain/	UseCases, Protocols
Data/	Repositories, Remote & Local
Core/	Models, DTOs, Mappers
Shared/	Alert manager, constants, extensions


⸻

🔮 Future Roadmap
	•	Watchlist CRUD & persistence
	•	Real-time stock updates via WebSocket
	•	Combine-based reactive state
	•	SwiftData integration
	•	Unit & View testing
	•	Codemagic integration
	•	GraphQL support
	•	App lifecycle optimization
	•	Multi-device sync (iCloud CoreData or CloudKit)
	•	TestFlight deployment

⸻

👨‍💻 Author

Sakir Saiyed
Senior Mobile Developer | iOS & Flutter Expert
📍 Edmonton, AB, Canada
📬 LinkedIn
🌐 Portfolio: Coming Soon

⸻

📄 License

This project is licensed under the MIT License. See the LICENSE file for details.

⸻

💡 Built as a passion project to master Clean Architecture, Combine, SwiftData, and real-time apps using best practices.

---
