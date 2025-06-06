//
//  Queryable.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import Foundation

protocol Queryable {
    static func fieldName(for keyPath: PartialKeyPath<Self>) -> String?
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
