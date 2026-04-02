// HLConsoleDestination.swift
// XCCore/Logging

import Foundation
import os.log

public final class HLConsoleDestination: HLLogDestination {
    public var minimumLevel: HLLogLevel?

    private let subsystem: String

    private lazy var osLogs: [HLLogLevel: OSLog] = [
        .debug:   OSLog(subsystem: subsystem, category: "debug"),
        .info:    OSLog(subsystem: subsystem, category: "info"),
        .warning: OSLog(subsystem: subsystem, category: "warning"),
        .error:   OSLog(subsystem: subsystem, category: "error"),
    ]

    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "com.hllogger") {
        self.subsystem = subsystem
    }

    public func write(_ entry: HLLogEntry) {
        let log = osLogs[entry.level] ?? .default
        let text = entry.formatted(includeEmoji: true)
        switch entry.level {
        case .debug:   os_log(.debug,   log: log, "%{public}@", text)
        case .info:    os_log(.info,    log: log, "%{public}@", text)
        case .warning: os_log(.default, log: log, "%{public}@", text)
        case .error:   os_log(.error,   log: log, "%{public}@", text)
        }
    }
}
