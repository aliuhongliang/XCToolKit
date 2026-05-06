//
//  HLNetworkResponse.swift
//  XCToolkit
//
//  统一响应模型，对应服务端 { code, message, data } 结构

import Foundation

public struct HLNetworkResponse {

    /// 业务状态码
    public let code: Int

    /// 业务消息
    public let message: String

    /// 原始 data 字段（JSON 对象或数组）
    public let data: Any?

    /// 原始响应 JSON
    public let rawJSON: [String: Any]

    // MARK: - Init

    init?(json: [String: Any]) {
        let config = HLNetworkConfig.shared

        guard let code = json[config.codeKey] as? Int else { return nil }

        self.code = code
        self.message = (json[config.messageKey] as? String) ?? ""
        self.data = json[config.dataKey]
        self.rawJSON = json
    }

    // MARK: - Helpers

    /// 是否业务成功
    public var isSuccess: Bool {
        return code == HLNetworkConfig.shared.successCode
    }

    /// data 解析为指定 Decodable 模型
    public func decode<T: Decodable>(_ type: T.Type) throws -> T {
        guard let data = data else {
            throw HLNetworkError.parse("data 字段为空")
        }
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode(type, from: jsonData)
    }

    /// data 解析为数组模型
    public func decodeArray<T: Decodable>(_ type: T.Type) throws -> [T] {
        guard let data = data else {
            throw HLNetworkError.parse("data 字段为空")
        }
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        return try JSONDecoder().decode([T].self, from: jsonData)
    }
}
