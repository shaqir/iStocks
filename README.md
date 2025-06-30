iStocks is an App to manage your stocks porfolio.

“I implemented the Watchlist feature in a trading app using SwiftUI + Combine + Clean Architecture. The system is divided into Domain, Data, and Presentation layers. I used UseCase and Repository patterns to cleanly decouple responsibilities. The ViewModel is reactive and interacts with SwiftData for local persistence and Combine for API. It’s modular, testable, and ready to scale.”


Clean Architecture Layers:

Domain           → Business rules, no frameworks
UseCases         → Application logic
Repositories     → Abstract data access
Data Sources     → SwiftData & Network implementations
Presentation     → SwiftUI Views + ViewModel (MVVM)



Domain Layer:

“This layer has no dependency on frameworks and represents business logic only. Easy to test, mock, and evolve.”

Data Layer:

UseCase Layer:

"Bridges domain to data: fetches stocks from repository"
“Each use case follows SRP (Single Responsibility) and is injected with dependencies, making testing easy.”

Presentation Layer

“The view is stateless and reactive. Business logic is completely offloaded to ViewModel, making testing and preview easy.”

readme_content = """
# 📈 Watchlist Module – Clean Architecture + MVVM + Combine (Swift)

This module replicates a **real-time Watchlist feature** like the one in the Kite trading app using **SwiftUI**, **Combine**, **SwiftData**, and **Clean Architecture**.

---

## 🧠 Architecture Overview

Presentation (SwiftUI + ViewModel)
⬇
UseCases (Application Logic)
⬇
Repositories (Interface Layer)
⬇
Data Sources (API + SwiftData)



- **MVVM**: View ↔ ViewModel (with `@Published` binding)
- **Combine**: Data flow & auto-refresh
- **SwiftData**: Persist user-added watchlist symbols
- **Dependency Injection**: Decoupled logic, easier testing and mocking

---

## 💡 Features Implemented

- ✅ MVVM using `@StateObject`, `@Published`, and SwiftUI bindings
- ✅ Combine for API fetching and auto-refresh with `Timer.publish`
- ✅ SwiftData to save/load/delete watchlist items
- ✅ Search bar with `.searchable`
- ✅ Pull-to-refresh with `.refreshable`
- ✅ Grouping by watchlist (e.g., NIFTY 50, Tech)
- ✅ Gain/loss formatting with color & arrow indicators
- ✅ Mock service for SwiftUI previews and tests

---
