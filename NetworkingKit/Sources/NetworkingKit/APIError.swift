//
//  APIError.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation

public enum APIError: LocalizedError, Equatable {
    case noInternetConnection
    case serverError(statusCode: Int, response: String)
    case invalidCity
    case unknownError

    public var message: String {
        switch self {
        case .noInternetConnection:
            "No internet connection available"
        case let .serverError(statusCode, response):
            "Failed with status code: \(statusCode), response: \(response)"
        case .invalidCity:
            "City not found. Please check the spelling and try again."
        case .unknownError:
            "Unable to provide an error response"
        }
    }

    public var errorDescription: String? {
        message
    }

    // MARK: - Equatable
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.noInternetConnection, .noInternetConnection):
            return true
        case (.invalidCity, .invalidCity):
            return true
        case (.unknownError, .unknownError):
            return true
        case let (.serverError(lStatus, lResponse), .serverError(rStatus, rResponse)):
            return lStatus == rStatus && lResponse == rResponse
        default:
            return false
        }
    }
}
