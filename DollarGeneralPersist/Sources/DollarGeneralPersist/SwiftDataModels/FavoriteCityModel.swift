//
//  FavoriteCityModel.swift
//  DollarGeneralPersist
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import SwiftData

/// SwiftData model for favorite cities
/// Provides persistent storage with automatic change tracking
@Model
public final class FavoriteCityModel {
    @Attribute(.unique) public var id: UUID
    public var cityName: String
    public var country: String?
    public var latitude: Double
    public var longitude: Double
    public var addedAt: Date

    public init(
        id: UUID = UUID(),
        cityName: String,
        country: String?,
        latitude: Double,
        longitude: Double,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.cityName = cityName
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.addedAt = addedAt
    }

    /// Computed property for display name
    public var displayName: String {
        if let country = country {
            return "\(cityName), \(country)"
        }
        return cityName
    }

    /// Convert SwiftData model to Codable struct for app use
    public func toFavoriteCity() -> FavoriteCity {
        return FavoriteCity(
            id: id.uuidString,
            cityName: cityName,
            country: country,
            coordinates: Coordinates(lon: longitude, lat: latitude),
            addedAt: addedAt
        )
    }

    /// Create SwiftData model from Codable struct
    public static func from(_ favorite: FavoriteCity) -> FavoriteCityModel {
        return FavoriteCityModel(
            id: UUID(uuidString: favorite.id) ?? UUID(),
            cityName: favorite.cityName,
            country: favorite.country,
            latitude: favorite.coordinates.lat,
            longitude: favorite.coordinates.lon,
            addedAt: favorite.addedAt
        )
    }
}
