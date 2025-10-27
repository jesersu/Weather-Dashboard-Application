//
//  APIRequest.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import Foundation

public struct APIRequest<Response: Decodable> {
    public var path: String
    public var query: [String: any Decodable]?
    public var method: Method = .get
    public var headers: [String: String]?
    public var decoder: JSONDecoder = .init()

    public init(
        path: String,
        query: [String: any Decodable]? = nil,
        method: Method = .get,
        headers: [String: String]? = nil,
        decoder: JSONDecoder = .init()
    ) {
        self.path = path
        self.query = query
        self.method = method
        self.headers = headers
        self.decoder = decoder
    }

    public enum Method {
        case get
        case post([String: Any])
        case put([String: Any])

        public var stringValue: String {
            switch self {
            case .get:
                return "GET"
            case .post:
                return "POST"
            case .put:
                return "PUT"
            }
        }
    }
}

struct EmptyResponse: Decodable {}
typealias NoResponseRequest = APIRequest<EmptyResponse>

extension APIRequest: CustomStringConvertible {
    public var description: String {
        """
    Request(
    path: \(path),
    query: \(query ?? [:]),
    method: \(method),
    headers: \(headers?.mapValues { $0.description.localizedCaseInsensitiveContains("Bearer") ? "***" : $0 } ?? [:])
)
"""
    }
}
