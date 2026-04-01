// Date+Extension.swift
// Date 工具扩展
//
// 模块：
//   1. Date → String（格式化输出）
//   2. 时间戳互转
//   3. 时间计算
//   4. 时间判断
//   5. 时间差显示（timeAgo / countdown / components）
//   6. 共用 DateFormatterCache

import Foundation

// MARK: ========================================
// MARK: - 1. Date → String
// MARK: ========================================

public extension Date {

    /// 按指定格式输出字符串
    func string(format: String) -> String {
        DateFormatterCache.shared.formatter(for: format).string(from: self)
    }

    /// "2024-01-01"
    var dateString: String { string(format: "yyyy-MM-dd") }

    /// "14:30:00"
    var timeString: String { string(format: "HH:mm:ss") }

    /// "14:30"
    var shortTimeString: String { string(format: "HH:mm") }

    /// "2024-01-01 14:30:00"
    var dateTimeString: String { string(format: "yyyy-MM-dd HH:mm:ss") }

    /// "01-01"
    var monthDayString: String { string(format: "MM-dd") }

    /// "2024-01"
    var yearMonthString: String { string(format: "yyyy-MM") }

    /// "2024年01月01日"
    var chineseDateString: String { string(format: "yyyy年MM月dd日") }

    /// "01月01日 14:30"
    var chineseMonthDayTimeString: String { string(format: "MM月dd日 HH:mm") }
}

// MARK: ========================================
// MARK: - 2. 时间戳互转
// MARK: ========================================

public extension Date {

    /// 秒级时间戳
    var timestamp: Int { Int(timeIntervalSince1970) }

    /// 毫秒级时间戳
    var millisecondTimestamp: Int { Int(timeIntervalSince1970 * 1000) }

    /// 当前时间秒级时间戳
    static var currentTimestamp: Int { Int(Date().timeIntervalSince1970) }

    /// 当前时间毫秒级时间戳
    static var currentMillisecondTimestamp: Int { Int(Date().timeIntervalSince1970 * 1000) }

    /// 从秒级时间戳创建
    static func from(timestamp: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
    }

    /// 从毫秒级时间戳创建
    static func from(milliseconds: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }

    /// 自动识别秒级/毫秒级时间戳（> 1e10 视为毫秒）
    static func from(autoTimestamp ts: Int) -> Date {
        ts > 10_000_000_000
            ? from(milliseconds: ts)
            : from(timestamp: ts)
    }
}

// MARK: ========================================
// MARK: - 3. 时间计算
// MARK: ========================================

public extension Date {

    /// 增加指定天数（负数为减少）
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    /// 增加指定小时
    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    /// 增加指定分钟
    func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    /// 增加指定秒数
    func adding(seconds: Int) -> Date {
        Calendar.current.date(byAdding: .second, value: seconds, to: self) ?? self
    }

    /// 增加指定月数
    func adding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// 当天 00:00:00
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// 当天 23:59:59
    var endOfDay: Date {
        var comps = DateComponents()
        comps.day = 1
        comps.second = -1
        return Calendar.current.date(byAdding: comps, to: startOfDay) ?? self
    }

    /// 本周第一天（周一）
    var startOfWeek: Date {
        var cal = Calendar.current
        cal.firstWeekday = 2  // 周一为第一天
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: comps) ?? self
    }

    /// 本周最后一天（周日）23:59:59
    var endOfWeek: Date {
        startOfWeek.adding(days: 6).endOfDay
    }

    /// 本月第一天 00:00:00
    var startOfMonth: Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: comps) ?? self
    }

    /// 本月最后一天 23:59:59
    var endOfMonth: Date {
        adding(months: 1).startOfMonth.adding(seconds: -1)
    }
}

// MARK: ========================================
// MARK: - 4. 时间判断
// MARK: ========================================

public extension Date {

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }

    var isInFuture: Bool {
        self > Date()
    }

    var isInPast: Bool {
        self < Date()
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    func isSameMonth(as other: Date) -> Bool {
        let cal  = Calendar.current
        let self_ = cal.dateComponents([.year, .month], from: self)
        let other_ = cal.dateComponents([.year, .month], from: other)
        return self_.year == other_.year && self_.month == other_.month
    }

    /// 根据生日计算年龄
    var age: Int {
        Calendar.current.dateComponents([.year], from: self, to: Date()).year ?? 0
    }
}

// MARK: ========================================
// MARK: - 5. 时间差显示
// MARK: ========================================

public extension Date {

    /// 相对时间描述（中文）
    /// 刚刚 / 3分钟前 / 1小时前 / 昨天 / 3天前 / 2024-01-01
    var timeAgo: String {
        let now      = Date()
        let interval = now.timeIntervalSince(self)

        if interval < 60 {
            return "刚刚"
        } else if interval < 3600 {
            return "\(Int(interval / 60))分钟前"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))小时前"
        } else if isYesterday {
            return "昨天 \(shortTimeString)"
        } else if interval < 86400 * 7 {
            return "\(Int(interval / 86400))天前"
        } else {
            return dateString
        }
    }

    /// 倒计时字符串（距目标时间）
    /// 超过1天  → "3天 02:45:30"
    /// 超过1小时 → "02:45:30"
    /// 不足1小时 → "45:30"
    func countdown(to target: Date) -> String {
        let diff = Int(target.timeIntervalSince(self))
        guard diff > 0 else { return "00:00" }

        let days = diff / 86400
        let hours = (diff % 86400) / 3600
        let minutes = (diff % 3600) / 60
        let seconds = diff % 60

        if days > 0 {
            return "\(days)天 \(String(format: "%02d:%02d:%02d", hours, minutes, seconds))"
        } else if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    /// 精确时间差分量
    typealias DateComponents_ = (days: Int, hours: Int, minutes: Int, seconds: Int)

    func components(to other: Date) -> DateComponents_ {
        let diff = Int(abs(other.timeIntervalSince(self)))
        return (
            days:    diff / 86400,
            hours:   (diff % 86400) / 3600,
            minutes: (diff % 3600) / 60,
            seconds: diff % 60
        )
    }
}

// MARK: ========================================
// MARK: - 6. DateFormatterCache（String+Extension 共用）
// MARK: ========================================

/// DateFormatter 创建开销大，缓存复用避免重复创建
final class DateFormatterCache {

    static let shared = DateFormatterCache()
    private init() {}

    private var cache: [String: DateFormatter] = [:]
    private let lock = NSLock()

    func formatter(for format: String) -> DateFormatter {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cache[format] { return cached }
        let formatter = DateFormatter()
        formatter.dateFormat = format
//        formatter.locale = Locale(identifier: "zh_CN")
        formatter.locale = Locale.current
//        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.timeZone = TimeZone.current
        cache[format] = formatter
        return formatter
    }
}
