//
//  HLAuthPlugin.swift
//  XCToolkit
//
//  Token 注入插件，将 token 写入 Header
//  URL 中的 token 注入已在 HLTargetType 的 task 中处理

import Foundation
import Moya

struct HLAuthPlugin: PluginType {

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let hlTarget = (target as? AnyHLTarget)?.base else { return request }
        guard hlTarget.requiresToken else { return request }
        guard let token = HLNetworkConfig.shared.tokenProvider?(), !token.isEmpty else { return request }

        var request = request
        let config = HLNetworkConfig.shared
        let headerValue = "\(config.tokenHeaderPrefix) \(token)"
        request.setValue(headerValue, forHTTPHeaderField: config.tokenHeaderKey)
        return request
    }
}

// 用于类型擦除，让插件能访问 HLTargetType 属性
protocol AnyHLTargetBox {
    var requiresToken: Bool { get }
}

struct AnyHLTarget: TargetType {
    let base: AnyHLTargetBox & TargetType

    var baseURL: URL { base.baseURL }
    var path: String { base.path }
    var method: Moya.Method { base.method }
    var task: Task { base.task }
    var headers: [String: String]? { base.headers }
    var sampleData: Data { base.sampleData }
}
