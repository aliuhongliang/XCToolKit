// HLFileDestination.swift
// XCCore/Logging

import Foundation

public final class HLFileDestination: HLLogDestination {
    public var minimumLevel: HLLogLevel?

    /// 日志存放目录，默认 Library/Logs/HLLogs
    public let logDirectory: URL

    /// 最多保留天数，默认 7 天
    public var maxRetainDays: Int = 7

    private let queue = DispatchQueue(label: "com.hllogger.file", qos: .background)
    private var currentFileHandle: FileHandle?
    private var currentDateString: String = ""

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = .current
        return f
    }()

    public init(logDirectory: URL? = nil) {
        if let dir = logDirectory {
            self.logDirectory = dir
        } else {
            let library = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            self.logDirectory = library.appendingPathComponent("Logs/HLLogs", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: self.logDirectory,
                                                  withIntermediateDirectories: true)
    }

    public func write(_ entry: HLLogEntry) {
        queue.async { [weak self] in
            guard let self else { return }
            self.rotateIfNeeded(for: entry.timestamp)
            let line = entry.formatted(includeEmoji: false) + "\n"
            if let data = line.data(using: .utf8) {
                self.currentFileHandle?.write(data)
            }
        }
    }

    /// 获取所有本地日志文件 URL（主线程调用）
    public func allLogFiles() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: logDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ))?.filter { $0.pathExtension == "log" }
          .sorted { $0.lastPathComponent < $1.lastPathComponent }
        ?? []
    }

    /// 手动清理超出保留天数的旧日志
    public func cleanOldLogs() {
        queue.async { [weak self] in
            guard let self else { return }
            self._cleanOldLogs()
        }
    }

    // MARK: - Private

    private func rotateIfNeeded(for date: Date) {
        let dateStr = Self.dateFormatter.string(from: date)
        guard dateStr != currentDateString else { return }

        currentFileHandle?.closeFile()
        currentFileHandle = nil
        currentDateString = dateStr

        let fileURL = logDirectory.appendingPathComponent("hllog-\(dateStr).log")
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }
        currentFileHandle = try? FileHandle(forWritingTo: fileURL)
        currentFileHandle?.seekToEndOfFile()

        _cleanOldLogs()
    }

    private func _cleanOldLogs() {
        guard let cutoff = Calendar.current.date(byAdding: .day,
                                                  value: -maxRetainDays,
                                                  to: Date()) else { return }
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: logDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        for url in files where url.pathExtension == "log" {
            let created = (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date()
            if created < cutoff {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}
