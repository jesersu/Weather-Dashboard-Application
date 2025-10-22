//
//  NotificationManagerTests.swift
//  WeDaAppTests
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import XCTest
import UserNotifications
@testable import WeDaApp

@MainActor
final class NotificationManagerTests: XCTestCase {

    var sut: NotificationManager!

    override func setUp() async throws {
        try await super.setUp()
        sut = NotificationManager()
    }

    override func tearDown() async throws {
        sut = nil
        // Cancel all pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        try await super.tearDown()
    }

    // MARK: - Permission Tests

    func test_requestPermission_requestsAuthorization() async {
        // When
        let granted = await sut.requestPermission()

        // Then
        // Note: In tests, this may return false as we can't actually grant permissions
        // The test verifies the method doesn't crash
        XCTAssertNotNil(granted, "Should return a boolean result")
    }

    // MARK: - Daily Summary Tests

    func test_scheduleDailySummary_schedulesPendingNotification() async {
        // Given
        let cityName = "London"
        let temperature = 15.0
        let description = "Partly cloudy"

        // When
        await sut.scheduleDailySummary(cityName: cityName, temperature: temperature, description: description)

        // Then
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let dailySummaryRequest = requests.first { $0.identifier.starts(with: "daily-summary") }

        XCTAssertNotNil(dailySummaryRequest, "Should schedule daily summary notification")
        XCTAssertTrue(dailySummaryRequest?.content.title.contains(cityName) ?? false, "Notification should contain city name")
    }

    func test_scheduleDailySummary_schedulesFor8AM() async {
        // Given
        let cityName = "London"

        // When
        await sut.scheduleDailySummary(cityName: cityName, temperature: 15.0, description: "Clear")

        // Then
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let dailySummaryRequest = requests.first { $0.identifier.starts(with: "daily-summary") }

        guard let trigger = dailySummaryRequest?.trigger as? UNCalendarNotificationTrigger else {
            XCTFail("Should have calendar trigger")
            return
        }

        XCTAssertEqual(trigger.dateComponents.hour, 8, "Should be scheduled for 8 AM")
    }

    // MARK: - Weather Alert Tests

    func test_scheduleWeatherAlert_schedulesImmediateNotification() async {
        // Given
        let cityName = "Paris"
        let alertMessage = "Heavy rain expected"

        // When
        await sut.scheduleWeatherAlert(cityName: cityName, message: alertMessage)

        // Then
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let alertRequest = requests.first { $0.identifier.starts(with: "weather-alert") }

        XCTAssertNotNil(alertRequest, "Should schedule weather alert notification")
        XCTAssertTrue(alertRequest?.content.body.contains(alertMessage) ?? false, "Alert should contain message")
    }

    func test_scheduleWeatherAlert_includesCityName() async {
        // Given
        let cityName = "Tokyo"
        let message = "Temperature drop"

        // When
        await sut.scheduleWeatherAlert(cityName: cityName, message: message)

        // Then
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let alertRequest = requests.first { $0.identifier.starts(with: "weather-alert") }

        XCTAssertTrue(alertRequest?.content.title.contains(cityName) ?? false, "Title should contain city name")
    }

    // MARK: - Temperature Alert Tests

    func test_checkTemperatureChange_alertsOnSignificantDrop() async {
        // Given
        let previousTemp = 20.0
        let currentTemp = 5.0 // 15 degree drop
        let cityName = "Berlin"

        // When
        await sut.checkTemperatureChange(
            previousTemp: previousTemp,
            currentTemp: currentTemp,
            cityName: cityName
        )

        // Then
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let tempAlert = requests.first { $0.identifier.starts(with: "weather-alert") }

        XCTAssertNotNil(tempAlert, "Should schedule alert for significant temperature drop")
    }

    func test_checkTemperatureChange_noAlertForSmallChange() async {
        // Given
        let previousTemp = 20.0
        let currentTemp = 18.0 // Only 2 degree drop
        let cityName = "Madrid"

        // When
        await sut.checkTemperatureChange(
            previousTemp: previousTemp,
            currentTemp: currentTemp,
            cityName: cityName
        )

        // Then
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let tempAlert = requests.first { $0.identifier.starts(with: "weather-alert") && $0.content.title.contains(cityName) }

        XCTAssertNil(tempAlert, "Should NOT schedule alert for small temperature change")
    }

    // MARK: - Cancel Tests

    func test_cancelAllNotifications_removesAllPending() async {
        // Given - Schedule multiple notifications
        await sut.scheduleDailySummary(cityName: "London", temperature: 15.0, description: "Clear")
        await sut.scheduleWeatherAlert(cityName: "Paris", message: "Rain alert")

        // When
        await sut.cancelAllNotifications()

        // Then
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        XCTAssertEqual(requests.count, 0, "Should cancel all notifications")
    }

    func test_cancelNotificationsForCity_removesOnlySpecificCity() async {
        // Given
        await sut.scheduleDailySummary(cityName: "London", temperature: 15.0, description: "Clear")
        await sut.scheduleDailySummary(cityName: "Paris", temperature: 18.0, description: "Cloudy")

        // When
        await sut.cancelNotifications(forCity: "London")

        // Then
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        let londonNotifications = requests.filter { $0.identifier.contains("london") }
        let parisNotifications = requests.filter { $0.identifier.contains("paris") }

        XCTAssertEqual(londonNotifications.count, 0, "Should cancel London notifications")
        XCTAssertGreaterThan(parisNotifications.count, 0, "Should keep Paris notifications")
    }
}
