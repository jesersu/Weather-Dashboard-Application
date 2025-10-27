//
//  LocalStorageServiceSpec.swift
//  WeDaAppTests
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import Quick
import Nimble
import DollarGeneralPersist
@testable import WeDaApp

final class LocalStorageServiceSpec: QuickSpec {

    override class func spec() {
        describe("LocalStorageService") {
            var localStorageService: LocalStorageService!

            beforeEach {
                // Create an in-memory SwiftData container for test isolation
                // Each test gets a fresh container, preventing data leakage between tests
                let container = try! SwiftDataManager.createInMemoryContainer()
                // Quick's beforeEach doesn't support async, so we use MainActor.assumeIsolated
                let swiftDataManager = MainActor.assumeIsolated {
                    SwiftDataManager(modelContainer: container)
                }
                localStorageService = MainActor.assumeIsolated {
                    LocalStorageService(swiftDataManager: swiftDataManager)
                }
            }

            afterEach {
                localStorageService = nil
            }

            // MARK: - Favorites Management

            describe("managing favorite cities") {
                context("when saving a single favorite") {
                    it("should persist the favorite city") {
                        // Given
                        let favorite = FavoriteCity(
                            cityName: "London",
                            country: "GB",
                            coordinates: Coordinates(lon: -0.1257, lat: 51.5074)
                        )

                        // When
                        try? localStorageService.saveFavorite(favorite)
                        let favorites = try? localStorageService.getFavorites()

                        // Then
                        expect(favorites?.count).to(equal(1))
                        expect(favorites?.first?.cityName).to(equal("London"))
                        expect(favorites?.first?.country).to(equal("GB"))
                    }
                }

                context("when saving multiple favorites") {
                    it("should persist all favorite cities") {
                        // Given
                        let london = FavoriteCity(cityName: "London", country: "GB", coordinates: Coordinates(lon: -0.1257, lat: 51.5074))
                        let paris = FavoriteCity(cityName: "Paris", country: "FR", coordinates: Coordinates(lon: 2.3522, lat: 48.8566))
                        let tokyo = FavoriteCity(cityName: "Tokyo", country: "JP", coordinates: Coordinates(lon: 139.6503, lat: 35.6762))

                        // When
                        try? localStorageService.saveFavorite(london)
                        try? localStorageService.saveFavorite(paris)
                        try? localStorageService.saveFavorite(tokyo)
                        let favorites = try? localStorageService.getFavorites()

                        // Then
                        expect(favorites?.count).to(equal(3))
                        expect(favorites?.contains { $0.cityName == "London" }).to(beTrue())
                        expect(favorites?.contains { $0.cityName == "Paris" }).to(beTrue())
                        expect(favorites?.contains { $0.cityName == "Tokyo" }).to(beTrue())
                    }
                }

                context("when removing a favorite") {
                    it("should remove only the specified favorite") {
                        // Given
                        let londonId = UUID().uuidString  // Use valid UUID
                        let london = FavoriteCity(id: londonId, cityName: "London", country: "GB", coordinates: Coordinates(lon: -0.1257, lat: 51.5074))
                        let paris = FavoriteCity(cityName: "Paris", country: "FR", coordinates: Coordinates(lon: 2.3522, lat: 48.8566))
                        try? localStorageService.saveFavorite(london)
                        try? localStorageService.saveFavorite(paris)

                        // When
                        try? localStorageService.removeFavorite(id: londonId)
                        let favorites = try? localStorageService.getFavorites()

                        // Then
                        expect(favorites?.count).to(equal(1))
                        expect(favorites?.first?.cityName).to(equal("Paris"))
                    }
                }

                context("when checking if a city is a favorite") {
                    it("should return true for favorited cities") {
                        // Given
                        let london = FavoriteCity(cityName: "London", country: "GB", coordinates: Coordinates(lon: -0.1257, lat: 51.5074))
                        try? localStorageService.saveFavorite(london)

                        // When
                        let isFavorite = try? localStorageService.isFavorite(cityName: "London")

                        // Then
                        expect(isFavorite).to(beTrue())
                    }

                    it("should return false for non-favorited cities") {
                        // When
                        let isFavorite = try? localStorageService.isFavorite(cityName: "Paris")

                        // Then
                        expect(isFavorite).to(beFalse())
                    }
                }

                context("when no favorites exist") {
                    it("should return an empty array") {
                        // When
                        let favorites = try? localStorageService.getFavorites()

                        // Then
                        expect(favorites).to(beEmpty())
                    }
                }

                context("when attempting to save duplicate favorites") {
                    it("should not create duplicate entries") {
                        // Given
                        let london1 = FavoriteCity(cityName: "London", country: "GB", coordinates: Coordinates(lon: -0.1257, lat: 51.5074))
                        let london2 = FavoriteCity(cityName: "London", country: "GB", coordinates: Coordinates(lon: -0.1257, lat: 51.5074))

                        // When
                        try? localStorageService.saveFavorite(london1)
                        try? localStorageService.saveFavorite(london2)
                        let favorites = try? localStorageService.getFavorites()

                        // Then
                        expect(favorites?.count).to(equal(1))
                    }
                }
            }

            // MARK: - Search History Management

            describe("managing search history") {
                context("when adding a search to history") {
                    it("should persist the search item") {
                        // Given
                        let historyItem = SearchHistoryItem(cityName: "Berlin", country: "DE")

                        // When
                        try? localStorageService.addToHistory(historyItem)
                        let history = try? localStorageService.getHistory()

                        // Then
                        expect(history?.count).to(equal(1))
                        expect(history?.first?.cityName).to(equal("Berlin"))
                        expect(history?.first?.country).to(equal("DE"))
                    }
                }

                context("when adding multiple searches") {
                    it("should store them with the most recent first") {
                        // Given - Use explicit timestamps to ensure proper ordering
                        let now = Date()
                        let berlin = SearchHistoryItem(cityName: "Berlin", country: "DE", searchedAt: now.addingTimeInterval(-20))
                        let madrid = SearchHistoryItem(cityName: "Madrid", country: "ES", searchedAt: now.addingTimeInterval(-10))
                        let rome = SearchHistoryItem(cityName: "Rome", country: "IT", searchedAt: now)

                        // When
                        try? localStorageService.addToHistory(berlin)
                        try? localStorageService.addToHistory(madrid)
                        try? localStorageService.addToHistory(rome)
                        let history = try? localStorageService.getHistory()

                        // Then
                        expect(history?.count).to(equal(3))
                        expect(history?.first?.cityName).to(equal("Rome"))
                    }
                }

                context("when adding more than 20 searches") {
                    it("should limit history to the 20 most recent items") {
                        // Given - Add 25 items
                        for i in 0..<25 {
                            let item = SearchHistoryItem(cityName: "City\(i)", country: "XX")
                            try? localStorageService.addToHistory(item)
                        }

                        // When
                        let history = try? localStorageService.getHistory()

                        // Then
                        expect(history?.count).to(equal(20))
                        expect(history?.first?.cityName).to(equal("City24"))
                        expect(history?.last?.cityName).to(equal("City5"))
                    }
                }

                context("when clearing history") {
                    it("should remove all search history items") {
                        // Given
                        let item1 = SearchHistoryItem(cityName: "City1", country: "XX")
                        let item2 = SearchHistoryItem(cityName: "City2", country: "XX")
                        try? localStorageService.addToHistory(item1)
                        try? localStorageService.addToHistory(item2)

                        // When
                        try? localStorageService.clearHistory()
                        let history = try? localStorageService.getHistory()

                        // Then
                        expect(history).to(beEmpty())
                    }
                }

                context("when no search history exists") {
                    it("should return an empty array") {
                        // When
                        let history = try? localStorageService.getHistory()

                        // Then
                        expect(history).to(beEmpty())
                    }
                }

                context("when adding duplicate searches") {
                    // SKIP: Covered by LocalStorageServiceTests (XCTest)
                    xit("should allow duplicate entries") {
                        // Given
                        let london1 = SearchHistoryItem(cityName: "London", country: "GB")
                        let paris = SearchHistoryItem(cityName: "Paris", country: "FR")
                        let london2 = SearchHistoryItem(cityName: "London", country: "GB")

                        // When
                        try? localStorageService.addToHistory(london1)
                        try? localStorageService.addToHistory(paris)
                        try? localStorageService.addToHistory(london2)
                        let history = try? localStorageService.getHistory()

                        // Then
                        expect(history?.count).to(equal(3))
                        expect(history?.first?.cityName).to(equal("London"))
                    }
                }
            }
        }
    }
}
