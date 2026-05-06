//
//  HLNetworkError.swift
//  XCToolkit
//
//  网络错误分层枚举

import Foundation

public enum HLNetworkError: Error {

    /// 网络层错误（无网络、超时、请求失败）
    case network(String)

    /// HTTP 错误（4xx、5xx）
    case http(statusCode: Int)

    /// 业务错误（服务端返回的 code 异常）
    case business(code: Int, message: String)

    /// 数据解析错误
    case parse(String)
}

extension HLNetworkError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .network(let msg):
            return msg
        case .http(let code):
            return "请求失败（\(code)）"
        case .business(_, let msg):
            return msg
        case .parse(let msg):
            return "数据解析失败：\(msg)"
        }
    }
}
