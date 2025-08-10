# iStocks App

A powerful and elegant **iOS stock tracking app** built with **SwiftUI**, **Combine**, and **MVVM CLEAN architecture**. 

- It delivers real-time updates, organized watchlists, and a Kite Zerodha-inspired user experience.
- This is a passion project for **CLEAN Architecutre** with latest tech stacks.
- Only 1 module is completed till now which is Watchlist Module, other modules are in progress.


&#x20;

---

## 💠 Features

* 🔄 Real-time stock updates via **Mock data, REST API and WebSocket API**
* 📊 Organized **Watchlists** with SwiftData persistence
* 🔍 Search & pick stocks with intuitive UX
* 📱 Built with **SwiftUI + Combine**
* 🧠 Clean MVVM architecture + modular components
* 🧪 Unit tested with **XCTest** + ViewInspector
* ✅ Self-hosted **CI Pipelines with GitHub Actions** and Xcode 16

---

## 💠 Tech Stack

| Layer        | Tech/Tool                           |
| ------------ | ----------------------------------- |
| Language     | Swift 5.10                          |
| UI           | SwiftUI                             |
| Reactive     | Combine                             |
| Architecture | MVVM + Clean Architecture           |
| Persistence  | SwiftData                           |
| Networking   | REST & WebSocket (Twelve Data API)  |
| Testing      | XCTest + ViewInspector              |
| CI/CD        | GitHub Actions + Self-Hosted Runner |

---

## 💠 Folder Structure

```
iStocks/
│
├── iStocksApp.swift
├── Resources/                  # Assets, fonts
├── Models/                     # Stock, Watchlist domain models
├── Views/                      # SwiftUI Views (Watchlist, Picker, Tabs)
├── ViewModels/                 # MVVM logic with Combine
├── Services/                   # API Clients, WebSocket, Persistence
├── UseCases/                   # Business Usecases
├── Domain/                     # Domain Logic and models
├── Repositories/               # Repository protocols, implementations 
├── DI/                         # Dependency injection setup
├── Tests/                      # XCTest Unit Tests
└── Utilities/                  # Extensions, Constants, Helpers
```
<img width="510" height="708" alt="Structure" src="https://github.com/user-attachments/assets/433ec79f-0ca7-4126-99c4-a35b4b48cdd9" />

---

## 💠 CI/CD Pipeline

This project uses a **self-hosted GitHub Actions runner on macOS with Xcode 16**.

### 🔧 Workflow Summary (`.github/workflows/ci.yml`)

* Checkout source code
* Set correct Xcode version
* Cache DerivedData and SwiftPM
* Clean build with `xcodebuild`
* Resolve dependencies
* Build for iPhone 16 simulator
* (Optional) Run Unit Tests & Report Coverage

> You can customize this workflow for TestFlight or Fastlane integration later.vg)](https://codecov.io/gh/sakirsaiyed/iStocks)

---

## 💠 Testing

To run tests locally:

```bash
xcodebuild test \
  -project iStocks.xcodeproj \
  -scheme iStocks \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

<table>
  <tr>
    <th>📊 Test Plan</th>
    <th>🧮 TestCases</th>
  </tr>
  <tr>
    <td><img width="250" src="https://github.com/user-attachments/assets/14ba78ee-24d3-4062-9cb8-b97633c3529a" alt="Test Plan Screenshot" /></td>
    <td><img width="250" src="https://github.com/user-attachments/assets/dd472407-c2a6-4d5e-b320-f43966d66ef4" alt="Test Cases Screenshot" /></td>
  </tr>
</table>

Tests are located under `/iStocksTests`, covering ViewModels, Services, and UI (via ViewInspector).

---

## 💠 Requirements

* macOS 14+
* Xcode 16 (Beta)
* iOS 17+ Simulator (iPhone 16 recommended)
* Swift 5.10+

---

## 🔐 Secrets & API Keys

* Uses [Twelve Data API](https://twelvedata.com)
* Store your API key securely in `.env` or CI/CD secrets
* Avoid committing keys to the repo

---

## 📦 Setup Instructions

```bash
git clone https://github.com/your-username/iStocks.git
cd iStocks
open iStocks.xcodeproj
```
---

## 💠 Roadmap

* Watchlist Module - Completed
* Upcoming Modules - Orders, Portfolio, Positions, StockDetails, etc

---

## 📸 Screenshots
<table>
  <tr>
    <th>📊 Watchlist</th>
    <th>🧮 Stock Picker</th>
    <th>📈 Edit Watchlist</th>
  </tr>
  <tr>
    <td><img width="250" src="https://github.com/user-attachments/assets/f47e92a0-8da8-4769-a04b-0d030031005c" alt="Watchlist Screenshot" /></td>
    <td><img width="250" src="https://github.com/user-attachments/assets/61051964-fc64-4f71-a75d-0c59e5bcd099" alt="Stock Picker Screenshot" /></td>
    <td><img width="250" src="https://github.com/user-attachments/assets/14c66f8d-09c5-4856-95e7-7f464780a426" alt="Edit Watchlist Screenshot" /></td>
  </tr>
</table>

🎥 Demo Video

https://github.com/user-attachments/assets/22e8d3cf-b6da-4c6b-a49b-e9572326135b

## 👨‍💼 Author

**Sakir Saiyed**
Senior iOS Developer |
📍 Calgary, Canada |
[LinkedIn](https://www.linkedin.com/in/sakirsaiyed/) |
[GitHub](https://github.com/sakirsaiyed)

---

## 📄 License

This project is licensed under the MIT License.
See the [LICENSE](LICENSE) file for details.
