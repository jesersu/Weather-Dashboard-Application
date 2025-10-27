//
//  NotificationManager.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit
import DollarGeneralTemplateHelpers

/// Manages local and push notifications for weather alerts and daily summaries
///
/// **Purpose**: Send timely weather notifications to keep users informed
///
/// **Notification Types**:
/// 1. **Daily Summary**: Morning weather forecast (8 AM)
/// 2. **Weather Alerts**: Significant changes (temperature drops, rain, severe weather)
/// 3. **Push Notifications**: Future-ready infrastructure for remote notifications
///
/// **iOS Notifications Best Practices**:
/// - Request permissions explicitly with clear explanation
/// - Use rich notifications with weather icons
/// - Respect user preferences (allow per-city toggles)
/// - Don't over-notify (max 2-3 per day per city)
/// - Handle notification actions (View Details, Dismiss)
///
/// **Testing**:
/// - Unit tests with UNUserNotificationCenter mocking
/// - Manual testing with notification triggers
/// - Test different authorization states
@MainActor
final class NotificationManager {
    // MARK: - Constants

    /// Minimum temperature drop (in °C) to trigger alert
    private static let significantTemperatureDrop: Double = 10.0

    // MARK: - Initialization

    init() {
        // Setup notification categories and actions
        setupNotificationCategories()
    }

    // MARK: - Permission Management

    /// Request notification permissions from user
    ///
    /// **Returns**: `true` if permission granted, `false` if denied
    ///
    /// **Usage**: Call this when user first opens app or enables notifications
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            if granted {
                LogInfo("✅ Notification permission granted")

                // Register for remote notifications (push)
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                LogInfo("❌ Notification permission denied")
            }

            return granted
        } catch {
            LogError("❌ Failed to request notification permission: \(error.localizedDescription)")
            return false
        }
    }

    /// Check current notification authorization status
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Daily Summary Notifications

    /// Schedule daily weather summary notification (8 AM every day)
    ///
    /// **Parameters**:
    /// - cityName: Name of the city
    /// - temperature: Current temperature
    /// - description: Weather description
    func scheduleDailySummary(cityName: String, temperature: Double, description: String) async {
        let content = UNMutableNotificationContent()
        content.title = "🌤️ Morning Weather for \(cityName)"
        content.body = "Currently \(Int(temperature))°C and \(description)"
        content.sound = .default
        content.categoryIdentifier = "WEATHER_SUMMARY"

        // Schedule for 8 AM every day
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let identifier = "daily-summary-\(cityName.lowercased())"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            LogInfo("✅ Scheduled daily summary for \(cityName) at 8 AM")
        } catch {
            LogError("❌ Failed to schedule daily summary: \(error.localizedDescription)")
        }
    }

    // MARK: - Weather Alerts

    /// Schedule immediate weather alert notification
    ///
    /// **Parameters**:
    /// - cityName: City affected by weather event
    /// - message: Alert message
    func scheduleWeatherAlert(cityName: String, message: String) async {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Weather Alert: \(cityName)"
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "WEATHER_ALERT"
        content.badge = 1

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let identifier = "weather-alert-\(cityName.lowercased())-\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            LogInfo("✅ Scheduled weather alert for \(cityName): \(message)")
        } catch {
            LogError("❌ Failed to schedule weather alert: \(error.localizedDescription)")
        }
    }

    // MARK: - Temperature Change Detection

    /// Check for significant temperature changes and alert if needed
    ///
    /// **Parameters**:
    /// - previousTemp: Previous temperature
    /// - currentTemp: Current temperature
    /// - cityName: City name
    func checkTemperatureChange(previousTemp: Double, currentTemp: Double, cityName: String) async {
        let tempDrop = previousTemp - currentTemp

        // Alert on significant temperature drop (> 10°C)
        if tempDrop >= Self.significantTemperatureDrop {
            let message = "Temperature dropped by \(Int(tempDrop))°C! Currently \(Int(currentTemp))°C"
            await scheduleWeatherAlert(cityName: cityName, message: message)
        }
    }

    // MARK: - Push Notifications (Future-Ready)

    /// Handle device token registration for push notifications
    ///
    /// **Note**: This is infrastructure for future push notification support
    /// Requires backend server to send push notifications
    func registerDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        LogInfo("📱 Device token for push notifications: \(tokenString)")

        // TODO: Send token to backend server for push notifications
        // For now, just log it
    }

    /// Handle incoming push notification
    ///
    /// **Note**: Future implementation for remote notification handling
    func handlePushNotification(_ userInfo: [AnyHashable: Any]) {
        LogInfo("📬 Received push notification: \(userInfo)")

        // TODO: Parse notification payload and update UI
        // Example payload:
        // {
        //   "city": "London",
        //   "alert": "Heavy rain expected",
        //   "temperature": 12
        // }
    }

    // MARK: - Notification Categories & Actions

    /// Setup notification categories with actions
    private func setupNotificationCategories() {
        // Action: View weather details
        let viewAction = UNNotificationAction(
            identifier: "VIEW_DETAILS",
            title: "View Details",
            options: [.foreground]
        )

        // Action: Dismiss
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: []
        )

        // Category: Weather Summary
        let summaryCategory = UNNotificationCategory(
            identifier: "WEATHER_SUMMARY",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        // Category: Weather Alert
        let alertCategory = UNNotificationCategory(
            identifier: "WEATHER_ALERT",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([summaryCategory, alertCategory])
        LogInfo("✅ Notification categories configured")
    }

    // MARK: - Cancellation

    /// Cancel all pending notifications
    func cancelAllNotifications() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        LogInfo("🚫 Cancelled all pending notifications")
    }

    /// Cancel notifications for specific city
    ///
    /// **Parameter** cityName: City to cancel notifications for
    func cancelNotifications(forCity cityName: String) async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()

        let cityIdentifiers = requests
            .filter { $0.identifier.lowercased().contains(cityName.lowercased()) }
            .map { $0.identifier }

        center.removePendingNotificationRequests(withIdentifiers: cityIdentifiers)
        LogInfo("🚫 Cancelled notifications for \(cityName)")
    }
}
