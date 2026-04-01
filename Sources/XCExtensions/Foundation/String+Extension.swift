// String+Extension.swift
// String 工具扩展
//
// 模块：
//   1. 判断 / 验证
//   2. 处理 / 转换
//   3. 截取 / 操作
//   4. 格式化（手机号 / 银行卡 / 金额 / 脱敏）
//   5. 时间格式化（秒转字符串）
//   6. 尺寸计算
//   7. 富文本
//   8. 本地化
//   9. 随机串
//  10. 版本号比较

import UIKit

// MARK: ========================================
// MARK: - 1. 判断 / 验证
// MARK: ========================================

public extension String {

    /// 是否为空或全是空白字符（空格、换行、制表符）
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 是否是合法国内手机号（1[3-9]xxxxxxxxx）
    var isValidPhone: Bool {
        matches(regex: "^1[3-9]\\d{9}$")
    }

    /// 是否是合法邮箱
    var isValidEmail: Bool {
        matches(regex: "^[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}$")
    }

    /// 是否是合法 URL
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return url.scheme != nil && url.host != nil
    }

    /// 是否是纯整数（支持负数）
    var isPureInt: Bool {
        matches(regex: "^-?\\d+$")
    }

    /// 是否是纯小数 / 整数（支持负数）
    var isPureFloat: Bool {
        matches(regex: "^-?\\d+(\\.\\d+)?$")
    }

    /// 内部正则匹配工具
    func matches(regex: String) -> Bool {
        range(of: regex, options: .regularExpression) != nil
    }
}

// MARK: ========================================
// MARK: - 2. 处理 / 转换
// MARK: ========================================

public extension String {

    /// 去掉首尾空格和换行
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 提取所有数字字符
    var digits: String {
        filter(\.isNumber)
    }

    /// 提取所有字母字符
    var letters: String {
        filter(\.isLetter)
    }

    /// URL 编码
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }

    /// URL 解码
    var urlDecoded: String {
        removingPercentEncoding ?? self
    }

    /// Base64 编码
    var base64Encoded: String {
        Data(utf8).base64EncodedString()
    }

    /// Base64 解码
    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self,
                              options: .ignoreUnknownCharacters) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 安全转 Int
    var toInt: Int? { Int(self) }

    /// 安全转 Double
    var toDouble: Double? { Double(self) }

    /// 安全转 Float
    var toFloat: Float? { Float(self) }

    /// 安全转 Bool（"true"/"1"/"yes" → true）
    var toBool: Bool? {
        switch lowercased().trimmed {
        case "true", "1", "yes": return true
        case "false", "0", "no": return false
        default: return nil
        }
    }

    /// 字符串转 Date
    /// - Parameter format: 日期格式，nil 时自动尝试常用格式
    func toDate(format: String? = nil) -> Date? {
        if let fmt = format {
            return DateFormatterCache.shared.formatter(for: fmt).date(from: self)
        }
        // 自动尝试常用格式
        let formats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd",
            "yyyy/MM/dd HH:mm:ss",
            "yyyy/MM/dd",
            "MM/dd/yyyy",
            "yyyyMMddHHmmss",
            "yyyyMMdd"
        ]
        for fmt in formats {
            if let date = DateFormatterCache.shared.formatter(for: fmt).date(from: self) {
                return date
            }
        }
        return nil
    }

    /// 按 Unicode 标量计数（emoji / 中文 各算 1 个）
    var unicodeCount: Int {
        unicodeScalars.count
    }
}

// MARK: ========================================
// MARK: - 3. 截取 / 操作（安全）
// MARK: ========================================

public extension String {

    /// 安全下标取字符
    subscript(index: Int) -> Character? {
        guard index >= 0, index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }

    /// 安全范围截取
    subscript(range: Range<Int>) -> String {
        let lower = Swift.max(0, range.lowerBound)
        let upper = Swift.min(count, range.upperBound)
        guard lower < upper else { return "" }
        let start = index(startIndex, offsetBy: lower)
        let end   = index(startIndex, offsetBy: upper)
        return String(self[start..<end])
    }

    /// 从指定位置截取指定长度
    func substring(from start: Int, length: Int) -> String {
        self[start..<(start + length)]
    }

    /// 去掉指定前缀
    func removePrefix(_ prefix: String) -> String {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
    }

    /// 去掉指定后缀
    func removeSuffix(_ suffix: String) -> String {
        hasSuffix(suffix) ? String(dropLast(suffix.count)) : self
    }

    /// 超长截断并加省略号
    func truncated(to maxLength: Int, tail: String = "...") -> String {
        guard count > maxLength else { return self }
        return self[0..<Swift.max(0, maxLength - tail.count)] + tail
    }

    /// 每隔 N 位插入分隔符（银行卡 / 序列号格式化复用）
    func insertSeparator(_ separator: String, every n: Int) -> String {
        var result = ""
        for (i, char) in enumerated() {
            if i > 0 && i % n == 0 { result += separator }
            result.append(char)
        }
        return result
    }
}

// MARK: ========================================
// MARK: - 4. 格式化
// MARK: ========================================

public extension String {

    // MARK: 展示格式化

    /// 手机号格式化：13812345678 → 138 1234 5678
    var formattedPhone: String {
        let d = digits
        guard d.count == 11 else { return self }
        return "\(d[0..<3]) \(d[3..<7]) \(d[7..<11])"
    }

    /// 银行卡格式化：每4位加空格
    var formattedBankCard: String {
        digits.insertSeparator(" ", every: 4)
    }

    /// 金额格式化：1234567.89 → 1,234,567.89
    /// - Parameter decimalPlaces: 保留小数位数，默认 2
    func formattedAmount(decimalPlaces: Int = 2) -> String {
        guard let value = toDouble else { return self }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimalPlaces
        formatter.maximumFractionDigits = decimalPlaces
        return formatter.string(from: NSNumber(value: value)) ?? self
    }

    /// 金额格式化（默认2位小数）
    var formattedAmount: String { formattedAmount() }

    // MARK: 脱敏

    /// 手机号脱敏：13812345678 → 138****5678
    var maskedPhone: String {
        let d = digits
        guard d.count == 11 else { return self }
        return "\(d[0..<3])****\(d[7..<11])"
    }

    /// 银行卡脱敏：保留后4位 → **** **** **** 7890
    var maskedBankCard: String {
        let d = digits
        guard d.count >= 4 else { return self }
        let last4 = d[Swift.max(0, d.count - 4)..<d.count]
        let masked = String(repeating: "*", count: d.count - 4)
        return (masked + last4).insertSeparator(" ", every: 4)
    }

    /// 身份证脱敏：110101199001011234 → 110101********1234
    var maskedIDCard: String {
        guard count == 18 else { return self }
        return "\(self[0..<6])********\(self[14..<18])"
    }
}

// MARK: ========================================
// MARK: - 5. 时间格式化（秒转字符串）
// MARK: ========================================

/// 秒转字符串的格式
public enum TimeFormat {
    case mmss           // 04:30
    case hhmmss         // 01:04:30
    case hhmmssMs       // 01:04:30.250（含毫秒，直播录制）
    case auto           // 不足1小时用 mm:ss，否则用 hh:mm:ss
    case chinese        // 1小时4分30秒
    case chineseShort   // 1小时4分
}

public extension Int {

    /// 秒数转时间字符串
    func secondsToTime(_ format: TimeFormat = .auto) -> String {
        let h  = self / 3600
        let m  = (self % 3600) / 60
        let s  = self % 60

        switch format {
        case .mmss:
            return String(format: "%02d:%02d", m + h * 60, s)
        case .hhmmss:
            return String(format: "%02d:%02d:%02d", h, m, s)
        case .hhmmssMs:
            return String(format: "%02d:%02d:%02d.000", h, m, s)
        case .auto:
            return h > 0
                ? String(format: "%02d:%02d:%02d", h, m, s)
                : String(format: "%02d:%02d", m, s)
        case .chinese:
            if h > 0 { return "\(h)小时\(m)分\(s)秒" }
            if m > 0 { return "\(m)分\(s)秒" }
            return "\(s)秒"
        case .chineseShort:
            if h > 0 { return "\(h)小时\(m)分" }
            return "\(m)分"
        }
    }
}

public extension Double {

    /// 秒数（含小数，毫秒精度）转时间字符串
    func secondsToTime(_ format: TimeFormat = .auto) -> String {
        let total = Int(self)
        let ms    = Int((self - Double(total)) * 1000)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60

        switch format {
        case .hhmmssMs:
            return String(format: "%02d:%02d:%02d.%03d", h, m, s, ms)
        default:
            return total.secondsToTime(format)
        }
    }
}

// MARK: ========================================
// MARK: - 6. 尺寸计算
// MARK: ========================================

public extension String {

    /// 单行文字宽度
    func width(font: UIFont) -> CGFloat {
        size(font: font, maxWidth: .greatestFiniteMagnitude).width
    }

    /// 限制宽度后的文字高度
    func height(font: UIFont, width: CGFloat) -> CGFloat {
        size(font: font, maxWidth: width).height
    }

    /// 限制最大宽度，计算所需 size
    func size(font: UIFont, maxWidth: CGFloat = .greatestFiniteMagnitude) -> CGSize {
        let constraint = CGSize(width: maxWidth,
                                height: CGFloat.greatestFiniteMagnitude)
        return (self as NSString).boundingRect(
            with: constraint,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).size
    }
}

// MARK: ========================================
// MARK: - 7. 富文本
// MARK: ========================================

public extension String {

    /// 生成 NSAttributedString
    func attributed(
        font: UIFont = .regular(14),
        color: UIColor = .black,
        lineHeight: CGFloat? = nil,
        alignment: NSTextAlignment = .left,
        kern: CGFloat = 0,
        strikethrough: Bool = false,
        underline: Bool = false
    ) -> NSAttributedString {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        if kern != 0 {
            attrs[.kern] = kern
        }
        if strikethrough {
            attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            attrs[.strikethroughColor] = color
        }
        if underline {
            attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
            attrs[.underlineColor] = color
        }
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        if let lh = lineHeight {
            style.minimumLineHeight = lh
            style.maximumLineHeight = lh
            attrs[.baselineOffset] = (lh - font.lineHeight) / 4
        }
        attrs[.paragraphStyle] = style
        return NSAttributedString(string: self, attributes: attrs)
    }

    /// 局部高亮（可多次叠加）
    func highlighted(
        _ targets: String...,
        color: UIColor,
        font: UIFont? = nil
    ) -> NSAttributedString {
        let att = NSMutableAttributedString(string: self)
        for target in targets {
            var searchRange = startIndex..<endIndex
            while let range = self.range(of: target, range: searchRange) {
                let nsRange = NSRange(range, in: self)
                att.addAttribute(.foregroundColor, value: color, range: nsRange)
                if let f = font {
                    att.addAttribute(.font, value: f, range: nsRange)
                }
                searchRange = range.upperBound..<endIndex
            }
        }
        return att
    }

    /// 图文混排：在指定位置插入图片
    /// - Parameters:
    ///   - image: 要插入的图片
    ///   - index: 插入位置，默认末尾
    ///   - imageSize: 图片尺寸，默认跟随字体行高
    ///   - font: 参考字体（用于对齐基线），默认 regular(14)
    func attributedWithImage(
        _ image: UIImage?,
        at index: Int? = nil,
        imageSize: CGSize? = nil,
        font: UIFont = .regular(14),
        baseAttributes: [NSAttributedString.Key: Any] = [:]
    ) -> NSAttributedString {
        let att = NSMutableAttributedString(string: self)

        // 补全基础属性
        let fullRange = NSRange(location: 0, length: att.length)
        var base: [NSAttributedString.Key: Any] = [.font: font]
        base.merge(baseAttributes) { _, new in new }
        att.addAttributes(base, range: fullRange)

        guard let image = image else { return att }

        // 图片附件
        let attachment = NSTextAttachment()
        attachment.image = image
        let size = imageSize ?? CGSize(width: font.lineHeight, height: font.lineHeight)
        // 垂直居中对齐
        let offsetY = (font.capHeight - size.height) / 2
        attachment.bounds = CGRect(origin: CGPoint(x: 0, y: offsetY), size: size)

        let imageAtt = NSAttributedString(attachment: attachment)
        let insertAt = index ?? att.length
        let safeIndex = Swift.min(Swift.max(0, insertAt), att.length)
        att.insert(imageAtt, at: safeIndex)

        return att
    }

    /// 多段富文本拼接（不同颜色/字体的文字组合）
    /// 用法：["直播中" + .red + .bold(14), "  3.2万人观看" + .gray + .regular(12)]
    static func composed(_ parts: [NSAttributedString]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        parts.forEach { result.append($0) }
        return result
    }
}

// MARK: NSAttributedString + 运算符拼接

public extension NSAttributedString {

    /// att1 + att2 拼接
    static func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: lhs)
        result.append(rhs)
        return result
    }
}

// MARK: ========================================
// MARK: - 8. 本地化
// MARK: ========================================

public extension String {

    /// NSLocalizedString 快捷
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// 带格式化参数的本地化
    /// 用法："欢迎%@，获得%@积分".localized(args: "张三", "100")
    func localized(args: CVarArg...) -> String {
        String(format: localized, arguments: args)
    }
}

// MARK: ========================================
// MARK: - 9. 随机串
// MARK: ========================================

public extension String {

    /// 随机串选项
    struct RandomOptions: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let numeric      = RandomOptions(rawValue: 1 << 0)  // 数字
        public static let alpha        = RandomOptions(rawValue: 1 << 1)  // 字母
        public static let alphanumeric: RandomOptions = [.numeric, .alpha]
        public static let symbol       = RandomOptions(rawValue: 1 << 2)  // 特殊符号
    }

    /// 生成随机字符串
    /// - Parameters:
    ///   - length: 长度
    ///   - options: 字符集选项，默认字母+数字
    static func random(length: Int,
                       options: RandomOptions = .alphanumeric) -> String {
        var charset = ""
        if options.contains(.numeric) { charset += "0123456789" }
        if options.contains(.alpha)   { charset += "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" }
        if options.contains(.symbol)  { charset += "!@#$%^&*()-_=+[]{}|;:,.<>?" }
        guard !charset.isEmpty else { return "" }
        let chars = Array(charset)
        return String((0..<length).map { _ in chars[Int.random(in: 0..<chars.count)] })
    }
}

// MARK: ========================================
// MARK: - 10. 版本号比较
// MARK: ========================================

public extension String {

    /// 版本号比较结果
    enum VersionCompareResult {
        case older   // self 比 other 旧
        case equal   // 相同
        case newer   // self 比 other 新
    }

    /// 比较版本号（支持 1.2.3 / 1.2 / 1 格式，自动补位对齐）
    func compareVersion(to other: String) -> VersionCompareResult {
        let lhs = versionComponents
        let rhs = other.versionComponents
        let maxLen = Swift.max(lhs.count, rhs.count)

        for i in 0..<maxLen {
            let l = i < lhs.count ? lhs[i] : 0
            let r = i < rhs.count ? rhs[i] : 0
            if l < r { return .older }
            if l > r { return .newer }
        }
        return .equal
    }

    /// 是否比指定版本旧
    func isOlderThan(_ version: String) -> Bool {
        compareVersion(to: version) == .older
    }

    /// 是否比指定版本新
    func isNewerThan(_ version: String) -> Bool {
        compareVersion(to: version) == .newer
    }

    /// 是否和指定版本相同
    func isSameVersion(as version: String) -> Bool {
        compareVersion(to: version) == .equal
    }

    /// 当前 App 版本号（Info.plist）
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    /// 当前 App Build 号
    static var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    private var versionComponents: [Int] {
        split(separator: ".").compactMap { Int($0) }
    }
}
