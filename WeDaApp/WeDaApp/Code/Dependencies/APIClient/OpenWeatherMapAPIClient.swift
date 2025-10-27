//
//  OpenWeatherMapAPIClient.swift
//  WeDaApp
//
//  Created by Jesus Chapi
//  Copyright © 2025 Dollar General. All rights reserved.
//

import ArkanaKeys
import Foundation
import NetworkingKit

public struct OpenWeatherMapAPIClient: APIClient {
    public init() {}

    @discardableResult
    public func request<Response>(_ request: APIRequest<Response>) async throws -> Response where Response: Decodable {
        let url = try buildURL(from: request)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.stringValue
        urlRequest.timeoutInterval = 30

        switch request.method {
        case .post(let body), .put(let body):
            urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: body)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        default:
            break
        }

        if let headers = request.headers {
            headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknownError
            }

            // Handle specific HTTP status codes
            switch httpResponse.statusCode {
            case 200..<300:
                return try decodeResponse(data: data, decoder: request.decoder)
            case 404:
                throw APIError.invalidCity
            case 401, 403:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unauthorized"
                throw APIError.serverError(statusCode: httpResponse.statusCode, response: errorMessage)
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError.serverError(statusCode: httpResponse.statusCode, response: errorMessage)
            }
        } catch let error as APIError {
            throw error
        } catch let urlError as URLError {
            if urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
                throw APIError.noInternetConnection
            }
            throw APIError.unknownError
        } catch {
            throw APIError.unknownError
        }
    }

    private func decodeResponse<Response: Decodable>(data: Data, decoder: JSONDecoder) throws -> Response {
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            if let dataString = String(data: data, encoding: .utf8) {
                print("Response data: \(dataString)")
            }
            throw APIError.unknownError
        }
    }

    public func buildURL<Response>(from request: APIRequest<Response>) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = URL(string: ArkanaKeys.Global().openWeatherMapBaseUrl)?.host
        components.path = request.path

        if let query = request.query as? [String: String] {
            components.queryItems = query.map { URLQueryItem(name: $0, value: $1) }
        }

        guard let url = components.url else {
            throw APIError.unknownError
        }

        return url
    }
}
