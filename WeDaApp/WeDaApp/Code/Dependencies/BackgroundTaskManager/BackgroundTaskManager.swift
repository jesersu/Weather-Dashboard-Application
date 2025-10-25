//
//  BackgroundTaskManager.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import BackgroundTasks
import DollarGeneralTemplateHelpers
import DollarGeneralPersist

/// Manages background task scheduling and execution for silent weather updates
///
/// **Purpose**: Fetch weather data for favorite cities in the background to keep data fresh
///
/// **⚠️ REQUIRED CONFIGURATION** (see BACKGROUND_TASKS_SETUP.md):
/// 1. Add `BGTaskSchedulerPermittedIdentifiers` to Info.plist with value: `com.dollarg.wedaapp.refresh`
/// 2. Enable "Background Modes" capability in Xcode (Background fetch + Background processing)
///
/// **iOS Background Tasks**:
/// - Uses BGTaskScheduler (iOS 13+) for battery-efficient background refresh
/// - System decides when to run based on usage patterns, battery level, network
/// - Tasks have 30-second execution limit
/// - Requires "Background fetch" and "Background processing" capabilities
///
/// **Best Practices**:
/// - Keep tasks under 30 seconds
/// - Handle task expiration gracefully
/// - Use battery-efficient scheduling (4-8 hour intervals)
/// - Only fetch essential data (favorites, not all cities)
///
/// **Testing**:
/// ```swift
/// // Simulate background fetch in debugger:
/// e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.dollarg.wedaapp.refresh"]
/// ```
///
/// **Troubleshooting**:
/// - Error 3 (NotPermitted): Missing configuration - see BACKGROUND_TASKS_SETUP.md
/// - Error 1 (Unavailable): iOS version < 13 or unsupported simulator
/// - Error 2 (TooMany): More than 10 pending requests
@MainActor
final class BackgroundTaskManager {

    // MARK: - Constants

    /// Background task identifier (must match Info.plist)
    static let backgroundRefreshTaskIdentifier = "com.dollarg.wedaapp.refresh"

    /// Minimum time between background refreshes (4 hours)
    private static let minimumBackgroundFetchInterval: TimeInterval = 4 * 60 * 60

    // MARK: - Dependencies

    private let weatherService: WeatherServiceProtocol
    private let storageService: LocalStorageServiceProtocol

    // MARK: - Initialization

    init(weatherService: WeatherServiceProtocol = WeatherService(),
         storageService: LocalStorageServiceProtocol = LocalStorageService()) {
        self.weatherService = weatherService
        self.storageService = storageService
    }

    // MARK: - Registration

    /// Register background tasks with BGTaskScheduler
    ///
    /// **Must be called** before `application(_:didFinishLaunchingWithOptions:)` returns
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundRefreshTaskIdentifier,
            using: nil
        ) { task in
            LogInfo("📱 Background refresh task started")
            self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
        }

        LogInfo("✅ Registered background refresh task: \(Self.backgroundRefreshTaskIdentifier)")
    }

    // MARK: - Scheduling

    /// Schedule next background refresh
    ///
    /// **Returns**: `true` if scheduled successfully, `false` if scheduling failed
    ///
    /// **Note**: BGTaskScheduler may fail on simulator or if background modes not enabled
    ///
    /// **Common Errors**:
    /// - Error 3 (NotPermitted): Missing BGTaskSchedulerPermittedIdentifiers or Background Modes
    /// - Error 1 (Unavailable): Running on unsupported iOS version
    /// - Error 2 (TooManyPendingTaskRequests): Too many pending requests (limit: ~10)
    @discardableResult
    func scheduleBackgroundRefresh() -> Bool {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundRefreshTaskIdentifier)

        // Schedule for at least 4 hours from now (battery-efficient)
        request.earliestBeginDate = Date(timeIntervalSinceNow: Self.minimumBackgroundFetchInterval)

        do {
            try BGTaskScheduler.shared.submit(request)
            LogInfo("✅ Scheduled background refresh for \(request.earliestBeginDate?.description ?? "unknown")")
            return true
        } catch let error as NSError {
            // Provide detailed error information
            let errorCode = error.code
            let errorMessage: String

            switch errorCode {
            case 3: // BGTaskSchedulerErrorCodeNotPermitted
                errorMessage = """
                ❌ Background task NOT PERMITTED (Error 3)

                This means your Xcode project is missing required configuration.

                📋 REQUIRED FIXES:
                1. Add BGTaskSchedulerPermittedIdentifiers to Info.plist/Target Settings
                   - Key: BGTaskSchedulerPermittedIdentifiers (Array)
                   - Value: com.dollarg.wedaapp.refresh

                2. Enable Background Modes capability in Xcode:
                   - Target → Signing & Capabilities → + Capability
                   - Add "Background Modes"
                   - Check ✅ Background fetch
                   - Check ✅ Background processing

                📖 See BACKGROUND_TASKS_SETUP.md for step-by-step instructions
                """

            case 1: // BGTaskSchedulerErrorCodeUnavailable
                errorMessage = """
                ❌ Background tasks UNAVAILABLE (Error 1)
                - iOS version too old (requires iOS 13+)
                - Running on unsupported simulator configuration
                """

            case 2: // BGTaskSchedulerErrorCodeTooManyPendingTaskRequests
                errorMessage = """
                ❌ Too many pending task requests (Error 2)
                - Maximum ~10 pending requests allowed
                - Cancel old requests before scheduling new ones
                """

            default:
                errorMessage = "❌ Failed to schedule background refresh: \(error.localizedDescription) (Error \(errorCode))"
            }

            LogError(errorMessage)
            return false
        } catch {
            LogError("❌ Failed to schedule background refresh: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Background Fetch Handler

    /// Handle background refresh task execution
    ///
    /// **Execution Flow**:
    /// 1. Fetch weather for all favorite cities
    /// 2. Cache results locally
    /// 3. Schedule next refresh
    /// 4. Complete task before 30-second limit
    ///
    /// - Parameter task: BGAppRefreshTask provided by system
    private func handleBackgroundRefresh(task: BGAppRefreshTask) {
        // Schedule next refresh immediately
        scheduleBackgroundRefresh()

        // Handle task expiration (30-second limit)
        task.expirationHandler = {
            LogInfo("⚠️ Background refresh task expired")
            // Cancel any ongoing work
            task.setTaskCompleted(success: false)
        }

        // Perform background fetch
        Task {
            let success = await performBackgroundFetch()
            task.setTaskCompleted(success: success)
            LogInfo("✅ Background refresh completed: \(success ? "success" : "failure")")
        }
    }

    // MARK: - Background Fetch Logic

    /// Perform the actual background fetch of weather data
    ///
    /// **Returns**: `true` if fetch succeeded, `false` if failed
    ///
    /// **Performance**:
    /// - Fetches weather for all favorites in parallel
    /// - Must complete within 30 seconds
    /// - Gracefully handles errors (doesn't crash app)
    func performBackgroundFetch() async -> Bool {
        do {
            LogInfo("🔄 Starting background weather fetch")

            // Get all favorite cities
            let favorites = try storageService.getFavorites()

            guard !favorites.isEmpty else {
                LogInfo("ℹ️ No favorites to fetch, skipping background refresh")
                return true
            }

            LogInfo("📍 Fetching weather for \(favorites.count) favorite cities")

            // Fetch weather for all favorites in parallel (efficient)
            let successCount = await withTaskGroup(of: (FavoriteCity, WeatherData?).self) { group in
                for favorite in favorites {
                    group.addTask {
                        do {
                            let weather = try await self.weatherService.fetchWeatherByCoordinates(
                                lat: favorite.coordinates.lat,
                                lon: favorite.coordinates.lon
                            )
                            return (favorite, weather)
                        } catch {
                            LogError("❌ Failed to fetch weather for \(favorite.cityName): \(error.localizedDescription)")
                            return (favorite, nil)
                        }
                    }
                }

                // Collect results and cache them
                var count = 0
                for await (favorite, weather) in group {
                    if let weather = weather {
                        cacheWeatherData(weather, for: favorite)
                        count += 1
                    }
                }
                return count
            }

            LogInfo("✅ Background fetch completed: \(successCount)/\(favorites.count) successful")

            // Return false if ALL fetches failed
            guard successCount > 0 else {
                LogError("❌ All background fetches failed")
                return false
            }

            // Save last background fetch timestamp
            DollarGeneralPersist.saveCache(
                key: "lastBackgroundFetchDate",
                value: ISO8601DateFormatter().string(from: Date())
            )

            return true

        } catch {
            LogError("❌ Background fetch failed: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Private Helpers

    /// Cache weather data locally for offline access
    ///
    /// **Storage**: UserDefaults via DollarGeneralPersist
    /// **Key Format**: `bg_weather_<cityname>`
    private func cacheWeatherData(_ weather: WeatherData, for favorite: FavoriteCity) {
        do {
            let data = try JSONEncoder().encode(weather)
            if let jsonString = String(data: data, encoding: .utf8) {
                let cacheKey = "bg_weather_\(favorite.cityName.lowercased())"
                DollarGeneralPersist.saveCache(key: cacheKey, value: jsonString)
                LogInfo("💾 Cached weather for \(favorite.cityName)")
            }
        } catch {
            LogError("❌ Failed to cache weather for \(favorite.cityName): \(error.localizedDescription)")
        }
    }

    // MARK: - Public Utility

    /// Get last background fetch date
    ///
    /// **Returns**: Date of last successful background fetch, or nil if never fetched
    static func getLastBackgroundFetchDate() -> Date? {
        let dateString = DollarGeneralPersist.getCacheData(key: "lastBackgroundFetchDate")
        guard !dateString.isEmpty else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }

    /// Cancel all pending background tasks
    func cancelAllBackgroundTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.backgroundRefreshTaskIdentifier)
        LogInfo("🚫 Cancelled all background refresh tasks")
    }
}
