# WeDaApp - Weather Dashboard Application

A complete iOS weather dashboard application built with SwiftUI and MVVM architecture for the Dollar General Mobile Developer Technical Assessment.

## 📋 Project Overview

**WeDaApp** (Weather Dashboard Application) is a native iOS application that:
- Fetches weather data from OpenWeatherMap API
- Displays current weather conditions and 5-day forecasts
- Allows users to save favorite cities
- Maintains search history
- Supports offline capability through local caching
- Follows TDD (Test-Driven Development) approach

**Time Allocation**: 4-6 hours
**Framework**: Native iOS (SwiftUI + Swift)
**Architecture**: MVVM with Protocol-Based Dependency Injection

---

## 🏗️ Architecture

### High-Level Structure

```
WeDaApp (MVVM Architecture)
├── Models (WeatherData, ForecastData, FavoriteCity, SearchHistory)
├── Views (SwiftUI components)
├── ViewModels (@MainActor ObservableObject classes)
├── Services (Protocol-based business logic)
└── Dependencies (API Client, Local Storage)
```

### Swift Packages (Modular Approach)

The project is organized into **4 local Swift packages**:

1. **NetworkingKit** - Generic HTTP networking layer
   - `APIClient` protocol
   - `APIRequest<Response>` generic request builder
   - `APIError` enum
   - `MockAPIClient` for testing

2. **DollarGeneralPersist** - Local data persistence
   - `KeychainManager` for sensitive data
   - UserDefaults helpers
   - Cache key constants

3. **DollarGeneralTemplateHelpers** - UI utilities & navigation
   - Logging functions
   - Navigation protocols
   - UI Test accessibility identifiers

4. **ArkanaKeys** - Encrypted secrets management
   - Auto-generated from `.env` file
   - Stores OpenWeatherMap API key securely

---

## 🚀 Setup Instructions

### Prerequisites

- Xcode 15.0 or later
- iOS 15.0+ deployment target
- macOS 13.0+ (for development)
- OpenWeatherMap API Key ([Get one here](https://openweathermap.org/api))
- Ruby (for Arkana gem)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/jesersu/Weather-Dashboard-Application.git
   cd WeatherDashboardApp
   ```

2. **Install dependencies**
   ```bash
   # Install Arkana for secrets management
   bundle install
   ```

3. **Configure API Keys**

   Create a `.env` file in the project root:
   ```bash
   cp .env .env.local
   ```

   Edit `.env.local` and add your OpenWeatherMap API key:
   ```
   OpenWeatherMapAPIKey=YOUR_ACTUAL_API_KEY_HERE
   OpenWeatherMapBaseUrl=https://api.openweathermap.org
   ```

   **⚠️ Important**: Never commit `.env.local` or actual API keys to version control!

4. **Generate encrypted secrets**
   ```bash
   bundle exec arkana
   ```

   This generates encrypted keys in `ArkanaKeys/ArkanaKeys/Sources/ArkanaKeys/`

5. **Open the project**
   ```bash
   open WeDaApp.xcworkspace
   ```

   **Note**: You'll need to create the Xcode workspace file first (see Current Status section below)

6. **Build and Run**
   - Select a simulator or device
   - Press `Cmd + R` to build and run

---

## 🧪 Running Tests

### Run All Tests
```bash
xcodebuild test -workspace WeDaApp.xcworkspace -scheme WeDaApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Run Specific Test Suites
```bash
# Unit tests only
xcodebuild test -workspace WeDaApp.xcworkspace -scheme WeDaApp -only-testing:WeDaAppTests/UnitTests -destination 'platform=iOS Simulator,name=iPhone 15'

# Integration tests only
xcodebuild test -workspace WeDaApp.xcworkspace -scheme WeDaApp -only-testing:WeDaAppTests/IntegrationTests -destination 'platform=iOS Simulator,name=iPhone 15'

# Quick/Nimble BDD tests
xcodebuild test -workspace WeDaApp.xcworkspace -scheme WeDaApp -only-testing:WeDaAppTests/Quick -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## 📂 Project Structure

```
WeatherDashboardApp/
├── WeDaApp/                                # Main app target
│   ├── Code/
│   │   ├── Application/                    # App entry point
│   │   ├── UI/
│   │   │   ├── Main/
│   │   │   │   ├── Search/                # City search screen
│   │   │   │   ├── WeatherDetails/        # Current weather & forecast
│   │   │   │   ├── Favorites/             # Favorite cities management
│   │   │   │   └── History/               # Search history
│   │   │   └── Common/                    # Reusable UI components
│   │   ├── Models/
│   │   │   ├── Weather/                   # WeatherData, ForecastData
│   │   │   └── Local/                     # FavoriteCity, SearchHistory
│   │   └── Dependencies/
│   │       ├── APIClient/                 # OpenWeatherMapAPIClient
│   │       ├── WeatherService/            # Business logic layer
│   │       └── LocalStorageService/       # Favorites & history management
│   └── Resources/
├── WeDaAppTests/                          # Test suite
│   ├── UnitTests/                         # XCTest unit tests
│   ├── IntegrationTests/                  # End-to-end tests
│   └── Quick/                             # BDD tests (Quick + Nimble)
├── NetworkingKit/                         # HTTP networking package
├── DollarGeneralPersist/                 # Persistence package
├── DollarGeneralTemplateHelpers/         # UI helpers package
├── ArkanaKeys/                           # Encrypted secrets package
├── .arkana.yml                           # Arkana configuration
├── .env                                  # Environment template (gitignored)
├── .gitignore
├── Gemfile
└── README.md
```

---

## 🎯 Features Implementation Status

### ✅ Completed

- [x] **Project Structure**
  - Directory structure created
  - Swift package modularization
  - Arkana secrets management setup
  - Git configuration

- [x] **Swift Packages**
  - NetworkingKit (generic HTTP layer)
  - DollarGeneralPersist (local storage)
  - DollarGeneralTemplateHelpers (UI utilities)
  - ArkanaKeys (encrypted secrets)

- [x] **Data Models**
  - `WeatherData` - Current weather
  - `ForecastData` - 5-day forecast
  - `FavoriteCity` - User favorites
  - `SearchHistoryItem` - Search history

- [x] **API Integration**
  - `OpenWeatherMapAPIClient` - HTTP client implementation
  - `OpenWeatherMapEndpoint` - Endpoint definitions
  - Error handling (invalid city, no internet, server errors)
  - Request building with query parameters

### 🚧 In Progress / To Do

- [ ] **Xcode Project Files**
  - Create `.xcodeproj` file
  - Create `.xcworkspace` file
  - Link all Swift packages
  - Configure build settings

- [ ] **Services Layer (TDD)**
  - [ ] Write WeatherService tests first
  - [ ] Implement WeatherService
  - [ ] Write LocalStorageService tests first
  - [ ] Implement favorites/history persistence

- [ ] **ViewModels (TDD)**
  - [ ] SearchViewModel + tests
  - [ ] WeatherDetailsViewModel + tests
  - [ ] FavoritesViewModel + tests
  - [ ] HistoryViewModel + tests

- [ ] **UI Screens**
  - [ ] Search Screen
  - [ ] Weather Details Screen (current + forecast)
  - [ ] Favorites Screen
  - [ ] History Screen
  - [ ] TabView navigation

- [ ] **Common UI Components**
  - [ ] LoadingView (shimmer/skeleton)
  - [ ] ErrorView (with retry button)
  - [ ] WeatherCard (reusable weather display)
  - [ ] ForecastCard (5-day forecast item)

- [ ] **Testing**
  - [ ] Unit tests for all services
  - [ ] Unit tests for all ViewModels
  - [ ] Widget/Component tests for UI
  - [ ] Integration tests for user flows
  - [ ] Offline capability tests

- [ ] **Features**
  - [ ] Offline caching
  - [ ] Pull-to-refresh
  - [ ] Search input validation
  - [ ] Temperature unit toggle (°C/°F)
  - [ ] Accessibility (VoiceOver, Dynamic Type)

- [ ] **Documentation**
  - [ ] CLAUDE.md for future Claude Code instances
  - [ ] Inline code documentation
  - [ ] Video demo (2-3 minutes)

---

## 🔑 API Integration

### OpenWeatherMap API Endpoints

**Current Weather**:
```
GET https://api.openweathermap.org/data/2.5/weather?q={city}&appid={API_key}&units=metric
```

**5-Day Forecast**:
```
GET https://api.openweathermap.org/data/2.5/forecast?q={city}&appid={API_key}&units=metric
```

### Error Handling

The app handles the following error scenarios:
- **404**: City not found (invalid city name)
- **401/403**: Unauthorized (invalid API key)
- **Network errors**: No internet connection
- **Timeout**: Request timeout after 30 seconds
- **Unknown errors**: Catch-all for unexpected issues

---

## 🧪 Testing Strategy (TDD Approach)

### Test Pyramid

1. **Unit Tests** (XCTest)
   - API service tests (mocked network)
   - Data model decoding tests
   - ViewModel business logic tests
   - Local storage tests

2. **Widget/Component Tests**
   - SearchBar renders correctly
   - WeatherCard displays data properly
   - LoadingView shows during async operations
   - ErrorView displays with retry button

3. **Integration Tests** (Quick + Nimble)
   - Search flow: Input → API call → Display results
   - Favorites flow: Add → Save → Display → Remove
   - Offline flow: Load cached data when offline
   - History flow: Track searches automatically

### TDD Workflow

```
1. Write failing test
2. Implement minimum code to pass
3. Refactor
4. Repeat
```

**Example**:
```swift
// 1. Write test first
func test_searchWeather_success() async {
    // Given
    let mockClient = MockAPIClient()
    mockClient.result = mockWeatherData
    let service = WeatherService(apiClient: mockClient)
    let viewModel = SearchViewModel(service: service)

    // When
    await viewModel.search(city: "London")

    // Then
    XCTAssertNil(viewModel.error)
    XCTAssertNotNil(viewModel.weatherData)
}

// 2. Implement to pass test
// 3. Refactor if needed
```

---

## 🏆 Assessment Criteria Alignment

| Criteria | Weight | Implementation |
|----------|--------|----------------|
| **Code Quality** | 20% | • Clean MVVM architecture<br>• Protocol-based design<br>• Modular Swift packages<br>• Comprehensive error handling |
| **Functionality & UI/UX** | 25% | • All 4 screens (Search, Details, Favorites, History)<br>• Responsive design<br>• Loading/error states<br>• Native iOS patterns |
| **State Management & Architecture** | 30% | • Combine + @Published<br>• Local persistence (UserDefaults + Keychain)<br>• MVVM separation<br>• Offline capability |
| **Testing & TDD** | 25% | • Tests written first<br>• Unit + Widget + Integration tests<br>• Mock-based testing<br>• XCTest + Quick/Nimble |

---

## 📝 Notes for Developers

### Adding New Features

1. **TDD Approach**: Always write tests first
2. **Protocol-Based**: Create protocol before concrete implementation
3. **Dependency Injection**: Use constructor injection
4. **Error Handling**: Use `APIError` enum
5. **Accessibility**: Add `UITestIDs` for all UI elements

### Secrets Management

- Never hardcode API keys
- Use Arkana for build-time encryption
- Store runtime secrets in Keychain (via `KeychainManager`)
- Keep `.env` files out of version control

### Architecture Patterns

**ViewModel Example**:
```swift
@MainActor
final class SearchViewModel: ObservableObject {
    @Published private(set) var weatherData: WeatherData?
    @Published private(set) var isLoading = false
    @Published var error: APIError?

    private let service: WeatherServiceProtocol

    init(service: WeatherServiceProtocol = WeatherService()) {
        self.service = service
    }

    func search(city: String) async {
        isLoading = true
        error = nil
        do {
            weatherData = try await service.fetchCurrentWeather(city: city)
        } catch let apiError as APIError {
            self.error = apiError
        } catch {
            self.error = .unknownError
        }
        isLoading = false
    }
}
```

---

## 🐛 Known Issues

- Xcode project/workspace files not yet created
- Need to set up Quick/Nimble dependencies
- TrustKit certificate pinning not configured
- No UI implementation yet

---

## 📚 Dependencies

### Swift Package Manager

- **Nuke** (or similar) - For remote image loading
- **Quick** - BDD testing framework
- **Nimble** - Matcher framework for expressive tests

### Ruby Gems

- **arkana** - Encrypted secrets management

---

## 👥 Contributing

This is an assessment project for Dollar General. Follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests first (TDD)
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

---

## 📄 License

This project is created for the Dollar General Mobile Developer Technical Assessment.

---

## 🆘 Support

For questions or issues:
1. Check this README
2. Review the assessment PDF (`assesment.pdf`)
3. Check the CLAUDE.md file for architecture guidance

---

## ✨ Current Status Summary

### What's Built ✅

1. **Complete Swift package architecture** - NetworkingKit, DollarGeneralPersist, DollarGeneralTemplateHelpers, ArkanaKeys
2. **Data models** - WeatherData, ForecastData, FavoriteCity, SearchHistory
3. **API client** - OpenWeatherMapAPIClient with full error handling
4. **Endpoint definitions** - Current weather & forecast endpoints
5. **Secrets management** - Arkana configuration and setup
6. **Project structure** - All directories and file organization

### Next Steps 🚧

1. **Create Xcode project files** (.xcodeproj, .xcworkspace)
2. **Write tests first** (TDD approach)
3. **Implement services** (WeatherService, LocalStorageService)
4. **Build ViewModels** with tests
5. **Create UI screens** (Search, Weather Details, Favorites, History)
6. **Add offline capability** with caching
7. **Polish UI/UX** with accessibility

---

**Ready to continue development!** 🚀
