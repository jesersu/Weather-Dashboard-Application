//
//  MockAPIClient.swift
//  NetworkingKit
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation

public final class MockAPIClient: APIClient {
    public var result: Any?
    public var error: Error?

    public init() {}

    public func request<Response>(_ request: APIRequest<Response>) async throws -> Response where Response: Decodable {
        if let error = error {
            throw error
        }
        guard let value = result as? Response else {
            throw URLError(.badServerResponse)
        }
        return value
    }
}
