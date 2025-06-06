//
//  QueryBuilder.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import Foundation

enum SortDirection: String {
    case ascending = "asc"
    case descending = "desc"
}

final class QueryBuilder<Model: Queryable> {
    private var parts: [String] = []

    @discardableResult
    func fields(_ keyPaths: PartialKeyPath<Model>...) -> Self {
        parts.append(FieldSelection(keyPaths).queryString)
        return self
    }

    @discardableResult
    func fields(_ build: (Path<Model>) -> [PartialKeyPath<Model>]) -> Self {
        parts.append(FieldSelection(build(Path())).queryString)
        return self
    }

    @discardableResult
    func `where`(_ build: (Path<Model>) -> WhereClause) -> Self {
        parts.append("where \(build(Path()).condition);")
        return self
    }

    @discardableResult
    func limit(_ count: Int) -> Self {
        parts.append("limit \(count);")
        return self
    }

    @discardableResult
    func offset(_ count: Int) -> Self {
        parts.append("offset \(count);")
        return self
    }

    @discardableResult
    func sort(by keyPath: KeyPath<Model, Any>, _ direction: SortDirection = .ascending) -> Self {
        if let key = Model.fieldName(for: keyPath) {
            parts.append("sort \(key) \(direction.rawValue);")
        }
        return self
    }

    func build() -> String {
        return parts.joined(separator: "\n")
    }
}
