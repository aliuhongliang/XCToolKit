// HLLogOutput.swift
// XCCore/Logging

import Foundation

// MARK: - HLLogOutput（输出开关）

public struct HLLogOutput: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let console = HLLogOutput(rawValue: 1 << 0)
    public static let file    = HLLogOutput(rawValue: 1 << 1)
    public static let remote  = HLLogOutput(rawValue: 1 << 2)

    public static let all: HLLogOutput = [.console, .file, .remote]
}

// MARK: - HLLogDestination（输出目标协议）

public protocol HLLogDestination: AnyObject {
    /// 该 destination 独立的最低输出级别，nil 则跟随 HLLogger.shared.minimumLevel
    var minimumLevel: HLLogLevel? { get set }
    func write(_ entry: HLLogEntry)
}
