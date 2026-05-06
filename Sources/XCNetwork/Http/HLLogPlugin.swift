//
//  HLLogPlugin.swift
//  XCToolkit
//
//  请求/响应日志插件，仅 Debug 环境输出

import Foundation
import Moya

struct HLLogPlugin: PluginType {

    func willSend(_ request: RequestType, target: TargetType) {
        #if DEBUG
        let urlString = request.request?.url?.absoluteString ?? "Unknown URL"
        let method = request.request?.httpMethod ?? "Unknown Method"
        var log = "\n========== 📤 REQUEST ==========\n"
        log += "[\(method)] \(urlString)\n"

        if let headers = request.request?.allHTTPHeaderFields, !headers.isEmpty {
            log += "Headers: \(headers)\n"
        }
        if let body = request.request?.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            log += "Body: \(bodyString)\n"
        }
        log += "================================="
        print(log)
        #endif
    }

    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        #if DEBUG
        var log = "\n========== 📥 RESPONSE ==========\n"
        switch result {
        case .success(let response):
            log += "Status: \(response.statusCode)\n"
            if let json = try? JSONSerialization.jsonObject(with: response.data),
               let pretty = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let prettyString = String(data: pretty, encoding: .utf8) {
                log += "Body:\n\(prettyString)\n"
            } else {
                log += "Body: \(String(data: response.data, encoding: .utf8) ?? "nil")\n"
            }
        case .failure(let error):
            log += "Error: \(error.localizedDescription)\n"
        }
        log += "=================================="
        print(log)
        #endif
    }
}
