//
//  FavoriteCity.swift
//  WeDaApp
//
//  Created by Claude Code
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation

/// Represents a user's favorite city
public struct FavoriteCity: Codable, Identifiable, Hashable {
    public let id: String
    public let cityName: String
    public let country: String?
    public let coordinates: Coordinates
    public let addedAt: Date

    public init(id: String = UUID().uuidString, cityName: String, country: String?, coordinates: Coordinates, addedAt: Date = Date()) {
        self.id = id
        self.cityName = cityName
        self.country = country
        self.coordinates = coordinates
        self.addedAt = addedAt
    }

    public var displayName: String {
        if let country = country {
            return "\(cityName), \(country)"
        }
        return cityName
    }
}
