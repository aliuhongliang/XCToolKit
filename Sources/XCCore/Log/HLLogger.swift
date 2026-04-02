// HLLogger.swift
// XCCore/Logging
//
// 用法：
//   // AppDelegate / App entry
//   HLLog.setup(outputs: [.console, .file], minimumLevel: .debug)
//
//   // 业务代码
//   HLLog.debug("pipeline started")
//   HLLog.info("user", userId, "logged in")
//   HLLog.warning("retry", count, "times", tag: "Network")
//   HLLog.error("stream crash", error, tag: "GStreamer")
//
//   // 运行时动态切换输出目标
//   HLLogger.shared.setOutputs([.console])

import Foundation

// MARK: - HLLogger

public final class HLLogger {

    public static let shared = HLLogger()

    /// 全局最低输出级别
    public var minimumLevel: HLLogLevel = .debug

    /// 总开关，false 时所有日志静默
    public var isEnabled: Bool = true

    // destination 实例
    private let console: HLConsoleDestination
    private let file: HLFileDestination

    // 当前激活的输出目标（由 outputs 驱动）
    private var activeDestinations: [HLLogDestination] = []

    // 外部注册的 remote destination
    private var remoteDestination: HLLogDestination?

    private let lock = NSLock()

    private init() {
        console = HLConsoleDestination()
        file = HLFileDestination()
    }

    // MARK: - 输出开关

    /// 设置激活的输出目标组合
    public func setOutputs(_ outputs: HLLogOutput) {
        lock.lock(); defer { lock.unlock() }
        var destinations: [HLLogDestination] = []
        if outputs.contains(.console) { destinations.append(console) }
        if outputs.contains(.file)    { destinations.append(file) }
        if outputs.contains(.remote), let remote = remoteDestination {
            destinations.append(remote)
        }
        activeDestinations = destinations
    }

    /// 注册 remote destination，注册后需在 outputs 中包含 .remote 才会生效
    public func setRemoteDestination(_ destination: HLLogDestination) {
        lock.lock(); defer { lock.unlock() }
        remoteDestination = destination
        // 若当前已包含 remote，立即替换
        activeDestinations = activeDestinations.filter { !($0 === remoteDestination) }
        if activeDestinations.contains(where: { $0 === console || $0 === file }) {
            activeDestinations.append(destination)
        }
    }

    /// 直接访问 FileDestination，用于获取日志文件列表等操作
    public var fileDestination: HLFileDestination { file }

    /// 直接访问 ConsoleDestination，用于单独设置 minimumLevel 等
    public var consoleDestination: HLConsoleDestination { console }

    // MARK: - 写入

    func log(level: HLLogLevel,
             items: [Any],
             tag: String?,
             file: String,
             function: String,
             line: Int) {
        guard isEnabled, level >= minimumLevel else { return }

        let message = items.map { "\($0)" }.joined(separator: " ")
        let entry = HLLogEntry(
            timestamp: Date(),
            level: level,
            message: message,
            tag: tag,
            file: file,
            function: function,
            line: line
        )

        lock.lock()
        let current = activeDestinations
        lock.unlock()

        for dest in current {
            if let destMin = dest.minimumLevel, level < destMin { continue }
            dest.write(entry)
        }
    }
}

// MARK: - HLLog（全局静态入口）

public enum HLLog {

    // MARK: Setup

    /// 一行完成初始化
    /// - Parameters:
    ///   - outputs: 激活的输出目标，默认控制台 + 文件
    ///   - minimumLevel: 全局最低级别，默认 debug
    ///   - subsystem: os_log subsystem，默认 Bundle ID
    public static func setup(
        outputs: HLLogOutput = [.console, .file],
        minimumLevel: HLLogLevel = .debug,
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.hllogger"
    ) {
        HLLogger.shared.minimumLevel = minimumLevel
        HLLogger.shared.consoleDestination.minimumLevel = nil // 跟随全局
        HLLogger.shared.setOutputs(outputs)
    }

    // MARK: - 日志方法

    public static func debug(
        _ items: Any...,
        tag: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        HLLogger.shared.log(level: .debug, items: items, tag: tag,
                            file: file, function: function, line: line)
    }

    public static func info(
        _ items: Any...,
        tag: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        HLLogger.shared.log(level: .info, items: items, tag: tag,
                            file: file, function: function, line: line)
    }

    public static func warning(
        _ items: Any...,
        tag: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        HLLogger.shared.log(level: .warning, items: items, tag: tag,
                            file: file, function: function, line: line)
    }

    public static func error(
        _ items: Any...,
        tag: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        HLLogger.shared.log(level: .error, items: items, tag: tag,
                            file: file, function: function, line: line)
    }
}
