# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**WeDaApp** (Weather Dashboard Application) is a native iOS weather app built with SwiftUI and MVVM architecture for the Dollar General Mobile Developer Technical Assessment. The app fetches weather data from OpenWeatherMap API, implements local data persistence, and follows Test-Driven Development (TDD) principles.

---

## Core Architecture

### MVVM Pattern

The app strictly follows MVVM with protocol-based dependency injection:

- **Views**: SwiftUI components in `WeDaApp/Code/UI/`
- **ViewModels**: `@MainActor` classes conforming to `ObservableObject`, accept dependencies via constructor
- **Models**: Codable data structures in `WeDaApp/Code/Models/`
- **Services**: Protocol-based business logic in `WeDaApp/Code/Dependencies/`

### Data Flow
```
View → ViewModel → Service → APIClient → Endpoint → OpenWeatherMap API
```

Example:
```
SearchView → SearchViewModel → WeatherService → OpenWeatherMapAPIClient → OpenWeatherMapEndpoint
```

---

## Swift Packages Architecture

The project uses **4 local Swift packages** for modularity:

### 1. NetworkingKit
Generic HTTP networking layer used across the entire app.

**Key Components**:
- `APIClient` protocol: Generic interface for making HTTP requests
- `APIRequest<Response>`: Type-safe request builder with generics
- `APIError` enum: Standardized error handling (.noInternetConnection, .serverError, .invalidCity, .unknownError)
- `Endpoint` protocol: Defines how to construct API requests
- `MockAPIClient`: Testing helper for mocking network responses

**Location**: `NetworkingKit/Sources/NetworkingKit/`

**Usage**:
```swift
let client: APIClient = OpenWeatherMapAPIClient()
let request = OpenWeatherMapEndpoint.currentWeather(city: "London").build()
let weather = try await client.request(request)
```

### 2. DollarGeneralPersist
Secure local data storage following OWASP recommendations.

**Key Components**:
- `KeychainManager`: Manages sensitive data storage in iOS Keychain
  - `saveAttribute(key:value:)`: Store sensitive data
  - `retrieveAttribute(key:)`: Retrieve sensitive data
  - `deleteAttribute(key:)`: Remove sensitive data
- `DollarGeneralPersist`: UserDefaults wrapper for simple caching
  - `getCacheData(key:)`: Retrieve cached string
  - `saveCache(key:value:)`: Save string to cache
  - `removeCache(key:)`: Delete cached data
- `KeysCache`: Cache key constants (favoriteCities, searchHistory, cachedWeatherData, etc.)

**Location**: `DollarGeneralPersist/Sources/DollarGeneralPersist/`

**Usage**:
```swift
// Save favorites
let favorites = try JSONEncoder().encode(favoriteCities)
DollarGeneralPersist.saveCache(key: KeysCache.favoriteCities, value: String(data: favorites, encoding: .utf8)!)

// Keychain for sensitive data
KeychainManager.saveAttribute(key: "apiToken", value: secretToken)
```

### 3. DollarGeneralTemplateHelpers
Common UI utilities, logging, and navigation infrastructure.

**Key Components**:
- Logging: `LogInfo()`, `LogError()`, `LogDebug()`
- Navigation protocols: `NavigationStackManager`, `NavigationPathProtocol`
- UI Test IDs: Accessibility identifiers organized by screen
  - `UITestIDs.SearchView`
  - `UITestIDs.WeatherDetailsView`
  - `UITestIDs.FavoritesView`
  - `UITestIDs.HistoryView`
  - `UITestIDs.Common`

**Location**: `DollarGeneralTemplateHelpers/Sources/DollarGeneralTemplateHelpers/`

**Usage**:
```swift
LogInfo("Fetching weather for \(city)")
.accessibilityIdentifier(UITestIDs.SearchView.searchButton.rawValue)
```

### 4. ArkanaKeys
Auto-generated encrypted secrets. **Never edit these files directly** - use Arkana CLI tool.

**Stores**:
- `openWeatherMapAPIKey`: API key for OpenWeatherMap
- `openWeatherMapBaseUrl`: Base URL for API requests

**Location**: `ArkanaKeys/ArkanaKeys/Sources/ArkanaKeys/` (auto-generated)

**Usage**:
```swift
let apiKey = ArkanaKeys.Global().openWeatherMapAPIKey
let baseUrl = ArkanaKeys.Global().openWeatherMapBaseUrl
```

---

## Data Models

### Weather Models

**WeatherData** - Current weather response:
```swift
public struct WeatherData: Codable, Identifiable {
    let id: Int
    let name: String  // City name
    let coord: Coordinates
    let weather: [Weather]  // Weather conditions
    let main: MainWeatherData  // Temp, humidity, pressure
    let wind: Wind
    let sys: Sys  // Country, sunrise, sunset
}
```

**ForecastResponse** - 5-day forecast:
```swift
public struct ForecastResponse: Codable {
    let list: [ForecastItem]  // 40 items (3-hour intervals)
    let city: City
}

public struct ForecastItem: Codable, Identifiable {
    let dt: Int
    let main: MainWeatherData
    let weather: [Weather]
    let pop: Double  // Probability of precipitation
    let dtTxt: String
}
```

### Local Storage Models

**FavoriteCity** - User's favorite cities:
```swift
public struct FavoriteCity: Codable, Identifiable {
    let id: String
    let cityName: String
    let country: String?
    let coordinates: Coordinates
    let addedAt: Date
}
```

**SearchHistoryItem** - Search history:
```swift
public struct SearchHistoryItem: Codable, Identifiable {
    let id: String
    let cityName: String
    let country: String?
    let searchedAt: Date
}
```

---

## API Integration

### OpenWeatherMap Endpoints

**Current Weather**:
```
GET /data/2.5/weather?q={city}&appid={key}&units=metric
```

**5-Day Forecast**:
```
GET /data/2.5/forecast?q={city}&appid={key}&units=metric
```

**By Coordinates**:
```
GET /data/2.5/weather?lat={lat}&lon={lon}&appid={key}&units=metric
```

### OpenWeatherMapAPIClient

The API client handles:
- URL construction with query parameters
- HTTP status code validation
- Error mapping (404 → invalidCity, network errors → noInternetConnection)
- JSON decoding with detailed error messages
- 30-second timeout

**Error Handling**:
```swift
do {
    let weather = try await client.request(request)
} catch APIError.invalidCity {
    // Handle invalid city
} catch APIError.noInternetConnection {
    // Handle offline
} catch APIError.serverError(let statusCode, let response) {
    // Handle server errors
}
```

---

## Key Patterns and Conventions

### Protocol-Based Dependency Injection

Always use protocols to enable testing:

```swift
// Define protocol
protocol WeatherServiceProtocol {
    func fetchCurrentWeather(city: String) async throws -> WeatherData
    func fetchForecast(city: String) async throws -> ForecastResponse
}

// Concrete implementation
struct WeatherService: WeatherServiceProtocol {
    let apiClient: APIClient

    init(apiClient: APIClient = OpenWeatherMapAPIClient()) {
        self.apiClient = apiClient
    }
}

// ViewModel accepts protocol
@MainActor
class SearchViewModel: ObservableObject {
    private let service: WeatherServiceProtocol

    init(service: WeatherServiceProtocol = WeatherService()) {
        self.service = service
    }
}
```

### Async/Await Throughout

All async operations use modern async/await:
- Use `@MainActor` on ViewModels to ensure UI updates on main thread
- Services and APIClient use `async throws` functions
- No legacy callbacks or completion handlers

**Example**:
```swift
@MainActor
final class SearchViewModel: ObservableObject {
    @Published private(set) var weatherData: WeatherData?
    @Published private(set) var isLoading = false
    @Published var error: APIError?

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

### Navigation Pattern

Custom NavigationStackManager with enum-based routing:

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

### State Management

ViewModels use `@Published` properties for reactive updates:

```swift
@Published private(set) var weatherData: WeatherData?
@Published private(set) var isLoading = false
@Published var error: APIError?
```

### Error Handling

Use `APIError` enum with localized descriptions:
- `.noInternetConnection` - Network unavailable
- `.invalidCity` - 404 city not found
- `.serverError(statusCode: Int, response: String)` - Server errors
- `.unknownError` - Catch-all

Display errors using the reusable `ErrorView` component with retry functionality.

### Accessibility

Always add accessibility identifiers for UI testing:

```swift
.accessibilityIdentifier(UITestIDs.SearchView.searchButton.rawValue)
.accessibilityAddTraits(.isButton)
```

---

## Testing (TDD Approach)

### Test Structure

1. **Unit Tests** (XCTest): `WeDaAppTests/UnitTests/`
2. **Integration Tests** (XCTest): `WeDaAppTests/IntegrationTests/`
3. **BDD Tests** (Quick + Nimble): `WeDaAppTests/Quick/`

### TDD Workflow

**Always write tests first**:
1. Write failing test
2. Implement minimum code to pass
3. Refactor
4. Repeat

**Example**:
```swift
@MainActor
final class SearchViewModelTests: XCTestCase {
    func test_search_success() async {
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
        XCTAssertEqual(viewModel.weatherData?.name, "London")
    }

    func test_search_invalidCity() async {
        // Given
        let mockClient = MockAPIClient()
        mockClient.error = APIError.invalidCity
        let viewModel = SearchViewModel(service: WeatherService(apiClient: mockClient))

        // When
        await viewModel.search(city: "InvalidCity")

        // Then
        XCTAssertEqual(viewModel.error, .invalidCity)
        XCTAssertNil(viewModel.weatherData)
    }
}
```

### Mock Objects

Always use mock implementations via protocols:

```swift
let mockClient = MockAPIClient()
mockClient.result = mockWeatherData
// or
mockClient.error = APIError.noInternetConnection
```

---

## Common Development Tasks

### Adding a New Feature

1. **Write tests first** (TDD)
2. Create models in `WeDaApp/Code/Models/`
3. Create service protocol in `WeDaApp/Code/Dependencies/`
4. Implement service with real API client
5. Create ViewModel with `@MainActor` and `ObservableObject`
6. Create SwiftUI View
7. Add navigation case if needed
8. Add accessibility identifiers

### Adding a New API Endpoint

1. Add endpoint case to `OpenWeatherMapEndpoint` enum
2. Implement `Endpoint` protocol methods (path, query, method, headers)
3. Create/update response model conforming to `Codable`
4. Update service to use new endpoint
5. Write tests for the new endpoint

### Adding New Secrets

1. Add secret to `.env` file: `NEW_SECRET=value`
2. Add secret name to `.arkana.yml` under `global_secrets:`
3. Run `bundle exec arkana` to regenerate
4. Access via `ArkanaKeys.Global().newSecret`

### Managing Local Persistence

**Favorites**:
```swift
// Save
let data = try JSONEncoder().encode(favorites)
DollarGeneralPersist.saveCache(key: KeysCache.favoriteCities, value: String(data: data, encoding: .utf8)!)

// Load
let json = DollarGeneralPersist.getCacheData(key: KeysCache.favoriteCities)
let favorites = try JSONDecoder().decode([FavoriteCity].self, from: json.data(using: .utf8)!)
```

**Search History**:
```swift
// Similar pattern to favorites
DollarGeneralPersist.saveCache(key: KeysCache.searchHistory, value: historyJSON)
```

### Creating Reusable UI Components

Place in `WeDaApp/Code/UI/Common/` following these patterns:
- `LoadingView` - Shimmer/skeleton screens
- `ErrorView` - Error display with retry button
- `WeatherCard` - Weather data display card
- Add accessibility identifiers from `UITestIDs.Common`

---

## File Organization

- `WeDaApp/Code/Application/`: App entry point (@main App struct)
- `WeDaApp/Code/UI/Main/`: Feature-specific views and view models
- `WeDaApp/Code/UI/Common/`: Reusable UI components
- `WeDaApp/Code/Models/Weather/`: API response models
- `WeDaApp/Code/Models/Local/`: Local persistence models
- `WeDaApp/Code/Dependencies/`: Service layer and API client

---

## Build & Run Commands

### Build Project
```bash
xcodebuild -workspace WeDaApp.xcworkspace -scheme WeDaApp -configuration Debug build
```

### Run Tests
```bash
# All tests
xcodebuild test -workspace WeDaApp.xcworkspace -scheme WeDaApp -destination 'platform=iOS Simulator,name=iPhone 15'

# Specific test class
xcodebuild test -workspace WeDaApp.xcworkspace -scheme WeDaApp -only-testing:WeDaAppTests/SearchViewModelTests -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Regenerate Secrets
```bash
bundle exec arkana
```

---

## Security Best Practices

1. **Never hardcode API keys** - use ArkanaKeys package
2. **Store sensitive runtime data in Keychain** - use `KeychainManager`
3. **OpenWeatherMap API key** - Stored encrypted via Arkana
4. **Local data** - Use `DollarGeneralPersist` for non-sensitive caching

---

## Notable Implementation Details

### Weather Icons

OpenWeatherMap provides weather icons:
```swift
let iconURL = URL(string: "https://openweathermap.org/img/wn/\(weather.icon)@2x.png")
```

Use Nuke (or similar) for remote image loading with caching.

### Temperature Units

API uses `units=metric` parameter for Celsius. To support Fahrenheit:
- Add `units=imperial` to query
- Or convert client-side: `°F = (°C × 9/5) + 32`

### Offline Capability

Cache weather data locally:
1. After successful API call, encode and save to `KeysCache.cachedWeatherData`
2. When offline (APIError.noInternetConnection), load from cache
3. Show visual indicator that data is cached

### ViewModels Are Main Actor

All ViewModels use `@MainActor` to ensure thread-safe UI updates. Never dispatch manually to main queue.

---

## Assessment Criteria Reminders

This project is evaluated on:
- **Code Quality** (20%): Clean MVVM, protocols, error handling, modularity
- **Functionality & UI/UX** (25%): All 4 screens, responsive design, loading/error states
- **State Management** (30%): Combine, local persistence, MVVM, offline capability
- **Testing & TDD** (25%): Tests written first, comprehensive coverage

Always prioritize TDD and clean architecture!
