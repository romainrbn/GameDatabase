//
//  UserDefault.swift
//  TheGameDatabase
//
//  Created by Romain Rabouan on 6/6/25.
//

import Foundation

@propertyWrapper
public struct UserDefault<T: PlistCodable & Equatable> {
    public let key: String
    public let defaultValue: T

    public init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            if newValue == defaultValue {
                UserDefaults.standard.removeObject(forKey: key)
            } else if let plistValue = newValue.plistValue {
                UserDefaults.standard.set(plistValue, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}

public typealias AnyCodableEquatable = any Codable & Equatable

public protocol PlistCodable {
    var plistValue: AnyCodableEquatable? { get }
}

extension Optional: PlistCodable {
    public var plistValue: AnyCodableEquatable? {
        switch self {
        case .none:
            return nil
        case .some(let wrapped):
            guard wrapped is PlistCodable else { return nil }
            return wrapped as? AnyCodableEquatable
        }
    }
}

extension String: PlistCodable {
    public var plistValue: AnyCodableEquatable? { self }
}

extension Data: PlistCodable {
    public var plistValue: AnyCodableEquatable? { self }
}

extension Date: PlistCodable {
    public var plistValue: AnyCodableEquatable? { self }
}

extension Bool: PlistCodable {
    public var plistValue: AnyCodableEquatable? { self }
}

extension Int: PlistCodable {
    public var plistValue: AnyCodableEquatable? { self }
}

extension UInt: PlistCodable {
    public var plistValue: AnyCodableEquatable? { self }
}

extension Int32: PlistCodable {
    public var plistValue: AnyCodableEquatable? { self }
}

extension UInt32: PlistCodable {
    public var plistValue: AnyCodableEquatable? { self }
}

extension Int16: PlistCodable {
    public var plistValue: AnyCodableEquatable? { self }
}

extension UInt16: PlistCodable {
    public var plistValue: AnyCodableEquatable? { self }
}

extension Int8: PlistCodable {
    public var plistValue: AnyCodableEquatable? { self }
}

extension UInt8: PlistCodable {
    public var plistValue: AnyCodableEquatable? { self }
}

extension Double: PlistCodable {
    public var plistValue: AnyCodableEquatable? { self }
}

extension Array: PlistCodable {
    public var plistValue: AnyCodableEquatable? {
        switch Element.self {
        case is PlistCodable.Type:
            return self as? AnyCodableEquatable
        default:
            return (self.first as? Array)?.plistValue != nil ? self as? AnyCodableEquatable : nil
        }
    }
}

extension Dictionary: PlistCodable {
    public var plistValue: AnyCodableEquatable? {
        guard Key.self == String.self else {
            assert(false, "Invalid key type. Use String.")
            return nil
        }

        switch Value.self {
        case is PlistCodable.Type:
            return self as? AnyCodableEquatable
        default:
            return (self.first?.value as? Dictionary)?.plistValue != nil ? self as? AnyCodableEquatable : nil
        }
    }
}
