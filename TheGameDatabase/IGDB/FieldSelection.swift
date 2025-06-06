//
//  FieldSelection.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import Foundation

struct FieldSelection<Model: Queryable> {
    let keys: [String]

    var queryString: String {
        return "fields \(keys.joined(separator: ","));"
    }

    init(_ keyPaths: [PartialKeyPath<Model>]) {
        self.keys = keyPaths.compactMap { Model.fieldName(for: $0) }
    }
}

@dynamicMemberLookup
struct Path<Model: Queryable> {
    subscript<Value>(dynamicMember keyPath: KeyPath<Model, Value>) -> KeyPath<Model, Value> {
        return keyPath
    }
}
