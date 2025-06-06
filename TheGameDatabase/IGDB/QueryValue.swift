//
//  QueryValue.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import Foundation

protocol QueryValue {
    var queryString: String { get }
}

extension String: QueryValue {
    var queryString: String {
        return "\"\(self)\""
    }
}

extension Int: QueryValue {
    var queryString: String {
        return "\(self)"
    }
}

extension Double: QueryValue {
    var queryString: String {
        return "\(self)"
    }
}

extension Bool: QueryValue {
    var queryString: String {
        return "\(self)"
    }
}

extension Optional: QueryValue where Wrapped: QueryValue {
    var queryString: String {
        switch self {
        case .some(let wrapped):
            return wrapped.queryString
        case .none:
            return "null"
        }
    }
}

extension Array: QueryValue where Element: QueryValue {
    var queryString: String {
        let elements = map { $0.queryString }.joined(separator: ",")
        return "[\(elements)]"
    }
}
