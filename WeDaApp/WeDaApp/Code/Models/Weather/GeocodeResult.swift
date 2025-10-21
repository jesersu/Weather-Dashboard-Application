//
//  GeocodeResult.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation

/// Represents a geocoding result from OpenWeatherMap Geocoding API
public struct GeocodeResult: Codable, Identifiable, Equatable {

    /// Unique identifier (computed from coordinates for Identifiable conformance)
    public var id: String {
        "\(lat)-\(lon)"
    }

    /// City/location name
    public let name: String

    /// City name in different languages (optional)
    public let localNames: [String: String]?

    /// Latitude coordinate
    public let lat: Double

    /// Longitude coordinate
    public let lon: Double

    /// Country code (e.g., "US", "GB")
    public let country: String

    /// State/province name (optional, mainly for US cities)
    public let state: String?

    enum CodingKeys: String, CodingKey {
        case name
        case localNames = "local_names"
        case lat
        case lon
        case country
        case state
    }

    // MARK: - Computed Properties

    /// Full display name with location context (e.g., "London, GB" or "Austin, Texas, US")
    public var displayName: String {
        if let state = state {
            return "\(name), \(state), \(country)"
        } else {
            return "\(name), \(country)"
        }
    }

    /// Short display name (e.g., "London" or "Austin, TX")
    public var shortDisplayName: String {
        if let state = state {
            return "\(name), \(state)"
        } else {
            return name
        }
    }
}
