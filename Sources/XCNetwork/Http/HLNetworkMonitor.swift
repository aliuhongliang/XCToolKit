//
//  HLNetworkMonitor.swift
//  XCToolkit
//
//  网络状态监测，基于 Network framework（iOS 12+）
//
//  使用示例：
//  HLNetworkMonitor.shared.startMonitoring()
//  HLNetworkMonitor.shared.onChange = { status in
//      print(status)
//  }
//  print(HLNetworkMonitor.shared.isReachable)
//  print(HLNetworkMonitor.shared.status)

import Foundation
import Network

public final class HLNetworkMonitor {

    public static let shared = HLNetworkMonitor()
    private init() {}

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.xctoolkit.network.monitor")

    // MARK: - Public

    /// 当前网络状态
    public private(set) var status: HLNetworkStatus = .unknown

    /// 是否有网络
    public var isReachable: Bool { status != .none && status != .unknown }

    /// 网络状态变化回调（主线程回调）
    public var onChange: ((HLNetworkStatus) -> Void)?

    /// 开始监测
    public func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let newStatus = HLNetworkStatus(path: path)
            guard newStatus != self.status else { return }
            self.status = newStatus
            DispatchQueue.main.async {
                self.onChange?(newStatus)
            }
        }
        monitor.start(queue: queue)
    }

    /// 停止监测
    public func stopMonitoring() {
        monitor.cancel()
    }
}

// MARK: - HLNetworkStatus

public enum HLNetworkStatus: Equatable {
    /// WiFi
    case wifi
    /// 蜂窝网络
    case cellular
    /// 以太网
    case ethernet
    /// 无网络
    case none
    /// 未知（未开始监测）
    case unknown

    init(path: NWPath) {
        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) {
                self = .wifi
            } else if path.usesInterfaceType(.cellular) {
                self = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                self = .ethernet
            } else {
                self = .none
            }
        } else {
            self = .none
        }
    }

    public var description: String {
        switch self {
        case .wifi:     return "WiFi"
        case .cellular: return "蜂窝网络"
        case .ethernet: return "以太网"
        case .none:     return "无网络"
        case .unknown:  return "未知"
        }
    }
}
