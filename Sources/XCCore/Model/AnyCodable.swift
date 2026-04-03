import Foundation

// MARK: - AnyCodable

/// 处理 [String: Any] 混合类型 JSON 的 Codable 包装
/// 用于动态结构、埋点参数、服务端配置下发等场景
///
///     struct Event: HLModel {
///         let name: String
///         let params: [String: AnyCodable]   // 支持任意值类型
///     }
public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            // Bool 必须在 Int 之前检查，避免 true/false 被解成 1/0
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable 无法解析该类型"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            let ctx = EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "AnyCodable 不支持该类型: \(type(of: value))"
            )
            throw EncodingError.invalidValue(value, ctx)
        }
    }
}

// MARK: ExpressibleBy 协议支持，方便字面量赋值

extension AnyCodable: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) { value = NSNull() }
}
extension AnyCodable: ExpressibleByBooleanLiteral {
    public init(booleanLiteral v: Bool) { value = v }
}
extension AnyCodable: ExpressibleByIntegerLiteral {
    public init(integerLiteral v: Int) { value = v }
}
extension AnyCodable: ExpressibleByFloatLiteral {
    public init(floatLiteral v: Double) { value = v }
}
extension AnyCodable: ExpressibleByStringLiteral {
    public init(stringLiteral v: String) { value = v }
}
extension AnyCodable: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: AnyCodable...) { value = elements.map(\.value) }
}
extension AnyCodable: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, AnyCodable)...) {
        value = Dictionary(elements, uniquingKeysWith: { $1 }).mapValues(\.value)
    }
}
