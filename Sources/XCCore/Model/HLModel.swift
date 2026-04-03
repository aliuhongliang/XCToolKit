import Foundation

// MARK: - HLModel Protocol

/// 基于 Codable 的扩展协议，提供 JSON/Dict/Data 互转能力
/// 使用方式：让 Model 遵守 HLModel 即可，无需额外实现
///
///     struct User: HLModel {
///         let id: Int
///         let name: String
///     }
public typealias HLModel = Codable & HLModelDecodable & HLModelEncodable

// MARK: - Decodable Extensions

public protocol HLModelDecodable: Decodable {}

public extension HLModelDecodable {

    // MARK: JSON String → Model

    /// 从 JSON 字符串解码，失败时抛出错误
    /// - Parameter jsonString: UTF-8 JSON 字符串
    static func decode(from jsonString: String) throws -> Self {
        guard let data = jsonString.data(using: .utf8) else {
            throw HLModelError.invalidJSON("字符串无法转为 UTF-8 Data")
        }
        return try HLJSONDecoder.shared.decode(Self.self, from: data)
    }

    /// 从 JSON 字符串解码，失败时返回 nil
    static func decoded(from jsonString: String) -> Self? {
        try? decode(from: jsonString)
    }

    // MARK: Dictionary → Model

    /// 从 [String: Any] 字典解码，失败时抛出错误
    static func decode(from dict: [String: Any]) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: dict)
        return try HLJSONDecoder.shared.decode(Self.self, from: data)
    }

    /// 从 [String: Any] 字典解码，失败时返回 nil
    static func decoded(from dict: [String: Any]) -> Self? {
        try? decode(from: dict)
    }

    // MARK: Data → Model

    /// 从 Data 解码，失败时抛出错误
    static func decode(from data: Data) throws -> Self {
        try HLJSONDecoder.shared.decode(Self.self, from: data)
    }

    /// 从 Data 解码，失败时返回 nil
    static func decoded(from data: Data) -> Self? {
        try? decode(from: data)
    }

    // MARK: Array

    /// 从 JSON 数组字符串解码为 [Self]，失败时抛出错误
    static func decodeArray(from jsonString: String) throws -> [Self] {
        guard let data = jsonString.data(using: .utf8) else {
            throw HLModelError.invalidJSON("字符串无法转为 UTF-8 Data")
        }
        return try HLJSONDecoder.shared.decode([Self].self, from: data)
    }

    /// 从 JSON 数组字符串解码，逐元素容错（某个元素失败时跳过）
    static func safeDecodeArray(from jsonString: String) -> [Self] {
        guard
            let data = jsonString.data(using: .utf8),
            let rawArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        else { return [] }

        return rawArray.compactMap { decoded(from: $0) }
    }
}

// MARK: - Encodable Extensions

public protocol HLModelEncodable: Encodable {}

public extension HLModelEncodable {

    // MARK: Model → JSON String

    /// 编码为紧凑 JSON 字符串
    func toJSONString() -> String? {
        toJSONString(prettyPrinted: false)
    }

    /// 编码为 JSON 字符串
    /// - Parameter prettyPrinted: 是否美化缩进
    func toJSONString(prettyPrinted: Bool) -> String? {
        let encoder = HLJSONEncoder.shared
        if prettyPrinted {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        } else {
            encoder.outputFormatting = []
        }
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: Model → Dictionary

    /// 编码为 [String: Any] 字典
    func toDictionary() -> [String: Any]? {
        guard
            let data = try? HLJSONEncoder.shared.encode(self),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return dict
    }

    // MARK: Model → Data

    /// 编码为 JSON Data
    func toData() -> Data? {
        try? HLJSONEncoder.shared.encode(self)
    }
}

// MARK: - HLModelError

public enum HLModelError: LocalizedError {
    case invalidJSON(String)
    case decodingFailed(String)
    case encodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidJSON(let msg):       return "无效 JSON: \(msg)"
        case .decodingFailed(let msg):    return "解码失败: \(msg)"
        case .encodingFailed(let msg):    return "编码失败: \(msg)"
        }
    }
}
