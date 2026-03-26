# iStocks Setup Guide

## Prerequisites

- **Xcode**: 15.0 or later
- **iOS**: 17.0 or later
- **Swift**: 5.9 or later
- **macOS**: 13.0 or later (for development)

## Initial Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd iStocks
```

### 2. Configure API Keys

The app requires API keys from two providers:

#### Finnhub API (WebSocket real-time data)
1. Sign up at [finnhub.io](https://finnhub.io/)
2. Get your free API key from the dashboard

#### Twelve Data API (REST API stock quotes)
1. Sign up at [twelvedata.com](https://twelvedata.com/)
2. Get your free API key

#### Set API Keys

**Option A: Environment Variables (Recommended)**

```bash
export FINNHUB_API_KEY="your_finnhub_key_here"
export TWELVE_DATA_API_KEY="your_twelve_data_key_here"
```

Add these to your `~/.zshrc` or `~/.bash_profile` for persistence.

**Option B: Info.plist**

1. Open `iStocks/Resources/Info.plist`
2. Add the following keys:

```xml
<key>FINNHUB_API_KEY</key>
<string>your_finnhub_key_here</string>
<key>TWELVE_DATA_API_KEY</key>
<string>your_twelve_data_key_here</string>
```

**Security Note**: Never commit API keys to version control. Add Info.plist to `.gitignore` if using this method.

### 3. Install Dependencies

This project uses only native iOS frameworks (no external dependencies).

```bash
# No package manager setup required
```

### 4. Open in Xcode

```bash
open iStocks.xcodeproj
```

Or double-click `iStocks.xcodeproj` in Finder.

### 5. Select Build Configuration

The app supports three modes:

- **Mock Mode** (default for Debug): Uses fake data, no API keys required
- **REST API Mode**: Uses TwelveData API for stock quotes
- **WebSocket Mode**: Uses Finnhub WebSocket for real-time updates

To change mode:

**Option A: Environment Variable**

```bash
# In Xcode: Product > Scheme > Edit Scheme > Run > Arguments > Environment Variables
WATCHLIST_MODE = "mock"    # or "rest" or "websocket"
```

**Option B: Code (temporary)**

Edit `AppConfiguration.swift`:

```swift
static var watchlistMode: WatchlistAppMode {
    return .mock  // Change to .restAPI or .websocket
}
```

## Build and Run

### Debug Build

1. Select target device or simulator
2. Press `⌘R` or click the Play button
3. App launches with mock data by default

### Release Build

1. Edit scheme: Product > Scheme > Edit Scheme
2. Change Build Configuration to "Release"
3. Build: `⌘B`

## Running Tests

### Unit Tests

```bash
# In Xcode
⌘U

# Or via command line
xcodebuild test -scheme iStocks -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Integration Tests

```bash
xcodebuild test -scheme iStocks -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:iStocksIntegrationTests
```

## Configuration Options

### Logging

Control logging verbosity in `AppConfiguration.swift`:

```swift
static var isLoggingEnabled: Bool {
    #if DEBUG
    return true
    #else
    return false  // Disable in production
    #endif
}
```

View logs in Console.app filtered by subsystem: `com.iStocks`

### Feature Flags

Enable/disable features in `AppConfiguration.swift`:

```swift
static var isWebSocketEnabled: Bool {
    #if DEBUG
    return true
    #else
    return false
    #endif
}
```

## Troubleshooting

### Issue: "API key is missing" error

**Solution**: Verify API keys are configured correctly. Check:
1. Environment variables are set
2. Info.plist contains keys (if using that method)
3. Run `SecureAPIKeyManager.printConfigurationStatus()` in debug

### Issue: "Rate limit exceeded"

**Solution**: 
- Free tier has rate limits
- Wait a few minutes before retrying
- Consider upgrading API plan
- Use Mock mode for development

### Issue: WebSocket connection fails

**Solution**:
- Check internet connection
- Verify Finnhub API key is valid
- Check firewall/proxy settings
- Enable WebSocket mode in configuration

### Issue: Build fails with "Cannot find type 'AppLogger'"

**Solution**:
- Clean build folder: `⌘⇧K`
- Rebuild: `⌘B`
- Verify `Logger.swift` is in the project

### Issue: SwiftData errors on first launch

**Solution**:
- Delete app from simulator/device
- Clean build folder
- Rebuild and run

## Development Workflow

### Adding a New Feature

1. Create feature branch: `git checkout -b feature/my-feature`
2. Follow Clean Architecture structure
3. Add domain models in `Domain/Entities/`
4. Create use cases in `Domain/UseCases/`
5. Implement repository in `Data/Repositories/`
6. Create ViewModels in `Presentation/ViewModel/`
7. Build UI in `Presentation/View/`
8. Write tests
9. Submit pull request

### Code Style

- Follow existing patterns
- Use SwiftLint (if configured)
- Document public APIs
- Write tests for business logic

## Debugging Tips

### Logging

```swift
AppLogger.debug("Debug message", category: .network)
AppLogger.info("Info message", category: .viewModel)
AppLogger.error("Error occurred", category: .persistence, error: error)
```

### Breakpoints

- Set breakpoints in ViewModels for state changes
- Use symbolic breakpoints for crashes
- Enable exception breakpoints

### Memory Debugging

- Instruments > Leaks
- Instruments > Allocations
- Enable malloc stack logging

### Network Debugging

- Charles Proxy for HTTP inspection
- Xcode Network Inspector
- Check Console.app for network logs

## Production Deployment

### Before Release

1. [ ] Update version number in project settings
2. [ ] Switch to Release build configuration
3. [ ] Verify API keys are in secure storage (not source code)
4. [ ] Run all tests
5. [ ] Test on physical devices
6. [ ] Profile for performance
7. [ ] Archive and export for App Store

### App Store Requirements

- Screenshots for all device sizes
- App privacy details
- Age rating
- Description and keywords
- Support URL

## Resources

- [Architecture Documentation](./ARCHITECTURE.md)
- [README](./README.md)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Finnhub API Docs](https://finnhub.io/docs/api)
- [Twelve Data API Docs](https://twelvedata.com/docs)

## Support

For issues:
1. Check this setup guide
2. Review architecture documentation
3. Check existing GitHub issues
4. Create new issue with:
   - Xcode version
   - iOS version
   - Steps to reproduce
   - Error messages/logs
