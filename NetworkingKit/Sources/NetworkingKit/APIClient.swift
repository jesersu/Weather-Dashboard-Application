//
//  APIClient.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation

public protocol APIClient {
    @discardableResult
    func request<Response: Decodable>(_ request: APIRequest<Response>) async throws -> Response
}

public protocol Endpoint {
    associatedtype Response: Decodable

    var baseURL: URL { get }
    var path: String { get }
    var query: [String: String] { get }
    var method: APIRequest<Response>.Method { get }
    var headers: [String: String]? { get }
}

public extension Endpoint {
    func build() -> APIRequest<Response> {
        .init(
            path: path,
            query: query,
            method: method,
            headers: headers
        )
    }
}
