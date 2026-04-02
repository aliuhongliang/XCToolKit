// HLRemoteDestination.swift
// XCCore/Logging
//
// 预留远端日志接口，业务层实现此协议后注册到 HLLogger 即可。
// 示例：
//
//   class MyRemoteDestination: HLRemoteDestination {
//       var minimumLevel: HLLogLevel? = .warning
//
//       func send(_ entry: HLLogEntry) {
//           // 上报到 Sentry、Firebase Crashlytics、自建服务等
//           let body = entry.formatted(includeEmoji: false)
//           MyAnalyticsSDK.log(level: entry.level.description, message: body)
//       }
//   }
//
//   // 注册
//   HLLogger.shared.addDestination(MyRemoteDestination(), for: .remote)

import Foundation

public protocol HLRemoteDestination: HLLogDestination {
    /// 上报单条日志，实现方自行处理批量聚合、重试、网络状态判断
    func send(_ entry: HLLogEntry)
}

public extension HLRemoteDestination {
    /// 默认将 write 转发给 send，业务层只需实现 send
    func write(_ entry: HLLogEntry) {
        send(entry)
    }
}
