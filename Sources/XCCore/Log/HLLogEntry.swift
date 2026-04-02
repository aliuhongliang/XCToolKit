// HLLogEntry.swift
// XCCore/Logging

import Foundation

public struct HLLogEntry {
    public let timestamp: Date
    public let level: HLLogLevel
    public let message: String
    public let tag: String?
    public let file: String
    public let function: String
    public let line: Int

    /// 格式化完整日志字符串
    /// - Parameter includeEmoji: 控制台输出传 true，文件写入传 false
    public func formatted(includeEmoji: Bool = true) -> String {
        let ts = Self.formatter.string(from: timestamp)
        let filename = URL(fileURLWithPath: file).lastPathComponent
        let location = "\(filename):\(line) \(function)"
        let prefix = includeEmoji ? "\(level.emoji) " : ""
        let tagStr = tag.map { "[\($0)] " } ?? ""
        return "\(ts) \(prefix)[\(level)] \(tagStr)\(message)  (\(location))"
    }

    // 带毫秒的本地时间
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        f.locale = .current
        return f
    }()
}
