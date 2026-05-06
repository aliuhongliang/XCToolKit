//
//  HLTargetType.swift
//  XCToolkit
//
//  业务侧继承此协议定义接口，无需关心底层 Moya 细节
//
//  使用示例：
//  enum UserAPI {
//      case login(phone: String, password: String)
//      case userInfo(id: Int)
//  }
//  extension UserAPI: HLTargetType {
//      var path: String {
//          switch self {
//          case .login: return "/user/login"
//          case .userInfo: return "/user/info"
//          }
//      }
//      var method: HLMethod {
//          switch self {
//          case .login: return .post
//          case .userInfo: return .get
//          }
//      }
//      var parameters: [String: Any]? {
//          switch self {
//          case .login(let phone, let password):
//              return ["phone": phone, "password": password]
//          case .userInfo(let id):
//              return ["id": id]
//          }
//      }
//  }

import Foundation
import Moya

/// HTTP 方法
public enum HLMethod {
    case get
    case post
    case put
    case delete
    case patch

    var moyaMethod: Moya.Method {
        switch self {
        case .get:    return .get
        case .post:   return .post
        case .put:    return .put
        case .delete: return .delete
        case .patch:  return .patch
        }
    }
}

/// 业务接口协议
public protocol HLTargetType {
    /// 接口路径（相对于 baseURL）
    var path: String { get }

    /// 请求方法
    var method: HLMethod { get }

    /// 请求参数（GET 拼 URL，POST 放 Body）
    var parameters: [String: Any]? { get }

    /// 是否需要 Token（默认 true）
    var requiresToken: Bool { get }

    /// 自定义 baseURL（可选，不设置则使用 HLNetworkConfig.shared.baseURL）
    var customBaseURL: String? { get }

    /// 自定义请求头（可选，会与公共 header 合并）
    var customHeaders: [String: String]? { get }
}

/// 默认实现
public extension HLTargetType {
    var requiresToken: Bool { return true }
    var customBaseURL: String? { return nil }
    var customHeaders: [String: String]? { return nil }
}

// MARK: - Moya TargetType 适配

struct HLMoyaTarget<T: HLTargetType>: TargetType {

    let target: T
    private let config = HLNetworkConfig.shared

    var baseURL: URL {
        let urlString = target.customBaseURL ?? config.baseURL
        return URL(string: urlString) ?? URL(string: "https://")!
    }

    var path: String { target.path }

    var method: Moya.Method { target.method.moyaMethod }

    var task: Task {
        let params = target.parameters ?? [:]

        // Token 注入到 URL 参数
        var urlParams: [String: Any] = [:]
        if target.requiresToken, let token = config.tokenProvider?() {
            urlParams[config.tokenParamKey] = token
        }

        switch target.method {
        case .get, .delete:
            // GET/DELETE：业务参数 + token 都拼到 URL
            urlParams.merge(params) { _, new in new }
            return urlParams.isEmpty ? .requestPlain : .requestParameters(parameters: urlParams, encoding: URLEncoding.queryString)

        case .post, .put, .patch:
            // POST/PUT/PATCH：业务参数放 Body，token 拼 URL
            if urlParams.isEmpty {
                return params.isEmpty ? .requestPlain : .requestParameters(parameters: params, encoding: JSONEncoding.default)
            } else {
                return .requestCompositeParameters(
                    bodyParameters: params,
                    bodyEncoding: JSONEncoding.default,
                    urlParameters: urlParams
                )
            }
        }
    }

    var headers: [String: String]? {
        var result = config.commonHeaders
        // 公共 header 合并自定义 header
        if let custom = target.customHeaders {
            result.merge(custom) { _, new in new }
        }
        return result
    }

    var sampleData: Data { Data() }
}
