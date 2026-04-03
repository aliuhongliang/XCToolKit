import Foundation

// MARK: - DefaultValueProvider

/// 为 @Default 提供默认值的协议
public protocol DefaultValueProvider {
    associatedtype Value: Codable
    static var defaultValue: Value { get }
}

// MARK: 常用默认值类型
public enum DefaultNil<T: Codable>: DefaultValueProvider {
    public typealias Value = T?
    public static var defaultValue: T? { nil }
}

public enum DefaultFalse: DefaultValueProvider {
    public static let defaultValue = false
}

public enum DefaultTrue: DefaultValueProvider {
    public static let defaultValue = true
}

public enum DefaultEmptyString: DefaultValueProvider {
    public static let defaultValue = ""
}

public enum DefaultZeroInt: DefaultValueProvider {
    public static let defaultValue = 0
}

public enum DefaultZeroDouble: DefaultValueProvider {
    public static let defaultValue = 0.0
}

public enum DefaultEmptyArray<T: Codable>: DefaultValueProvider {
    public static var defaultValue: [T] { [] }
}

// MARK: - @Default

/// 字段缺失或为 null 时使用指定默认值，不会崩溃
///
///     struct Config: HLModel {
///         @Default<DefaultTrue> var isEnabled: Bool     // 缺失时 = true
///         @Default<DefaultZeroInt> var retryCount: Int  // 缺失时 = 0
///     }
@propertyWrapper
public struct Default<Provider: DefaultValueProvider>: Codable {
    public var wrappedValue: Provider.Value

    public init(wrappedValue: Provider.Value = Provider.defaultValue) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try? decoder.singleValueContainer()
        wrappedValue = (try? container?.decode(Provider.Value.self)) ?? Provider.defaultValue
    }

    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

// MARK: - @LossyArray

/// 数组解码时，某个元素失败则跳过，不会因为单个元素崩溃整个数组
///
///     struct Feed: HLModel {
///         @LossyArray var items: [Item]
///     }
@propertyWrapper
public struct LossyArray<Element: Codable>: Codable {
    public var wrappedValue: [Element]

    public init(wrappedValue: [Element] = []) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements: [Element] = []
        while !container.isAtEnd {
            // 用 SafeElement 包一层，解码失败时跳过
            if let element = try? container.decode(SafeElement<Element>.self) {
                elements.append(element.value)
            } else {
                // 推进游标，避免死循环
                _ = try? container.decode(AnyCodable.self)
            }
        }
        wrappedValue = elements
    }

    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }

    private struct SafeElement<T: Decodable>: Decodable {
        let value: T
        init(from decoder: Decoder) throws {
            value = try T(from: decoder)
        }
    }
}

// MARK: - @LossyString

/// 将 Number / Bool 类型的 JSON 值宽松转为 String
/// 处理后端乱返回类型的场景（如 id 有时是 Int 有时是 String）
///
///     struct User: HLModel {
///         @LossyString var userId: String   // 后端返回 123 或 "123" 都能解析
///     }
@propertyWrapper
public struct LossyString: Codable {
    public var wrappedValue: String?

    public init(wrappedValue: String? = nil) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            wrappedValue = str
        } else if let int = try? container.decode(Int.self) {
            wrappedValue = String(int)
        } else if let double = try? container.decode(Double.self) {
            // 避免 1.0 显示成 "1.0"，整数部分直接截断
            wrappedValue = double.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(double))
                : String(double)
        } else if let bool = try? container.decode(Bool.self) {
            wrappedValue = bool ? "true" : "false"
        } else {
            wrappedValue = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

// MARK: - @LossyBool

/// 将 Int (0/1) / String ("true"/"false"/"1"/"0") 宽松转为 Bool
///
///     struct Setting: HLModel {
///         @LossyBool var isActive: Bool   // 后端返回 1 / "true" / true 均可
///     }
@propertyWrapper
public struct LossyBool: Codable {
    public var wrappedValue: Bool?

    public init(wrappedValue: Bool? = nil) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            wrappedValue = bool
        } else if let int = try? container.decode(Int.self) {
            wrappedValue = int != 0
        } else if let str = try? container.decode(String.self) {
            wrappedValue = ["true", "1", "yes"].contains(str.lowercased())
        } else {
            wrappedValue = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

@propertyWrapper
public struct Flexible<T: Codable & DefaultValueProvider>: Codable where T.Value == T {
    public var wrappedValue: T

    public init(wrappedValue: T = T.defaultValue) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try? decoder.singleValueContainer()
        
        // 1. 尝试正常解析
        if let value = try? container?.decode(T.self) {
            wrappedValue = value
            return
        }

        // 2. 类型对不上时的“强转”逻辑
        if let str = try? container?.decode(String.self) {
            // 如果预期是 Int/Double，但后端给了 String "123"
            if T.self == Int.self, let v = Int(str) as? T { wrappedValue = v; return }
            if T.self == Double.self, let v = Double(str) as? T { wrappedValue = v; return }
            if T.self == Bool.self {
                let lower = str.lowercased()
                if ["true", "1", "yes"].contains(lower) { wrappedValue = true as! T; return }
                if ["false", "0", "no"].contains(lower) { wrappedValue = false as! T; return }
            }
        } else if let num = try? container?.decode(Double.self) {
            // 如果预期是 String，但后端给了数字 123
            if T.self == String.self {
                wrappedValue = (num.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(num)) : String(num)) as! T
                return
            }
            // 如果预期是 Bool，但后端给了数字 1
            if T.self == Bool.self {
                wrappedValue = (num != 0) as! T
                return
            }
        }
        
        // 3. 实在解析不了，给默认值
        wrappedValue = T.defaultValue
    }

    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

// MARK: - @ISO8601Date

/// 将 ISO8601 格式字符串自动解码为 Date
/// 支持：2024-01-15T10:30:00Z / 2024-01-15T10:30:00+08:00
///
///     struct Event: HLModel {
///         @ISO8601Date var createdAt: Date
///     }
@propertyWrapper
public struct ISO8601Date: Codable {
    public var wrappedValue: Date?

    private static let formatters: [ISO8601DateFormatter] = {
        let withFractional = ISO8601DateFormatter()
        withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let standard = ISO8601DateFormatter()
        standard.formatOptions = [.withInternetDateTime]
        return [withFractional, standard]
    }()

    public init(wrappedValue: Date? = nil) {
        self.wrappedValue = wrappedValue
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = nil
            return
        }
        let str = try container.decode(String.self)
        wrappedValue = Self.formatters.lazy.compactMap { $0.date(from: str) }.first
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let date = wrappedValue {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            try container.encode(formatter.string(from: date))
        } else {
            try container.encodeNil()
        }
    }
}

// MARK: - KeyedDecodingContainer helpers
// 让 @Default 在字段为 null 时也使用默认值（而不仅是字段缺失）

public extension KeyedDecodingContainer {
    func decode<P: DefaultValueProvider>(
        _ type: Default<P>.Type,
        forKey key: Key
    ) throws -> Default<P> {
        (try? decodeIfPresent(type, forKey: key)) ?? Default()
    }

    func decode<T: Codable>(
        _ type: LossyArray<T>.Type,
        forKey key: Key
    ) throws -> LossyArray<T> {
        (try? decodeIfPresent(type, forKey: key)) ?? LossyArray()
    }

    func decode(_ type: LossyString.Type, forKey key: Key) throws -> LossyString {
        (try? decodeIfPresent(type, forKey: key)) ?? LossyString()
    }

    func decode(_ type: LossyBool.Type, forKey key: Key) throws -> LossyBool {
        (try? decodeIfPresent(type, forKey: key)) ?? LossyBool()
    }

    func decode(_ type: ISO8601Date.Type, forKey key: Key) throws -> ISO8601Date {
        (try? decodeIfPresent(type, forKey: key)) ?? ISO8601Date()
    }
    
    func decode<T>(_ type: Flexible<T>.Type, forKey key: Key) throws -> Flexible<T> {
        (try? decodeIfPresent(type, forKey: key)) ?? Flexible()
    }
}

extension String: DefaultValueProvider { public static var defaultValue: String { "" } }
extension Int: DefaultValueProvider { public static var defaultValue: Int { 0 } }
extension Double: DefaultValueProvider { public static var defaultValue: Double { 0.0 } }
extension Bool: DefaultValueProvider { public static var defaultValue: Bool { false } }
