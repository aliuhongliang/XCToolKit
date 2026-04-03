import Foundation

// MARK: - String + HLRegex

public extension String {

    // MARK: 便捷验证（返回 ValidationResult，含 reason）

    /// 验证是否符合内置规则
    ///
    ///     let result = "13800138000".hl.validate(.phoneCN)
    ///     if case .invalid(let reason) = result { showError(reason) }
    func hlValidate(_ rule: HLRegexRule) -> ValidationResult {
        HLRegex.shared.validate(self, rule: rule)
    }

    /// 验证是否符合自定义注册规则
    func hlValidate(ruleKey: String) -> ValidationResult {
        HLRegex.shared.validate(self, ruleKey: ruleKey)
    }

    /// 是否匹配内置规则（简洁 Bool，适合无需展示错误原因的场景）
    func hlIsValid(_ rule: HLRegexRule) -> Bool {
        hlValidate(rule).isValid
    }

    // MARK: 匹配 / 提取

    /// 返回第一个匹配的子字符串
    func hlFirstMatch(pattern: String) -> String? {
        HLRegex.shared.firstMatch(in: self, pattern: pattern)
    }

    /// 返回所有匹配的子字符串列表
    func hlAllMatches(pattern: String) -> [String] {
        HLRegex.shared.allMatches(in: self, pattern: pattern)
    }

    /// 返回所有捕获组（每个元素是一次匹配的全部 group）
    func hlGroups(pattern: String) -> [[String]] {
        HLRegex.shared.groups(in: self, pattern: pattern)
    }

    /// 替换所有匹配内容
    func hlReplacing(pattern: String, with template: String) -> String {
        HLRegex.shared.replacing(in: self, pattern: pattern, with: template)
    }

    // MARK: 语义化快捷属性（最高频场景）

    var isValidPhoneCN:     Bool { hlIsValid(.phoneCN) }
    var isValidPhoneTW:     Bool { hlIsValid(.phoneTW) }
    var isValidEmail:       Bool { hlIsValid(.email) }
    var isValidIDCard:      Bool { hlValidate(.idCardCN).isValid }
    var isValidUsername:    Bool { hlIsValid(.username) }
    var isValidURL:         Bool { hlIsValid(.urlHTTP) }
    var isValidIPv4:        Bool { hlIsValid(.ipv4) }
    var isValidIPv6:        Bool { hlIsValid(.ipv6) }
    var isInteger:          Bool { hlIsValid(.integer) }
    var isNumeric:          Bool { hlIsValid(.numeric) }
    var isValidBankCard:    Bool { hlValidate(.bankCard).isValid }
    var isValidLicensePlate:Bool { hlIsValid(.licensePlateCN) }
    var isChinese:          Bool { hlIsValid(.chinese) }

    /// 密码强度等级
    var passwordStrength: PasswordStrength {
        if hlIsValid(.passwordStrong)  { return .strong }
        if hlIsValid(.passwordMedium)  { return .medium }
        if hlIsValid(.passwordWeak)    { return .weak }
        return .tooWeak
    }
}

// MARK: - PasswordStrength

public enum PasswordStrength {
    case tooWeak    // 不满足最低要求
    case weak       // 纯字母或纯数字，≥6位
    case medium     // 字母+数字，8-20位
    case strong     // 字母+数字+特殊字符，8-20位

    public var description: String {
        switch self {
        case .tooWeak: return "密码太弱"
        case .weak:    return "弱"
        case .medium:  return "中"
        case .strong:  return "强"
        }
    }

    public var score: Int {
        switch self {
        case .tooWeak: return 0
        case .weak:    return 1
        case .medium:  return 2
        case .strong:  return 3
        }
    }
}
