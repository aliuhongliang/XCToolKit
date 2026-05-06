//
//  HLNetwork.swift
//  XCToolkit
//
//  网络请求统一入口
//
//  使用示例：
//  // 请求并解析模型
//  HLNetwork.request(UserAPI.userInfo(id: 1), model: UserModel.self) { result in
//      switch result {
//      case .success(let user): print(user)
//      case .failure(let error): print(error)
//      }
//  }
//
//  // 只要原始 Response
//  HLNetwork.request(UserAPI.logout) { result in
//      switch result {
//      case .success(let response): print(response.code)
//      case .failure(let error): print(error)
//      }
//  }

import Foundation
import Moya

public final class HLNetwork {

    private init() {}

    // MARK: - 是否正在刷新 Token
    private static var isRefreshingToken = false
    private static var pendingRequests: [() -> Void] = []

    // MARK: - Request（原始 Response）

    /// 发起请求，返回 HLNetworkResponse
    public static func request<T: HLTargetType>(
        _ target: T,
        completion: @escaping (Result<HLNetworkResponse, HLNetworkError>) -> Void
    ) {
        let provider = makeProvider(for: target)
        let moyaTarget = HLMoyaTarget(target: target)

        provider.request(moyaTarget) { result in
            handleResult(result, target: target, completion: completion)
        }
    }

    // MARK: - Request（泛型模型解析）

    /// 发起请求，自动解析 data 字段为指定模型
    public static func request<T: HLTargetType, M: Decodable>(
        _ target: T,
        model: M.Type,
        completion: @escaping (Result<M, HLNetworkError>) -> Void
    ) {
        request(target) { result in
            switch result {
            case .success(let response):
                do {
                    let model = try response.decode(M.self)
                    completion(.success(model))
                } catch {
                    let err = HLNetworkError.parse(error.localizedDescription)
                    HLNetworkConfig.shared.onError?(err)
                    completion(.failure(err))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// 发起请求，自动解析 data 字段为模型数组
    public static func requestArray<T: HLTargetType, M: Decodable>(
        _ target: T,
        model: M.Type,
        completion: @escaping (Result<[M], HLNetworkError>) -> Void
    ) {
        request(target) { result in
            switch result {
            case .success(let response):
                do {
                    let models = try response.decodeArray(M.self)
                    completion(.success(models))
                } catch {
                    let err = HLNetworkError.parse(error.localizedDescription)
                    HLNetworkConfig.shared.onError?(err)
                    completion(.failure(err))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Private

    private static func makeProvider<T: HLTargetType>(for target: T) -> MoyaProvider<HLMoyaTarget<T>> {
        let config = HLNetworkConfig.shared
        let session = Session(configuration: {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = HLNetworkConfig.shared.timeout
            return config
        }())
        return MoyaProvider<HLMoyaTarget<T>>(
            session: session,
            plugins: [HLAuthPlugin(), HLLogPlugin()]
        )
    }

    private static func handleResult<T: HLTargetType>(
        _ result: Result<Response, MoyaError>,
        target: T,
        completion: @escaping (Result<HLNetworkResponse, HLNetworkError>) -> Void
    ) {
        let config = HLNetworkConfig.shared

        switch result {
        case .failure(let error):
            let err = HLNetworkError.network(error.localizedDescription)
            config.onError?(err)
            completion(.failure(err))

        case .success(let response):
            // HTTP 状态码检查
            if response.statusCode == config.unauthorizedCode {
                config.onUnauthorized?()
                let err = HLNetworkError.http(statusCode: response.statusCode)
                completion(.failure(err))
                return
            }

            guard (200..<300).contains(response.statusCode) else {
                let err = HLNetworkError.http(statusCode: response.statusCode)
                config.onError?(err)
                completion(.failure(err))
                return
            }

            // 解析 JSON
            guard let json = try? JSONSerialization.jsonObject(with: response.data) as? [String: Any],
                  let hlResponse = HLNetworkResponse(json: json) else {
                let err = HLNetworkError.parse("响应格式错误")
                config.onError?(err)
                completion(.failure(err))
                return
            }

            // 业务 code 检查
            if hlResponse.code == config.tokenExpiredCode {
                // Token 过期，刷新后重试
                handleTokenExpired(target: target, completion: completion)
                return
            }

            if !hlResponse.isSuccess {
                let err = HLNetworkError.business(code: hlResponse.code, message: hlResponse.message)
                config.onError?(err)
                completion(.failure(err))
                return
            }

            completion(.success(hlResponse))
        }
    }

    // MARK: - Token 刷新

    private static func handleTokenExpired<T: HLTargetType>(
        target: T,
        completion: @escaping (Result<HLNetworkResponse, HLNetworkError>) -> Void
    ) {
        let config = HLNetworkConfig.shared

        // 把当前请求加入等待队列
        pendingRequests.append {
            self.request(target, completion: completion)
        }

        // 如果已在刷新中，直接等待
        guard !isRefreshingToken else { return }
        isRefreshingToken = true

        guard let refreshHandler = config.onTokenExpired else {
            // 没有配置刷新逻辑，直接退出登录
            isRefreshingToken = false
            pendingRequests.removeAll()
            config.onUnauthorized?()
            return
        }

        refreshHandler { newToken in
            DispatchQueue.main.async {
                self.isRefreshingToken = false
                if newToken != nil {
                    // 刷新成功，重放所有等待的请求
                    let pending = self.pendingRequests
                    self.pendingRequests.removeAll()
                    pending.forEach { $0() }
                } else {
                    // 刷新失败，退出登录
                    self.pendingRequests.removeAll()
                    config.onUnauthorized?()
                }
            }
        }
    }
}
