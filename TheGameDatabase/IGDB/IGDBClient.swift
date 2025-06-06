//
//  IGDBCLient.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "com.romainrbn.TheGameDatabase", category: "WS")

enum IGDBError: Error {
    case invalidURL
    case invalidResponse
}

struct AuthResult: Decodable {
    let accessToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }
}

final class IGDBClient {
    private let apiKey: String
    private let clientId: String
    private let session: URLSession

    enum AuthError: Error {
        case invalidURL
    }

    enum QueryError: Error {
        case missingToken
    }

    @UserDefault("IGDBToken", defaultValue: nil)
    private var authToken: String?

    @UserDefault("LastTokenTTL", defaultValue: nil)
    private var lastTokenTTL: TimeInterval?

    init(apiKey: String, clientId: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.clientId = clientId
        self.session = session
    }

    func query<Model: Queryable & Decodable>(
        endpoint: String,
        _ build: (QueryBuilder<Model>) -> QueryBuilder<Model>
    ) async throws -> [Model] {
        try await authIfNeeded()

        guard let authToken else {
            throw QueryError.missingToken
        }

        let body = build(QueryBuilder<Model>()).build()
        guard let url = URL(string: "https://api.igdb.com/v4/\(endpoint)") else {
            throw IGDBError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        request.setValue(clientId, forHTTPHeaderField: "Client-ID")
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        logger.debug("Made WS Request to URL: \(request.url?.absoluteString ?? "-")")

        guard (response as? HTTPURLResponse)?.statusCode ?? 500 < 300 else {
            throw IGDBError.invalidResponse
        }

        return try JSONDecoder().decode([Model].self, from: data)
    }

    private func authIfNeeded() async throws {
        if let lastTokenTTL, Date.now.timeIntervalSince1970 < lastTokenTTL {
            return
        }

        let urlString = "https://id.twitch.tv/oauth2/token?client_id=\(clientId)&client_secret=\(apiKey)&grant_type=client_credentials"
        guard let url = URL(string: urlString) else {
            throw AuthError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode ?? 500 < 300 else {
            throw IGDBError.invalidResponse
        }

        let auth = try JSONDecoder().decode(AuthResult.self, from: data)

        self.authToken = auth.accessToken
        self.lastTokenTTL = Date.now.timeIntervalSince1970 + Double(auth.expiresIn)
    }
}
