//
//  SearchHistoryModel.swift
//  DollarGeneralPersist
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import SwiftData

/// SwiftData model for search history
/// Provides persistent storage with automatic change tracking
@Model
public final class SearchHistoryModel {
    @Attribute(.unique) public var id: UUID
    public var cityName: String
    public var country: String?
    public var searchedAt: Date

    public init(
        id: UUID = UUID(),
        cityName: String,
        country: String?,
        searchedAt: Date = Date()
    ) {
        self.id = id
        self.cityName = cityName
        self.country = country
        self.searchedAt = searchedAt
    }

    /// Computed property for display name
    public var displayName: String {
        if let country = country {
            return "\(cityName), \(country)"
        }
        return cityName
    }

    /// Convert SwiftData model to Codable struct for app use
    public func toSearchHistoryItem() -> SearchHistoryItem {
        return SearchHistoryItem(
            id: id.uuidString,
            cityName: cityName,
            country: country,
            searchedAt: searchedAt
        )
    }

    /// Create SwiftData model from Codable struct
    public static func from(_ item: SearchHistoryItem) -> SearchHistoryModel {
        return SearchHistoryModel(
            id: UUID(uuidString: item.id) ?? UUID(),
            cityName: item.cityName,
            country: item.country,
            searchedAt: item.searchedAt
        )
    }
}
