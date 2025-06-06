//
//  Fetchable.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import Foundation

protocol Fetchable {
    associatedtype Model: Queryable & Decodable

    static var endpoint: String { get }
    static var idKeyPath: KeyPath<Model, Int?> { get }
    static func buildQuery(_ builder: QueryBuilder<Model>) -> QueryBuilder<Model>
}

protocol DataTransferObject {
    init()

    func fetchDependencies(using client: IGDBClient) async throws
}

struct FetchRequest<T: Fetchable> {
    let ids: [Int]
    let fetchable: T.Type

    init(ids: [Int], fetchable: T.Type = T.self) {
        self.ids = ids
        self.fetchable = fetchable
    }
}

class DataFetcher {
    private let client: IGDBClient
    private var cache: [String: Any] = [:]

    init(client: IGDBClient) {
        self.client = client
    }

    func fetch<T: Fetchable>(_ request: FetchRequest<T>) async throws -> [T.Model] {
        let cacheKey = "\(T.endpoint)-\(request.ids.sorted())"

        if let cached = cache[cacheKey] as? [T.Model] {
            return cached
        }

        let results: [T.Model] = try await client.query(endpoint: T.endpoint) { builder in
            T.buildQuery(builder.where { _ in
                T.idKeyPath.isIn(request.ids)
            })
        }

        cache[cacheKey] = results
        return results
    }

    func clearCache() {
        cache.removeAll()
    }
}
