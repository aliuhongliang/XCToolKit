import Foundation

// MARK: - HLJSONDecoder

/// 全局 JSON 解码器，统一配置策略
/// 默认策略：snakeCase → camelCase，secondsSince1970 日期
public final class HLJSONDecoder: JSONDecoder {

    public static let shared = HLJSONDecoder()

    private override init() {
        super.init()
        keyDecodingStrategy    = .convertFromSnakeCase
        dateDecodingStrategy   = .secondsSince1970
        nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "+Infinity",
            negativeInfinity: "-Infinity",
            nan: "NaN"
        )
    }
}

// MARK: - HLJSONEncoder

/// 全局 JSON 编码器，统一配置策略
public final class HLJSONEncoder: JSONEncoder {

    public static let shared = HLJSONEncoder()

    private override init() {
        super.init()
        keyEncodingStrategy  = .convertToSnakeCase
        dateEncodingStrategy = .secondsSince1970
    }
}
