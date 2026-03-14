# Technology Decisions & Future Optimizations

## Document Purpose
This document captures our current technology choices, lessons learned, pain points, and potential upgrade paths for future consideration. It serves as a reference for technical debt management and strategic technology decisions.

**Last Updated**: March 14, 2026

---

## Current Technology Stack

### Development Environment
| Technology | Version | Status | Notes |
|------------|---------|--------|-------|
| Xcode | 26.3 | ✅ Current | Using project format 77 (Xcode 16+ format) |
| iOS Deployment Target | 18.5 | ✅ Current | Cutting edge, may limit CI/CD options |
| Swift | 5.0 | ✅ Current | Stable, widely supported |
| macOS | Latest | ✅ Current | Development on latest macOS version |

### Architecture & Patterns
- **Architecture**: Clean Architecture (Domain/Data/Presentation layers)
- **UI Framework**: SwiftUI (100% declarative UI)
- **State Management**: Combine framework
- **Dependency Injection**: Manual DI with container pattern
- **Data Persistence**: SwiftData
- **Networking**: URLSession with Combine publishers
- **Real-time Updates**: WebSocket (Finnhub) + REST API (TwelveData)

### Key Libraries & Dependencies
```swift
// Package.swift equivalent
dependencies: [
    .package(url: "https://github.com/nalexn/ViewInspector", from: "0.10.2")
]
```

### CI/CD Infrastructure
- **Platform**: GitHub Actions
- **Runner**: macos-15 (M2 hardware)
- **Xcode Version**: 16.4 (fallback to 16.0-16.3)
- **Build Time**: ~5-10 minutes
- **Cost**: Free (public repository)

---

## Lessons Learned

### 1. Project Format Compatibility (Critical)
**Issue**: Xcode 26.3 created project with objectVersion 77, incompatible with older CI Xcode versions.

**Impact**:
- CI pipeline failed completely with format incompatibility error
- Unable to build on Xcode 15.x runners (macOS-14)
- Blocked all automated testing and deployments

**Solution**:
- Upgraded CI to macOS-15 with Xcode 16.4
- Removed IPHONEOS_DEPLOYMENT_TARGET overrides

**Lesson**:
> ⚠️ **Always ensure CI Xcode version matches or exceeds local development Xcode version.** Project format versions are not backward compatible.

**Future Prevention**:
- Monitor GitHub Actions runner versions monthly
- Test CI pipeline immediately after Xcode upgrades
- Consider Xcode version pinning strategy if team uses different versions

### 2. Logging Verbosity Management
**Issue**: Excessive debug/info logging created console noise, making it difficult to identify real issues.

**Impact**:
- 100+ log messages per second during WebSocket updates
- Debug logs for every network request/response
- Success confirmations for routine operations

**Solution**:
- Removed ~25 verbose log statements across 8 files
- Made logging conditional based on frequency (batch operations)
- Kept only warnings, errors, and meaningful events
- Added AppLogger category system for better filtering

**Lesson**:
> 📊 **Log sparingly in production code. Only log: errors, warnings, state changes, and business events. Never log success for routine operations.**

**Best Practices Established**:
```swift
// ❌ Don't do this
AppLogger.debug("Received price update for \(symbol)")  // Fires 50x/sec

// ✅ Do this instead
if updates.count > 100 {
    AppLogger.info("Processing large batch: \(updates.count) updates")
}

// ✅ Always log errors
AppLogger.error("Failed to decode", category: .network, error: error)
```

### 3. iOS Deployment Target Strategy
**Issue**: Using iOS 18.5 (cutting edge) limits CI/CD options and requires newest Xcode.

**Impact**:
- Restricts CI runner choices
- Forces latest Xcode requirement
- May exclude users on older iOS versions

**Current Strategy**: Stay on latest to use newest APIs and frameworks

**Alternative Strategy**:
- Use iOS 17.0 as minimum deployment target for wider compatibility
- Conditionalize new APIs with `@available` checks
- Balances modern features with CI/CD flexibility

**Lesson**:
> 🎯 **Balance cutting-edge iOS features with CI/CD infrastructure availability. Consider N-1 iOS version as deployment target unless new APIs are critical.**

---

## Current Pain Points & Technical Debt

### High Priority

#### 1. CI/CD Platform Limitations
**Current State**: GitHub Actions (free tier)
- ✅ Free for public repos
- ✅ Integrated with GitHub
- ❌ Slower Xcode updates (1-2 weeks behind Apple releases)
- ❌ M2 hardware only (not M2 Pro/M4)
- ❌ Manual setup for code signing and TestFlight
- ❌ ~5-10 minute build times

**Impact**: Medium
- Acceptable for open source project
- May slow down rapid release cycles
- No automated App Store deployment

**Future Consideration**: See "Future Upgrade Paths" section

#### 2. Manual Dependency Injection
**Current State**: Manual DI container pattern
- ✅ Full control, no magic
- ✅ Compile-time safety
- ❌ Boilerplate code for each feature module
- ❌ No automatic dependency graph validation
- ❌ Manual lifecycle management

**Impact**: Low
- Works well for current project size
- May become cumbersome as app scales to 10+ features

**Future Consideration**:
- Swinject (Swift DI framework)
- Needle (Uber's compile-time DI)
- Swift Macros for DI code generation (Swift 5.9+)

#### 3. Combine Framework Deprecation Path
**Current State**: Using Combine for reactive streams
- ✅ Native Apple framework
- ✅ Well integrated with SwiftUI
- ⚠️ Apple moving toward async/await and AsyncSequence
- ⚠️ Combine not getting major updates

**Impact**: Low (current), Medium (long-term)
- Combine still fully supported
- Industry trend toward async/await
- New APIs favor structured concurrency

**Future Consideration**:
- Gradual migration to async/await
- Replace publishers with AsyncSequence
- Use Observation framework (iOS 17+) for state management

**Migration Path**:
```swift
// Current: Combine
func fetchStocks() -> AnyPublisher<[Stock], Error>

// Future: async/await
func fetchStocks() async throws -> [Stock]

// Future: AsyncSequence for streams
func observeStocks() -> AsyncStream<[Stock]>
```

### Medium Priority

#### 4. Testing Infrastructure
**Current State**:
- Unit tests with ViewInspector
- Integration tests (skipped in CI)
- No UI automation tests
- No snapshot testing

**Gaps**:
- Limited SwiftUI view testing coverage
- No automated UI regression testing
- Manual testing for UI changes

**Future Consideration**:
- XCUITest for automated UI testing
- SnapshotTesting library for visual regression
- Increase unit test coverage to 80%+

#### 5. API Key Management
**Current State**: SecureAPIKeyManager with local storage
- ✅ Keys not in source code
- ❌ Manual key management
- ❌ No key rotation strategy
- ❌ Keys stored in repository (gitignored)

**Future Consideration**:
- Environment variable injection at build time
- CI/CD secrets integration
- Runtime key fetching from secure backend
- API key rotation automation

---

## Future Upgrade Paths

### CI/CD Platform Migration (When Needed)

#### Option 1: Bitrise (Recommended for Professional)
**When to Consider**:
- Need Xcode updates within 24 hours of Apple release
- Require automated TestFlight/App Store deployment
- Want faster build times with M4 Pro hardware
- Team grows beyond hobby project

**Migration Effort**: Low (1-2 days)
**Cost**: ~₹3,000/month (Hobby tier: 300 credits/month)

**Benefits**:
- Native iOS/macOS support
- Automated code signing
- TestFlight upload automation
- M4 Pro Apple Silicon runners
- 300+ integrations (Slack, Jira, etc.)

**Migration Steps**:
1. Create Bitrise account and connect GitHub
2. Import existing project
3. Configure code signing certificates
4. Add TestFlight deployment workflow
5. Migrate GitHub Actions to Bitrise YAML
6. Update README with new CI badge

#### Option 2: Jenkins + Fastlane (Recommended for Cost Optimization)
**When to Consider**:
- Have spare Mac hardware or can afford AWS EC2 Mac
- Want zero ongoing costs
- Need full CI/CD customization
- Team has DevOps expertise

**Migration Effort**: High (1-2 weeks)
**Cost**:
- Free (self-hosted)
- OR ~$100-300/month for AWS EC2 Mac instance

**Benefits**:
- 100% free if self-hosted
- Complete control over build environment
- No vendor lock-in
- Can use latest Xcode immediately

**Migration Steps**:
1. Set up Mac mini or AWS EC2 Mac instance
2. Install Jenkins server
3. Install Fastlane and configure lanes
4. Create Jenkinsfile pipeline
5. Configure webhooks from GitHub
6. Set up code signing and provisioning profiles
7. Create Fastlane lanes for build/test/deploy

**Sample Fastlane Configuration**:
```ruby
# fastlane/Fastfile
lane :test do
  run_tests(
    scheme: "iStocks",
    device: "iPhone 16",
    skip_testing: ["iStocksIntegrationTests"]
  )
end

lane :beta do
  build_app(scheme: "iStocks")
  upload_to_testflight
end
```

#### Option 3: Codemagic (Premium Alternative)
**When to Consider**:
- Need absolute fastest builds (M4 Max hardware)
- Flutter or React Native migration in future
- Unlimited build minutes required

**Migration Effort**: Low (1-2 days)
**Cost**: ~₹25,000/month (unlimited builds)

**Not Recommended Unless**: Budget allows premium CI/CD and need cutting-edge hardware

### State Management Migration

#### Observation Framework (iOS 17+)
**When to Consider**: After dropping iOS 16 support

**Benefits**:
- Simpler than Combine
- Better SwiftUI integration
- Automatic dependency tracking
- Less boilerplate

**Migration Example**:
```swift
// Current: Combine
class WatchlistViewModel: ObservableObject {
    @Published var stocks: [Stock] = []
    private var cancellables = Set<AnyCancellable>()
}

// Future: Observation
@Observable
class WatchlistViewModel {
    var stocks: [Stock] = []
    // No need for @Published, cancellables, etc.
}
```

**Migration Effort**: Medium (2-3 weeks)
**Timeline**: Consider after iOS 18.0 becomes minimum target (2027-2028)

### Dependency Injection Frameworks

#### Needle (Compile-time DI)
**When to Consider**: App grows to 15+ feature modules

**Benefits**:
- Compile-time safety
- Dependency graph generation
- Code generation reduces boilerplate
- Used by Uber at scale

**Migration Effort**: High (3-4 weeks)
**Timeline**: Not urgent, consider when DI becomes pain point

### Networking Layer Enhancements

#### Alamofire Migration
**When to Consider**: Need advanced networking features

**Benefits**:
- Request/response interception
- Advanced retry logic
- Better error handling
- Network reachability

**Current Assessment**: URLSession + Combine is sufficient
**Timeline**: Only if complex networking requirements emerge

---

## Technology Selection Criteria

When evaluating new technologies or upgrades, use these criteria:

### 1. Must Have
- ✅ Active maintenance (updated within 6 months)
- ✅ Swift 5.0+ compatibility
- ✅ iOS 17+ support
- ✅ SwiftUI compatibility
- ✅ Good documentation

### 2. Nice to Have
- ⭐ First-party Apple framework (preferred)
- ⭐ Large community and ecosystem
- ⭐ Performance benchmarks available
- ⭐ Migration path from current solution

### 3. Avoid
- ❌ Abandoned projects (no updates >1 year)
- ❌ Objective-C only libraries
- ❌ UIKit-only frameworks
- ❌ Proprietary closed-source solutions
- ❌ Vendor lock-in without clear benefits

---

## Decision Log

### March 14, 2026: CI/CD Platform Decision
**Decision**: Stay with GitHub Actions for now
**Rationale**:
- Free for open source project
- Recently fixed with macOS-15 + Xcode 16 support
- Good enough for current needs
- Can migrate to Bitrise when project goes commercial

**Revisit**: When project needs:
- Automated TestFlight deployment
- Faster build times (>5 min becomes bottleneck)
- Commercial release schedule

### March 14, 2026: Logging Strategy Refinement
**Decision**: Reduce logging verbosity to warnings+ only
**Rationale**:
- Console noise prevented issue identification
- Production logs should be actionable
- AppLogger category system provides filtering

**Implementation**:
- Removed 25+ verbose log statements
- Kept errors, warnings, and state changes only
- Conditional logging for batch operations

### January 2026: Logger Migration
**Decision**: Migrate from print() to os.Logger (AppLogger)
**Rationale**:
- Production-grade logging with categories
- Better performance than print()
- Unified logging system integration
- Searchable and filterable logs

**Status**: ✅ Completed

---

## Monitoring & Review Schedule

### Monthly Review
- [ ] Check GitHub Actions runner updates
- [ ] Review Xcode beta releases
- [ ] Monitor dependency updates (ViewInspector, etc.)
- [ ] Check CI/CD build times

### Quarterly Review
- [ ] Evaluate new iOS SDK features
- [ ] Review technical debt backlog
- [ ] Assess CI/CD platform satisfaction
- [ ] Consider new Swift language features

### Annual Review
- [ ] Major architecture decisions
- [ ] Technology stack evaluation
- [ ] CI/CD platform cost/benefit analysis
- [ ] Dependency framework migrations

---

## Resources & References

### CI/CD Platforms
- [Bitrise](https://bitrise.io) - Mobile-first CI/CD
- [Codemagic](https://codemagic.io) - Flutter/iOS CI/CD
- [GitHub Actions iOS Guide](https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-swift)
- [Fastlane](https://fastlane.tools) - iOS automation tool

### Architecture & Patterns
- [Clean Architecture (Uncle Bob)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Swift by Sundell - Architecture](https://www.swiftbysundell.com/articles/different-flavors-of-dependency-injection-in-swift/)
- [Point-Free - Dependencies](https://www.pointfree.co/collections/dependencies)

### State Management
- [Apple - Observation Framework](https://developer.apple.com/documentation/observation)
- [Combine to async/await Migration](https://www.swiftbysundell.com/articles/replacing-combine-with-async-await/)

### Testing
- [ViewInspector](https://github.com/nalexn/ViewInspector) - SwiftUI testing
- [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing) - Visual regression
- [XCTest Best Practices](https://developer.apple.com/documentation/xctest)

---

## Contributors & Maintenance

**Document Owner**: Sakir Saiyed
**Last Updated**: March 14, 2026
**Next Review**: April 14, 2026

### Change History
- **2026-03-14**: Initial document creation
  - Added current tech stack
  - Documented CI/CD lessons learned
  - Outlined future upgrade paths
  - Established review schedule
