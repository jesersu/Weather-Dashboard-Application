//
//  SearchHistory.swift
//  WeDaApp
//
//  Created by Claude Code
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation

/// Represents a search history entry
public struct SearchHistoryItem: Codable, Identifiable, Hashable {
    public let id: String
    public let cityName: String
    public let country: String?
    public let searchedAt: Date

    public init(id: String = UUID().uuidString, cityName: String, country: String?, searchedAt: Date = Date()) {
        self.id = id
        self.cityName = cityName
        self.country = country
        self.searchedAt = searchedAt
    }

    public var displayName: String {
        if let country = country {
            return "\(cityName), \(country)"
        }
        return cityName
    }
}
