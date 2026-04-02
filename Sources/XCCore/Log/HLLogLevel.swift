// HLLogLevel.swift
// XCCore/Logging

import Foundation

public enum HLLogLevel: Int, Comparable, CustomStringConvertible {
    case debug   = 0
    case info    = 1
    case warning = 2
    case error   = 3

    public static func < (lhs: HLLogLevel, rhs: HLLogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var description: String {
        switch self {
        case .debug:   return "DEBUG"
        case .info:    return "INFO"
        case .warning: return "WARN"
        case .error:   return "ERROR"
        }
    }

    public var emoji: String {
        switch self {
        case .debug:   return "🔍"
        case .info:    return "ℹ️"
        case .warning: return "⚠️"
        case .error:   return "🔴"
        }
    }
}
