//
//  HLNetworkConfig.swift
//  XCToolkit
//
//  全局网络配置，在 AppDelegate 或启动时设置一次
//
//  使用示例：
//  let config = HLNetworkConfig.shared
//  config.baseURL = "https://api.example.com"
//  config.timeout = 30
//  config.tokenProvider = { UserDefaults.standard.string(forKey: "token") }
//  config.tokenExpiredCode = 4001
//  config.onTokenExpired = { completion in
//      // 刷新 token 逻辑，完成后回调新 token
//      completion("new_token")
//  }
//  config.onUnauthorized = {
//      // 退出登录
//  }
//  config.onError = { error in
//      HLToast.show(error.localizedDescription)
//  }

import Foundation

public final class HLNetworkConfig {

    public static let shared = HLNetworkConfig()
    private init() {}

    // MARK: - 基础配置

    /// 接口根地址
    public var baseURL: String = ""

    /// 超时时间（秒），默认 30
    public var timeout: TimeInterval = 30

    /// 公共请求头
    public var commonHeaders: [String: String] = [:]

    // MARK: - Token 配置

    /// Token 提供者（闭包动态取，避免时序问题）
    public var tokenProvider: (() -> String?)? = nil

    /// Token 在 URL 中的参数名，默认 "token"
    public var tokenParamKey: String = "token"

    /// Token 在 Header 中的格式，默认 "Bearer {token}"
    public var tokenHeaderKey: String = "Authorization"
    public var tokenHeaderPrefix: String = "Bearer"

    // MARK: - 响应字段配置

    /// 业务状态码字段名，默认 "code"
    public var codeKey: String = "code"

    /// 业务消息字段名，默认 "message"（也可设为 "reason"）
    public var messageKey: String = "message"

    /// 业务数据字段名，默认 "data"
    public var dataKey: String = "data"

    /// 业务成功码，默认 200
    public var successCode: Int = 200

    // MARK: - 鉴权配置

    /// 触发 Token 刷新的业务 code，默认 4001
    public var tokenExpiredCode: Int = 4001

    /// 触发退出登录的 HTTP 状态码，默认 401
    public var unauthorizedCode: Int = 401

    /// Token 刷新回调，业务层实现刷新逻辑，完成后回调新 token（nil 表示刷新失败）
    public var onTokenExpired: ((_ completion: @escaping (_ newToken: String?) -> Void) -> Void)? = nil

    /// 退出登录回调
    public var onUnauthorized: (() -> Void)? = nil

    // MARK: - 错误回调

    /// 全局错误回调，业务层决定是否 Toast 提示
    public var onError: ((HLNetworkError) -> Void)? = nil
}
