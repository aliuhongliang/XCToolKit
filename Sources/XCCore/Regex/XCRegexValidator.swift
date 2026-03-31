import Foundation

public enum RegexValidator {
    public static func isMatch(_ text: String, pattern: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }

    public static func isPhoneNumber(_ text: String) -> Bool {
        isMatch(text, pattern: "^1[3-9]\\d{9}$")
    }

    public static func isEmail(_ text: String) -> Bool {
        isMatch(text, pattern: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
    }

    public static func isIDCard(_ text: String) -> Bool {
        isMatch(text, pattern: "^(\\d{15}|\\d{17}[0-9Xx])$")
    }

    public static func isDigitsOnly(_ text: String) -> Bool {
        isMatch(text, pattern: "^\\d+$")
    }
}
