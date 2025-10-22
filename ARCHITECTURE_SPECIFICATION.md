# WeDaApp - Architecture Specification Document

**Project**: Weather Dashboard Application (WeDaApp)
**Platform**: iOS
**Framework**: SwiftUI
**Date**: October 2025
**Version**: 1.0

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Overview](#system-overview)
3. [Architecture Patterns](#architecture-patterns)
4. [Module Architecture](#module-architecture)
5. [Data Flow Architecture](#data-flow-architecture)
6. [API Integration Architecture](#api-integration-architecture)
7. [Data Persistence Architecture](#data-persistence-architecture)
8. [Security Architecture](#security-architecture)
9. [Testing Architecture](#testing-architecture)
10. [Component Specifications](#component-specifications)

---

## 1. Executive Summary

WeDaApp is a native iOS weather application built for the Dollar General Mobile Developer Technical Assessment. The application demonstrates enterprise-grade architecture using MVVM pattern, protocol-oriented programming, and Test-Driven Development (TDD) principles.

### Key Architectural Principles

- **Separation of Concerns**: Strict MVVM pattern with clear boundaries
- **Modularity**: Four distinct Swift packages for reusability
- **Testability**: Protocol-based dependency injection throughout
- **Security**: OWASP-compliant data storage and encrypted secrets
- **Scalability**: Generic networking layer supporting future extensions

---

## 2. System Overview

### 2.1 Technology Stack

| Layer | Technology |
|-------|------------|
| UI Framework | SwiftUI |
| Architecture | MVVM (Model-View-ViewModel) |
| Concurrency | Swift Async/Await |
| State Management | Combine (@Published properties) |
| Networking | URLSession with generic APIClient |
| Local Storage | UserDefaults + Keychain |
| Testing | XCTest + Quick/Nimble (BDD) |
| Secrets Management | Arkana |
| Dependency Management | Swift Package Manager |

### 2.2 External Dependencies

- **OpenWeatherMap API**: Weather data provider
- **Nuke**: Async image loading and caching (for weather icons)
- **Quick/Nimble**: BDD testing framework
- **Arkana**: Encrypted secrets management

---

## 3. Architecture Patterns

### 3.1 MVVM Pattern

The application strictly adheres to Model-View-ViewModel pattern:

```
┌─────────────────────────────────────────────────────┐
│                      View Layer                      │
│         (SwiftUI Views - UI/Main/, UI/Common/)      │
└────────────────┬────────────────────────────────────┘
                 │ Observes @Published properties
                 │ Calls ViewModel methods
┌────────────────▼────────────────────────────────────┐
│                   ViewModel Layer                    │
│        (@MainActor ObservableObject classes)        │
│              - Presentation Logic                    │
│              - State Management                      │
└────────────────┬────────────────────────────────────┘
                 │ Calls service protocols
                 │ Transforms domain models
┌────────────────▼────────────────────────────────────┐
│                    Service Layer                     │
│           (Protocol-based business logic)            │
│       - WeatherService, FavoritesService, etc.      │
└────────────────┬────────────────────────────────────┘
                 │ Uses APIClient protocol
                 │ Performs business operations
┌────────────────▼────────────────────────────────────┐
│                   Data Layer                         │
│    - APIClient (NetworkingKit)                      │
│    - DollarGeneralPersist (Local Storage)           │
│    - OpenWeatherMap API                             │
└─────────────────────────────────────────────────────┘
```

#### 3.1.1 View Responsibilities

- Render UI based on ViewModel state
- Handle user interactions
- Navigate to other views
- Apply accessibility identifiers

#### 3.1.2 ViewModel Responsibilities

- Expose @Published properties for View binding
- Handle user actions via async methods
- Transform domain models to presentation models
- Manage loading/error states
- Coordinate service calls

#### 3.1.3 Model Responsibilities

- Define data structures (Codable)
- Represent API responses and local entities
- No business logic

#### 3.1.4 Service Responsibilities

- Implement business logic
- Orchestrate API calls
- Handle data persistence
- Provide protocol-based interfaces

### 3.2 Protocol-Oriented Programming

All dependencies use protocols to enable:
- **Testability**: Mock implementations for unit tests
- **Flexibility**: Easy to swap implementations
- **Decoupling**: Concrete types hidden behind abstractions

**Example**:
```swift
protocol WeatherServiceProtocol {
    func fetchCurrentWeather(city: String) async throws -> WeatherData
    func fetchForecast(city: String) async throws -> ForecastResponse
}

// Production implementation
struct WeatherService: WeatherServiceProtocol { ... }

// Test mock
class MockWeatherService: WeatherServiceProtocol { ... }
```

### 3.3 Dependency Injection

Constructor-based dependency injection throughout:

```swift
@MainActor
final class SearchViewModel: ObservableObject {
    private let service: WeatherServiceProtocol

    init(service: WeatherServiceProtocol = WeatherService()) {
        self.service = service
    }
}
```

---

## 4. Module Architecture

The project is organized into **4 local Swift packages** for maximum modularity and reusability.

### 4.1 NetworkingKit

**Purpose**: Generic HTTP networking abstraction layer

**Components**:

```
NetworkingKit/
├── APIClient.swift          # Protocol defining request interface
├── APIRequest.swift         # Generic request builder
├── APIError.swift           # Standardized error types
├── Endpoint.swift           # Protocol for API endpoints
└── MockAPIClient.swift      # Testing utility
```

**Key Interfaces**:

```swift
public protocol APIClient {
    func request<Response: Decodable>(_ request: APIRequest<Response>) async throws -> Response
}

public protocol Endpoint {
    associatedtype Response: Decodable
    var path: String { get }
    var method: HTTPMethod { get }
    var queryItems: [URLQueryItem] { get }
    var headers: [String: String] { get }
    func build() -> APIRequest<Response>
}

public enum APIError: Error, Equatable {
    case noInternetConnection
    case invalidCity
    case serverError(statusCode: Int, response: String)
    case unknownError
}
```

**Usage Pattern**:
```swift
let client: APIClient = OpenWeatherMapAPIClient()
let request = OpenWeatherMapEndpoint.currentWeather(city: "London").build()
let weather = try await client.request(request)
```

### 4.2 DollarGeneralPersist

**Purpose**: Secure local data storage following OWASP guidelines

**Components**:

```
DollarGeneralPersist/
├── DollarGeneralPersist.swift    # UserDefaults wrapper
├── KeychainManager.swift          # Keychain operations
└── KeysCache.swift                # Cache key constants
```

**Storage Strategy**:

| Data Type | Storage | Reason |
|-----------|---------|--------|
| API Keys (build-time) | ArkanaKeys (encrypted) | Maximum security |
| User tokens (runtime) | Keychain | Secure, encrypted by OS |
| Favorites, History | UserDefaults | Non-sensitive, fast access |
| Cached weather data | UserDefaults | Temporary, non-sensitive |

**Key Interfaces**:

```swift
// UserDefaults wrapper
public class DollarGeneralPersist {
    public static func saveCache(key: String, value: String)
    public static func getCacheData(key: String) -> String?
    public static func removeCache(key: String)
}

// Keychain manager
public class KeychainManager {
    public static func saveAttribute(key: String, value: String)
    public static func retrieveAttribute(key: String) -> String?
    public static func deleteAttribute(key: String)
}

// Cache keys
public struct KeysCache {
    public static let favoriteCities = "FavoriteCities"
    public static let searchHistory = "SearchHistory"
    public static let cachedWeatherData = "CachedWeatherData"
}
```

### 4.3 DollarGeneralTemplateHelpers

**Purpose**: Common utilities, logging, and UI infrastructure

**Components**:

```
DollarGeneralTemplateHelpers/
├── Logging/
│   └── Logger.swift               # LogInfo, LogError, LogDebug
├── Navigation/
│   ├── NavigationStackManager.swift
│   └── NavigationPathProtocol.swift
└── UITestIDs/
    └── UITestIDs.swift            # Accessibility identifiers
```

**Logging System**:
```swift
LogInfo("User searched for city: \(cityName)")
LogError("API request failed: \(error)")
LogDebug("Cache hit for key: \(key)")
```

**Navigation Pattern**:
```swift
enum AppNavigation: NavigationPathProtocol {
    case weatherDetails(city: String)
    case favoriteDetails(favorite: FavoriteCity)

    @ViewBuilder
    var destination: some View {
        switch self {
        case .weatherDetails(let city):
            WeatherDetailsView(viewModel: WeatherDetailsViewModel(city: city))
        case .favoriteDetails(let favorite):
            WeatherDetailsView(viewModel: WeatherDetailsViewModel(city: favorite.cityName))
        }
    }
}
```

**UI Test IDs**:
```swift
public struct UITestIDs {
    public enum SearchView: String {
        case searchField = "search_field"
        case searchButton = "search_button"
        case resultsContainer = "results_container"
    }

    public enum WeatherDetailsView: String {
        case temperatureLabel = "temperature_label"
        case weatherIcon = "weather_icon"
        case forecastList = "forecast_list"
    }
}
```

### 4.4 ArkanaKeys

**Purpose**: Auto-generated encrypted secrets management

**Security Features**:
- Secrets encrypted at build time
- Keys obfuscated in compiled binary
- Never committed to version control
- Generated from `.env` file via Arkana CLI

**Configuration** (`.arkana.yml`):
```yaml
global_secrets:
  - openWeatherMapAPIKey
  - openWeatherMapBaseUrl
```

**Usage**:
```swift
let apiKey = ArkanaKeys.Global().openWeatherMapAPIKey
let baseUrl = ArkanaKeys.Global().openWeatherMapBaseUrl
```

**Build Integration**:
```bash
# Regenerate after updating .env
bundle exec arkana
```

---

## 5. Data Flow Architecture

### 5.1 Request Flow

```
User Interaction
    │
    ▼
┌───────────────────┐
│   SwiftUI View    │
└────────┬──────────┘
         │ .task { await viewModel.method() }
         ▼
┌───────────────────┐
│    ViewModel      │ @Published var weatherData
│   (@MainActor)    │ @Published var isLoading
└────────┬──────────┘ @Published var error
         │ await service.fetchWeather()
         ▼
┌───────────────────┐
│  Service Layer    │ WeatherServiceProtocol
└────────┬──────────┘
         │ await client.request(endpoint.build())
         ▼
┌───────────────────┐
│   APIClient       │ OpenWeatherMapAPIClient
│ (NetworkingKit)   │
└────────┬──────────┘
         │ URLSession.data(for:)
         ▼
┌───────────────────┐
│  OpenWeatherMap   │
│       API         │
└───────────────────┘
```

### 5.2 Response Flow

```
OpenWeatherMap API Response (JSON)
    │
    ▼
┌───────────────────┐
│   APIClient       │ Decodes JSON → WeatherData
│  (NetworkingKit)  │ Maps HTTP errors → APIError
└────────┬──────────┘
         │ returns WeatherData or throws APIError
         ▼
┌───────────────────┐
│  Service Layer    │ Additional business logic
└────────┬──────────┘ Persistence operations
         │
         ▼
┌───────────────────┐
│   ViewModel       │ Sets @Published properties
│  (@MainActor)     │ Ensures main thread execution
└────────┬──────────┘
         │ Automatic Combine notification
         ▼
┌───────────────────┐
│  SwiftUI View     │ Re-renders based on new state
└───────────────────┘
```

### 5.3 State Management

ViewModels manage three types of state:

```swift
@MainActor
final class SearchViewModel: ObservableObject {
    // Data state
    @Published private(set) var weatherData: WeatherData?

    // UI state
    @Published private(set) var isLoading = false

    // Error state
    @Published var error: APIError?
}
```

Views observe and react:
```swift
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if let error = viewModel.error {
                ErrorView(error: error) {
                    Task { await viewModel.retry() }
                }
            } else if let weather = viewModel.weatherData {
                WeatherCard(weather: weather)
            }
        }
    }
}
```

---

## 6. API Integration Architecture

### 6.1 OpenWeatherMap API Client

**Implementation**: `OpenWeatherMapAPIClient.swift`

**Base Configuration**:
```swift
class OpenWeatherMapAPIClient: APIClient {
    private let baseURL: String
    private let apiKey: String
    private let session: URLSession

    init() {
        self.baseURL = ArkanaKeys.Global().openWeatherMapBaseUrl
        self.apiKey = ArkanaKeys.Global().openWeatherMapAPIKey

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
}
```

### 6.2 Endpoint Definitions

**OpenWeatherMapEndpoint** enum:

```swift
enum OpenWeatherMapEndpoint {
    case currentWeather(city: String)
    case currentWeatherByCoordinates(lat: Double, lon: Double)
    case forecast(city: String)
}

extension OpenWeatherMapEndpoint: Endpoint {
    var path: String {
        switch self {
        case .currentWeather, .currentWeatherByCoordinates:
            return "/data/2.5/weather"
        case .forecast:
            return "/data/2.5/forecast"
        }
    }

    var queryItems: [URLQueryItem] {
        var items = [URLQueryItem(name: "appid", value: apiKey),
                     URLQueryItem(name: "units", value: "metric")]

        switch self {
        case .currentWeather(let city), .forecast(let city):
            items.append(URLQueryItem(name: "q", value: city))
        case .currentWeatherByCoordinates(let lat, let lon):
            items.append(URLQueryItem(name: "lat", value: "\(lat)"))
            items.append(URLQueryItem(name: "lon", value: "\(lon)"))
        }

        return items
    }
}
```

### 6.3 API Endpoints

| Endpoint | Method | Purpose | Response Model |
|----------|--------|---------|----------------|
| `/data/2.5/weather?q={city}` | GET | Current weather by city | `WeatherData` |
| `/data/2.5/weather?lat={lat}&lon={lon}` | GET | Current weather by coordinates | `WeatherData` |
| `/data/2.5/forecast?q={city}` | GET | 5-day forecast (3h intervals) | `ForecastResponse` |

### 6.4 Error Mapping

```swift
HTTP Status → APIError Mapping:
    404           → .invalidCity
    401, 403      → .serverError(statusCode, response)
    500-599       → .serverError(statusCode, response)
    Network error → .noInternetConnection
    Other         → .unknownError
```

### 6.5 Request/Response Cycle

```swift
// 1. Build request
let endpoint = OpenWeatherMapEndpoint.currentWeather(city: "London")
let request = endpoint.build()  // APIRequest<WeatherData>

// 2. Execute request
let client = OpenWeatherMapAPIClient()
let weather = try await client.request(request)

// 3. Handle errors
do {
    let weather = try await client.request(request)
    // Success
} catch APIError.invalidCity {
    // Show "City not found"
} catch APIError.noInternetConnection {
    // Load from cache or show offline message
} catch APIError.serverError(let code, let response) {
    // Show server error details
}
```

---

## 7. Data Persistence Architecture

### 7.1 Storage Layers

```
┌─────────────────────────────────────────────────────┐
│              Application Layer                       │
└──────┬─────────────────┬────────────────┬───────────┘
       │                 │                │
       │ Favorites       │ History        │ Cache
       │                 │                │
┌──────▼─────────────────▼────────────────▼───────────┐
│         DollarGeneralPersist (UserDefaults)         │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│              Application Layer                       │
└──────┬──────────────────────────────────────────────┘
       │ Sensitive data (tokens, credentials)
┌──────▼──────────────────────────────────────────────┐
│         KeychainManager (iOS Keychain)              │
└─────────────────────────────────────────────────────┘
```

### 7.2 Data Models

#### Favorites

```swift
public struct FavoriteCity: Codable, Identifiable {
    public let id: String              // UUID
    public let cityName: String        // "London"
    public let country: String?        // "GB"
    public let coordinates: Coordinates // For API calls
    public let addedAt: Date           // Timestamp
}
```

**Storage**: JSON-encoded in UserDefaults under `KeysCache.favoriteCities`

#### Search History

```swift
public struct SearchHistoryItem: Codable, Identifiable {
    public let id: String           // UUID
    public let cityName: String     // "Paris"
    public let country: String?     // "FR"
    public let searchedAt: Date     // Timestamp
}
```

**Storage**: JSON-encoded in UserDefaults under `KeysCache.searchHistory`

#### Weather Cache

**Purpose**: Offline capability - show last fetched data when network unavailable

**Storage**: JSON-encoded `WeatherData` in UserDefaults under city-specific keys

```swift
let cacheKey = "weather_\(cityName.lowercased())"
DollarGeneralPersist.saveCache(key: cacheKey, value: weatherJSON)
```

### 7.3 Persistence Operations

```swift
// Save favorites
func saveFavorites(_ favorites: [FavoriteCity]) {
    let encoder = JSONEncoder()
    if let data = try? encoder.encode(favorites),
       let json = String(data: data, encoding: .utf8) {
        DollarGeneralPersist.saveCache(key: KeysCache.favoriteCities, value: json)
    }
}

// Load favorites
func loadFavorites() -> [FavoriteCity] {
    guard let json = DollarGeneralPersist.getCacheData(key: KeysCache.favoriteCities),
          let data = json.data(using: .utf8) else {
        return []
    }
    return (try? JSONDecoder().decode([FavoriteCity].self, from: data)) ?? []
}
```

---

## 8. Security Architecture

### 8.1 Security Layers

```
┌─────────────────────────────────────────────────────┐
│          Build-Time Secrets (API Keys)              │
│                  ArkanaKeys                          │
│         (Encrypted, obfuscated in binary)           │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│       Runtime Secrets (Tokens, Credentials)         │
│              iOS Keychain                            │
│     (Hardware-encrypted, app-sandboxed)             │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│          Non-Sensitive Data (Favorites)             │
│              UserDefaults                            │
│              (App-sandboxed)                         │
└─────────────────────────────────────────────────────┘
```

### 8.2 OWASP Compliance

**OWASP MASVS Requirements Met**:

| Requirement | Implementation |
|-------------|----------------|
| MSTG-STORAGE-1: Sensitive data not in system logs | Logging excludes PII (GPS coordinates, precise location). Only logs authorization states and city names. |
| MSTG-STORAGE-2: No sensitive data in external storage | All data stored in app sandbox. No data written to shared locations. |
| MSTG-STORAGE-14: Encryption for sensitive data | iOS Keychain (hardware-backed AES-256) for runtime secrets. API keys encrypted via Arkana. |
| MSTG-CRYPTO-1: Proven crypto libraries | iOS native Keychain and Arkana obfuscation. No custom cryptography. |
| MSTG-NETWORK-1: Network security | HTTPS enforced via App Transport Security. No plaintext HTTP connections. |

**Privacy Compliance:**
- Location data (GPS coordinates) never logged to system
- NSLocationWhenInUseUsageDescription provides clear usage explanation
- Location permission requested only once, user choice respected
- All location data processed in-memory only, not persisted

### 8.3 Secrets Management Flow

```
Development Phase:
    .env file (gitignored)
        │
        ▼
    bundle exec arkana
        │
        ▼
    ArkanaKeys package (auto-generated)
        │
        ▼
    Encrypted + Obfuscated code
        │
        ▼
    Compiled into app binary

Runtime Phase:
    ArkanaKeys.Global().openWeatherMapAPIKey
        │
        ▼
    Deobfuscation in memory
        │
        ▼
    Used for API request
        │
        ▼
    Cleared from memory
```

### 8.4 Network Security

```swift
// HTTPS only (enforced by ATS)
// App Transport Security enabled in Info.plist

// Certificate pinning (optional enhancement)
// URLSession with custom ServerTrustEvaluating
```

---

## 9. Testing Architecture

### 9.1 Test Pyramid

```
                    ┌─────────────┐
                    │   UI Tests  │  (Planned - XCUITest)
                    │   (E2E)     │
                    └─────────────┘
                  ┌───────────────────┐
                  │ Integration Tests │  (Service + API layer)
                  │    (XCTest)       │
                  └───────────────────┘
            ┌─────────────────────────────────┐
            │      Unit Tests                 │  (ViewModels, Models)
            │  (XCTest + Quick/Nimble)       │
            └─────────────────────────────────┘
```

### 9.2 Test-Driven Development (TDD) Workflow

```
1. Write failing test
    │
    ▼
2. Implement minimum code to pass
    │
    ▼
3. Refactor while keeping tests green
    │
    ▼
4. Repeat
```

### 9.3 Test Structure

```
WeDaAppTests/
├── UnitTests/
│   ├── ViewModels/
│   │   ├── SearchViewModelTests.swift
│   │   ├── WeatherDetailsViewModelTests.swift
│   │   └── FavoritesViewModelTests.swift
│   ├── Services/
│   │   ├── WeatherServiceTests.swift
│   │   └── FavoritesServiceTests.swift
│   └── Models/
│       └── WeatherDataTests.swift
├── IntegrationTests/
│   ├── NetworkingIntegrationTests.swift
│   └── PersistenceIntegrationTests.swift
└── Quick/
    └── SearchViewModelSpec.swift (BDD style)
```

### 9.4 Mocking Strategy

**Protocol-based mocks**:

```swift
class MockAPIClient: APIClient {
    var result: Decodable?
    var error: Error?

    func request<Response: Decodable>(_ request: APIRequest<Response>) async throws -> Response {
        if let error = error {
            throw error
        }
        guard let result = result as? Response else {
            throw APIError.unknownError
        }
        return result
    }
}

class MockWeatherService: WeatherServiceProtocol {
    var weatherData: WeatherData?
    var forecastData: ForecastResponse?
    var shouldThrowError = false

    func fetchCurrentWeather(city: String) async throws -> WeatherData {
        if shouldThrowError { throw APIError.invalidCity }
        return weatherData!
    }
}
```

### 9.5 Test Coverage Goals

| Layer | Target Coverage |
|-------|-----------------|
| ViewModels | 90%+ |
| Services | 85%+ |
| Models | 95%+ |
| APIClient | 80%+ |
| Overall | 85%+ |

### 9.6 Example Test Case

```swift
@MainActor
final class SearchViewModelTests: XCTestCase {
    func test_search_success_updatesWeatherData() async {
        // Given - Arrange
        let mockClient = MockAPIClient()
        mockClient.result = WeatherData.mock(name: "London")
        let service = WeatherService(apiClient: mockClient)
        let viewModel = SearchViewModel(service: service)

        // When - Act
        await viewModel.search(city: "London")

        // Then - Assert
        XCTAssertNil(viewModel.error)
        XCTAssertNotNil(viewModel.weatherData)
        XCTAssertEqual(viewModel.weatherData?.name, "London")
        XCTAssertFalse(viewModel.isLoading)
    }

    func test_search_invalidCity_setsError() async {
        // Given
        let mockClient = MockAPIClient()
        mockClient.error = APIError.invalidCity
        let viewModel = SearchViewModel(service: WeatherService(apiClient: mockClient))

        // When
        await viewModel.search(city: "InvalidCity123")

        // Then
        XCTAssertEqual(viewModel.error, .invalidCity)
        XCTAssertNil(viewModel.weatherData)
    }
}
```

---

## 10. Component Specifications

### 10.1 Core Features

#### Feature 1: City Search

**View**: `SearchView.swift`
**ViewModel**: `SearchViewModel.swift`
**Service**: `WeatherService.swift`

**User Flow**:
1. User enters city name
2. Taps search button
3. Loading state shown
4. Weather data displayed or error shown

**State Management**:
```swift
@Published private(set) var searchResults: [WeatherData] = []
@Published private(set) var isLoading = false
@Published var error: APIError?
```

#### Feature 2: Weather Details

**View**: `WeatherDetailsView.swift`
**ViewModel**: `WeatherDetailsViewModel.swift`

**Displays**:
- Current weather (temperature, conditions, humidity, wind)
- 5-day forecast (daily high/low, conditions)
- Weather icons
- Add to favorites button

#### Feature 3: Favorites Management

**View**: `FavoritesView.swift`
**ViewModel**: `FavoritesViewModel.swift`
**Service**: `FavoritesService.swift`

**Operations**:
- Add city to favorites
- Remove from favorites
- Load favorites from persistence
- Quick access to favorite cities' weather

#### Feature 4: Search History

**View**: `HistoryView.swift`
**ViewModel**: `HistoryViewModel.swift`

**Features**:
- Display recent searches (limit 20)
- Tap to re-search
- Clear history option

### 10.2 Common UI Components

#### LoadingView
Shimmer/skeleton screen during async operations

#### ErrorView
```swift
ErrorView(error: APIError, retryAction: () -> Void)
```
Displays localized error message with retry button

#### WeatherCard
Reusable card displaying weather information

### 10.3 Navigation Architecture

**MainTabView** - Root tab container:
- Search tab
- Favorites tab
- History tab

**NavigationStack** with enum-based routing for deep navigation

---

## Appendix A: Directory Structure

```
WeDaApp.xcworkspace
├── WeDaApp/
│   ├── Code/
│   │   ├── Application/
│   │   │   └── WeDaAppApp.swift (@main)
│   │   ├── UI/
│   │   │   ├── Main/
│   │   │   │   ├── MainTabView.swift
│   │   │   │   ├── Search/
│   │   │   │   │   ├── SearchView.swift
│   │   │   │   │   └── SearchViewModel.swift
│   │   │   │   ├── WeatherDetails/
│   │   │   │   ├── Favorites/
│   │   │   │   └── History/
│   │   │   └── Common/
│   │   │       ├── LoadingView.swift
│   │   │       ├── ErrorView.swift
│   │   │       └── WeatherCard.swift
│   │   ├── Models/
│   │   │   ├── Weather/
│   │   │   │   ├── WeatherData.swift
│   │   │   │   └── ForecastResponse.swift
│   │   │   └── Local/
│   │   │       ├── FavoriteCity.swift
│   │   │       └── SearchHistoryItem.swift
│   │   └── Dependencies/
│   │       ├── APIClient/
│   │       │   ├── OpenWeatherMapAPIClient.swift
│   │       │   └── OpenWeatherMapEndpoint.swift
│   │       └── Services/
│   │           ├── WeatherService.swift
│   │           └── FavoritesService.swift
│   └── Resources/
│       └── Assets.xcassets
├── NetworkingKit/
├── DollarGeneralPersist/
├── DollarGeneralTemplateHelpers/
├── ArkanaKeys/
└── WeDaAppTests/
```

---

## Appendix B: Build Commands

```bash
# Build project
xcodebuild -workspace WeDaApp.xcworkspace -scheme WeDaApp -configuration Debug build

# Run all tests
xcodebuild test -workspace WeDaApp.xcworkspace -scheme WeDaApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test class
xcodebuild test -workspace WeDaApp.xcworkspace -scheme WeDaApp \
  -only-testing:WeDaAppTests/SearchViewModelTests \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Regenerate encrypted secrets
bundle exec arkana

# Update Swift Package dependencies
xcodebuild -resolvePackageDependencies -workspace WeDaApp.xcworkspace
```

---

## Appendix C: Assessment Criteria Alignment

| Criterion | Weight | Architecture Implementation |
|-----------|--------|----------------------------|
| **Code Quality** | 20% | MVVM, protocol-oriented design, separation of concerns, modularity via Swift packages |
| **Functionality & UI/UX** | 25% | 4 complete features, loading/error states, responsive SwiftUI design |
| **State Management** | 30% | Combine with @Published, MVVM with ViewModels, local persistence, offline capability |
| **Testing & TDD** | 25% | TDD workflow, comprehensive unit/integration tests, protocol-based mocking |

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | October 2025 | System Architect | Initial architecture specification |

---

**End of Architecture Specification Document**
