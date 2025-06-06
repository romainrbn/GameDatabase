import Foundation
import SwiftUI
import Query

protocol QueryValue {
    var queryString: String { get }
}

extension String  : QueryValue { var queryString: String { "\"\(self)\"" } }
extension Int     : QueryValue { var queryString: String { "\(self)" } }
extension Double  : QueryValue { var queryString: String { "\(self)" } }
extension Bool    : QueryValue { var queryString: String { "\(self)" } }

extension Optional: QueryValue where Wrapped: QueryValue {
    var queryString: String {
        switch self {
        case .some(let w): return w.queryString
        case .none:        return "null"
        }
    }
}

extension Array: QueryValue where Element: QueryValue {
    var queryString: String { "[\(map { $0.queryString }.joined(separator: ","))]" }
}

protocol Queryable {
    static func fieldName(for: PartialKeyPath<Self>) -> String?
}

@propertyWrapper
struct Field<Value: Decodable>: Decodable {
    let key: String
    var wrappedValue: Value?

    init(key: String) {
        self.key = key
        self.wrappedValue = nil
    }
}

struct WhereClause { let condition: String }

private func makeWhere<Model: Queryable, VP, V: QueryValue>(
    _ kp: KeyPath<Model, VP>, op: String, _ value: V) -> WhereClause
{
    guard let key = Model.fieldName(for: kp) else {
        return WhereClause(condition: "")
    }
    return WhereClause(condition: "\(key) \(op) \(value.queryString)")
}

// Comparison operators (operate on *any* value/wrapped key-path)
func == <M: Queryable, VP, V: QueryValue>(lhs: KeyPath<M, VP>, rhs: V) -> WhereClause { makeWhere(lhs, op: "=",  rhs) }
func != <M: Queryable, VP, V: QueryValue>(lhs: KeyPath<M, VP>, rhs: V) -> WhereClause { makeWhere(lhs, op: "!=", rhs) }
func  > <M: Queryable, VP, V: QueryValue>(lhs: KeyPath<M, VP>, rhs: V) -> WhereClause { makeWhere(lhs, op: ">",  rhs) }
func  < <M: Queryable, VP, V: QueryValue>(lhs: KeyPath<M, VP>, rhs: V) -> WhereClause { makeWhere(lhs, op: "<",  rhs) }
func >= <M: Queryable, VP, V: QueryValue>(lhs: KeyPath<M, VP>, rhs: V) -> WhereClause { makeWhere(lhs, op: ">=", rhs) }
func <= <M: Queryable, VP, V: QueryValue>(lhs: KeyPath<M, VP>, rhs: V) -> WhereClause { makeWhere(lhs, op: "<=", rhs) }

// Logical combinators
func && (l: WhereClause, r: WhereClause) -> WhereClause { .init(condition: "(\(l.condition) & \(r.condition))") }
func || (l: WhereClause, r: WhereClause) -> WhereClause { .init(condition: "(\(l.condition) | \(r.condition))") }

struct FieldSelection<Model: Queryable> {
    let keys: [String]
    var queryString: String { "fields \(keys.joined(separator: ","));" }

    init(_ kps: [PartialKeyPath<Model>]) {
        self.keys = kps.compactMap { Model.fieldName(for: $0) }
    }
}

@dynamicMemberLookup
struct Path<Model: Queryable> {
    subscript<Value>(dynamicMember kp: KeyPath<Model, Value>) -> KeyPath<Model, Value> { kp }
}

enum SortDirection: String { case ascending = "asc", descending = "desc" }

final class QueryBuilder<Model: Queryable> {
    private var parts: [String] = []

    @discardableResult
    func fields(_ kps: PartialKeyPath<Model>...) -> Self {
        parts.append(FieldSelection(kps).queryString); return self
    }

    @discardableResult
    func fields(_ build: (Path<Model>) -> [PartialKeyPath<Model>]) -> Self {
        parts.append(FieldSelection(build(Path())).queryString); return self
    }

    @discardableResult
    func `where`(_ build: (Path<Model>) -> WhereClause) -> Self {
        parts.append("where \(build(Path()).condition);"); return self
    }

    @discardableResult
    func limit(_ n: Int) -> Self   { parts.append("limit \(n);");  return self }
    @discardableResult
    func offset(_ n: Int) -> Self  { parts.append("offset \(n);"); return self }

    @discardableResult
    func sort(by kp: KeyPath<Model, Any>, _ dir: SortDirection = .ascending) -> Self {
        if let key = Model.fieldName(for: kp) { parts.append("sort \(key) \(dir.rawValue);") }
        return self
    }

    func build() -> String { parts.joined(separator: "\n") }
}

@QueryableModel
struct GameCharacter: Decodable, Queryable {
    @Field(key: "akas")         var akas:        [String]?
    @Field(key: "checksum")     var checksum:    String?
    @Field(key: "country_name") var countryName: String?
    @Field(key: "created_at")   var createdAt:   Int?
    @Field(key: "description")  var description: String?
    @Field(key: "games")        var games:       [Int]?
    @Field(key: "gender")       var gender:      Int?
    @Field(key: "mug_shot")     var mugShot:     Int?
    @Field(key: "name")         var name:        String?
    @Field(key: "slug")         var slug:        String?
    @Field(key: "species")      var species:     Int?
    @Field(key: "updated_at")   var updatedAt:   Int?
    @Field(key: "url")          var url:         String?
}

enum IGDBError: Error { case invalidURL, invalidResponse }

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
        self.apiKey = apiKey; self.clientId = clientId; self.session = session
    }

    func query<Model: Queryable & Decodable>(
        endpoint: String,
        _ build: (QueryBuilder<Model>) -> QueryBuilder<Model>
    ) async throws -> [Model] {
        try await authIfNeeded()

        guard let authToken else { throw QueryError.missingToken }

        let body = build(QueryBuilder<Model>()).build()
        guard let url = URL(string: "https://api.igdb.com/v4/\(endpoint)") else { throw IGDBError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(authToken)",   forHTTPHeaderField: "Authorization")
        req.setValue(clientId,             forHTTPHeaderField: "Client-ID")
        req.setValue("text/plain",         forHTTPHeaderField: "Content-Type")
        req.httpBody = body.data(using: .utf8)

        let (data, resp) = try await session.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode ?? 500 < 300 else { throw IGDBError.invalidResponse }
        return try JSONDecoder().decode([Model].self, from: data)
    }

    private func authIfNeeded() async throws {
        if let lastTokenTTL, Date.now.timeIntervalSince1970 < lastTokenTTL {
            return
        }

        guard let url = URL(string: "https://id.twitch.tv/oauth2/token?client_id=\(clientId)&client_secret=\(apiKey)&grant_type=client_credentials") else {
            throw AuthError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        let (data, response) = try await session.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode ?? 500 < 300 else { throw IGDBError.invalidResponse }

        let auth = try JSONDecoder().decode(AuthResult.self, from: data)

        self.authToken = auth.accessToken
        self.lastTokenTTL = Date.now.timeIntervalSince1970 + Double(auth.expiresIn)
    }
}

enum Endpoints {
    struct Character {
        static let path = "characters"
        typealias Model = GameCharacter
    }
}

func performFetch(client: IGDBClient) async throws {
    let characters: [GameCharacter] = try await client.query(endpoint: Endpoints.Character.path) { builder in
        builder
            .fields { [$0.name, $0.description, $0.games] }
            .where { $0.name == "Arthur Morgan" }
            .limit(1)
    }

    print("Fetched:", characters.count, "characters")

    // Now you can safely access the fields that were requested
    if let character = characters.first {
        print("Name:", character.name ?? "N/A")
        print("Description:", character.description ?? "N/A")
        print("Games:", character.games ?? [])
        // Other fields will be nil since they weren't requested
        print("Akas:", character.akas ?? []) // This will print []
    }
}

extension EnvironmentValues {
    @Entry var dbClient = IGDBClient(
        apiKey: ProcessInfo.processInfo.environment["SECRET"]!,
        clientId: ProcessInfo.processInfo.environment["CLIENT_ID"]!
    )
}
