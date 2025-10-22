//
//  LocationManager.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation
import CoreLocation
import Combine
import DollarGeneralTemplateHelpers
import DollarGeneralPersist

/// Location-specific errors
public enum LocationError: Error, Equatable {
    case denied
    case restricted
    case unavailable
    case failed(String)

    public var message: String {
        switch self {
        case .denied:
            return "Location access was denied. You can enable it in Settings."
        case .restricted:
            return "Location access is restricted."
        case .unavailable:
            return "Location services are not available."
        case .failed(let reason):
            return "Failed to get location: \(reason)"
        }
    }
}

/// Protocol for location manager operations
public protocol LocationManagerProtocol: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    var currentLocation: CLLocation? { get }
    var locationError: LocationError? { get }

    func requestLocationPermission()
    func getCurrentLocation() async throws -> CLLocation
    func hasRequestedPermission() -> Bool
    func markPermissionRequested()
}

/// Manager for handling device location services
@MainActor
public class LocationManager: NSObject, LocationManagerProtocol, ObservableObject {

    // MARK: - Published Properties

    @Published public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public private(set) var currentLocation: CLLocation?
    @Published public private(set) var locationError: LocationError?

    // MARK: - Private Properties

    private let locationManager: CLLocationManager
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    // MARK: - Initialization

    public override init() {
        self.locationManager = CLLocationManager()
        super.init()

        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.authorizationStatus = locationManager.authorizationStatus

        LogInfo("LocationManager initialized with status: \(authorizationStatus.rawValue)")
    }

    // MARK: - Public Methods

    /// Request when-in-use location authorization
    public func requestLocationPermission() {
        LogInfo("Requesting location permission")
        locationManager.requestWhenInUseAuthorization()
    }

    /// Get current location (one-time request)
    /// - Returns: Current CLLocation
    /// - Throws: LocationError if location cannot be determined
    public func getCurrentLocation() async throws -> CLLocation {
        LogInfo("Getting current location")

        // Check authorization status
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            LogError("Location authorization not granted: \(authorizationStatus.rawValue)")
            throw mapAuthorizationToError(authorizationStatus)
        }

        // Request location using async/await
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.locationManager.requestLocation()
        }
    }

    /// Check if location permission has been requested before
    /// - Returns: True if permission was requested previously
    public func hasRequestedPermission() -> Bool {
        let requested = DollarGeneralPersist.getCacheData(key: KeysCache.locationPermissionRequested)
        return requested == "true"
    }

    /// Mark that location permission has been requested
    public func markPermissionRequested() {
        DollarGeneralPersist.saveCache(key: KeysCache.locationPermissionRequested, value: "true")
        LogInfo("Marked location permission as requested")
    }

    // MARK: - Private Methods

    /// Map authorization status to LocationError
    private func mapAuthorizationToError(_ status: CLAuthorizationStatus) -> LocationError {
        switch status {
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .unavailable
        default:
            return .unavailable
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        LogInfo("Location authorization changed: \(status.rawValue)")

        authorizationStatus = status

        // Update error if permission was denied
        switch status {
        case .denied:
            locationError = .denied
        case .restricted:
            locationError = .restricted
        default:
            locationError = nil
        }
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            LogError("No location in didUpdateLocations")
            return
        }

        LogInfo("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        currentLocation = location
        locationError = nil

        // Resume continuation if waiting
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        LogError("Location manager failed: \(error.localizedDescription)")

        let locationError: LocationError

        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = .denied
            case .locationUnknown:
                locationError = .unavailable
            default:
                locationError = .failed(clError.localizedDescription)
            }
        } else {
            locationError = .failed(error.localizedDescription)
        }

        self.locationError = locationError

        // Resume continuation with error if waiting
        locationContinuation?.resume(throwing: locationError)
        locationContinuation = nil
    }
}
