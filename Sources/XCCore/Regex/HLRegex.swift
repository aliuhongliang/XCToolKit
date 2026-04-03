import Foundation

// MARK: - ValidationResult

/// 验证结果，携带失败原因，方便直接用于 UI 提示
public enum ValidationResult: Equatable {
    case valid
    case invalid(reason: String)

    public var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    public var reason: String? {
        if case .invalid(let r) = self { return r }
        return nil
    }
}

// MARK: - HLRegexRule

/// 正则规则定义
public struct HLRegexRule {
    public let pattern: String
    public let failureReason: String

    public init(pattern: String, failureReason: String) {
        self.pattern = pattern
        self.failureReason = failureReason
    }
}

// MARK: - Built-in Rules

public extension HLRegexRule {

    // MARK: 联系方式

    /// 中国大陆手机号（1开头，11位）
    static let phoneCN = HLRegexRule(
        pattern: #"^1[3-9]\d{9}$"#,
        failureReason: "请输入有效的手机号码"
    )

    /// 台湾手机号（09开头，10位）
    static let phoneTW = HLRegexRule(
        pattern: #"^09\d{8}$"#,
        failureReason: "請輸入有效的手機號碼"
    )

    /// 通用手机号（宽松：7-15位数字，可含 + 前缀）
    static let phoneGeneral = HLRegexRule(
        pattern: #"^\+?[1-9]\d{6,14}$"#,
        failureReason: "请输入有效的电话号码"
    )

    /// 邮箱（RFC 5322 简化版，覆盖 99% 场景）
    static let email = HLRegexRule(
        pattern: #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#,
        failureReason: "请输入有效的邮箱地址"
    )

    // MARK: 身份证件

    /// 中国大陆居民身份证（18位格式校验，校验码单独计算）
    static let idCardCN = HLRegexRule(
        pattern: #"^\d{17}[\dXx]$"#,
        failureReason: "请输入有效的身份证号码"
    )

    // MARK: 账号

    /// 用户名（字母/数字/下划线，4-16位，不能以下划线开头结尾）
    static let username = HLRegexRule(
        pattern: #"^(?!_)[A-Za-z0-9_]{4,16}(?<!_)$"#,
        failureReason: "用户名为 4-16 位字母、数字或下划线，不能以下划线开头或结尾"
    )

    // MARK: 密码（分级）

    /// 弱密码：至少 6 位，仅字母或仅数字
    static let passwordWeak = HLRegexRule(
        pattern: #"^[A-Za-z0-9]{6,}$"#,
        failureReason: "密码至少 6 位"
    )

    /// 中等密码：8-20位，同时包含字母和数字
    static let passwordMedium = HLRegexRule(
        pattern: #"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,20}$"#,
        failureReason: "密码需 8-20 位，包含字母和数字"
    )

    /// 强密码：8-20位，字母+数字+特殊字符
    static let passwordStrong = HLRegexRule(
        pattern: #"^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z\d])[^\s]{8,20}$"#,
        failureReason: "密码需 8-20 位，包含字母、数字和特殊字符"
    )

    // MARK: 数字

    /// 纯整数（不含小数点，可带负号）
    static let integer = HLRegexRule(
        pattern: #"^-?\d+$"#,
        failureReason: "请输入整数"
    )

    /// 正整数（不含零和负数）
    static let positiveInteger = HLRegexRule(
        pattern: #"^[1-9]\d*$"#,
        failureReason: "请输入正整数"
    )

    /// 数字（含可选小数点和负号）
    static let numeric = HLRegexRule(
        pattern: #"^-?\d+(\.\d+)?$"#,
        failureReason: "请输入有效数字"
    )

    // MARK: 网络

    /// HTTP/HTTPS URL
    static let urlHTTP = HLRegexRule(
        pattern: #"^https?://[^\s/$.?#].[^\s]*$"#,
        failureReason: "请输入有效的 URL"
    )

    /// IPv4 地址
    static let ipv4 = HLRegexRule(
        pattern: #"^((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)$"#,
        failureReason: "请输入有效的 IPv4 地址"
    )

    /// IPv6 地址（宽松匹配）
    static let ipv6 = HLRegexRule(
        pattern: #"^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^::([0-9a-fA-F]{1,4}:){0,6}[0-9a-fA-F]{1,4}$|^([0-9a-fA-F]{1,4}:){1,7}:$"#,
        failureReason: "请输入有效的 IPv6 地址"
    )

    // MARK: 车辆

    /// 中国大陆车牌号（含新能源）
    static let licensePlateCN = HLRegexRule(
        pattern: #"^[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤川青藏琼宁夏][A-HJ-NP-Z][A-HJ-NP-Z0-9]{4,5}[A-HJ-NP-Z0-9挂学警港澳]$"#,
        failureReason: "请输入有效的车牌号"
    )

    // MARK: 文本

    /// 纯中文字符（CJK 统一汉字范围）
    static let chinese = HLRegexRule(
        pattern: #"^[\u4E00-\u9FFF\u3400-\u4DBF]+$"#,
        failureReason: "只能包含中文字符"
    )

    /// 银行卡号（16-19位，Luhn 算法校验在 HLRegex.validate 中单独处理）
    static let bankCard = HLRegexRule(
        pattern: #"^\d{16,19}$"#,
        failureReason: "请输入有效的银行卡号"
    )
}

// MARK: - HLRegex Engine

/// 正则验证引擎，支持内置规则 + 自定义注册
public final class HLRegex {

    public static let shared = HLRegex()
    private init() {}

    // MARK: 规则注册表（自定义规则）

    private var customRules: [String: HLRegexRule] = [:]
    private let lock = NSLock()

    /// 注册自定义规则
    /// - Parameters:
    ///   - rule: 规则定义
    ///   - key: 规则唯一标识
    public func register(rule: HLRegexRule, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        customRules[key] = rule
    }

    /// 通过 key 取自定义规则
    public func rule(forKey key: String) -> HLRegexRule? {
        lock.lock()
        defer { lock.unlock() }
        return customRules[key]
    }

    // MARK: 正则缓存（避免重复编译）

    private var regexCache: [String: NSRegularExpression] = [:]
    private let cacheLock = NSLock()

    private func regex(for pattern: String) -> NSRegularExpression? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let cached = regexCache[pattern] { return cached }
        let compiled = try? NSRegularExpression(pattern: pattern, options: [])
        if let compiled { regexCache[pattern] = compiled }
        return compiled
    }

    // MARK: 核心验证

    /// 用内置规则验证字符串
    public func validate(_ string: String, rule: HLRegexRule) -> ValidationResult {
        // 银行卡号额外做 Luhn 校验
        if rule.pattern == HLRegexRule.bankCard.pattern {
            return validateBankCard(string)
        }
        // 身份证额外做校验位验证
        if rule.pattern == HLRegexRule.idCardCN.pattern {
            return validateIDCard(string)
        }
        return matchesPattern(string, rule: rule)
    }

    /// 用自定义 key 验证字符串
    public func validate(_ string: String, ruleKey: String) -> ValidationResult {
        guard let rule = rule(forKey: ruleKey) else {
            return .invalid(reason: "未找到规则: \(ruleKey)")
        }
        return validate(string, rule: rule)
    }

    /// 在字符串中查找第一个匹配
    public func firstMatch(in string: String, pattern: String) -> String? {
        guard
            let re = regex(for: pattern),
            let match = re.firstMatch(in: string, range: NSRange(string.startIndex..., in: string)),
            let range = Range(match.range, in: string)
        else { return nil }
        return String(string[range])
    }

    /// 查找所有匹配
    public func allMatches(in string: String, pattern: String) -> [String] {
        guard let re = regex(for: pattern) else { return [] }
        let nsString = string as NSString
        return re.matches(in: string, range: NSRange(location: 0, length: nsString.length))
            .compactMap { match -> String? in
                guard let range = Range(match.range, in: string) else { return nil }
                return String(string[range])
            }
    }

    /// 提取捕获组
    public func groups(in string: String, pattern: String) -> [[String]] {
        guard let re = regex(for: pattern) else { return [] }
        let nsString = string as NSString
        return re.matches(in: string, range: NSRange(location: 0, length: nsString.length))
            .map { match in
                (0..<match.numberOfRanges).compactMap { i -> String? in
                    guard let range = Range(match.range(at: i), in: string) else { return nil }
                    return String(string[range])
                }
            }
    }

    /// 替换匹配内容
    public func replacing(in string: String, pattern: String, with template: String) -> String {
        guard let re = regex(for: pattern) else { return string }
        return re.stringByReplacingMatches(
            in: string,
            range: NSRange(string.startIndex..., in: string),
            withTemplate: template
        )
    }

    // MARK: Private Helpers

    private func matchesPattern(_ string: String, rule: HLRegexRule) -> ValidationResult {
        guard let re = regex(for: rule.pattern) else {
            return .invalid(reason: "正则表达式无效: \(rule.pattern)")
        }
        let range = NSRange(string.startIndex..., in: string)
        let matched = re.firstMatch(in: string, range: range) != nil
        return matched ? .valid : .invalid(reason: rule.failureReason)
    }

    // MARK: 身份证校验位算法

    private func validateIDCard(_ id: String) -> ValidationResult {
        let id = id.uppercased()
        // 先验证格式
        let formatResult = matchesPattern(id, rule: .idCardCN)
        guard formatResult.isValid else { return formatResult }

        let coefficients = [7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2]
        let checkCodes = ["1", "0", "X", "9", "8", "7", "6", "5", "4", "3", "2"]
        let digits = Array(id.prefix(17))
        let sum = zip(digits, coefficients).reduce(0) { result, pair in
            result + (Int(String(pair.0)) ?? 0) * pair.1
        }
        let expectedCheck = checkCodes[sum % 11]
        let actualCheck = String(id.suffix(1))
        return expectedCheck == actualCheck
            ? .valid
            : .invalid(reason: "身份证校验码不正确")
    }

    // MARK: 银行卡 Luhn 算法

    private func validateBankCard(_ card: String) -> ValidationResult {
        let formatResult = matchesPattern(card, rule: .bankCard)
        guard formatResult.isValid else { return formatResult }

        var sum = 0
        let reversed = card.reversed().enumerated()
        for (index, char) in reversed {
            guard var digit = char.wholeNumberValue else {
                return .invalid(reason: HLRegexRule.bankCard.failureReason)
            }
            if index % 2 == 1 {
                digit *= 2
                if digit > 9 { digit -= 9 }
            }
            sum += digit
        }
        return sum % 10 == 0
            ? .valid
            : .invalid(reason: "银行卡号校验失败")
    }
}
