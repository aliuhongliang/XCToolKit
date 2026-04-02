# HLLogger 使用文档

`HLLogger` 是 `XCCore` 模块下的日志封装库，支持控制台、本地文件、远端三种输出方式，可按需开关，零三方依赖。

---

## 目录

- [文件结构](#文件结构)
- [快速开始](#快速开始)
- [日志级别](#日志级别)
- [输出目标开关](#输出目标开关)
- [写日志](#写日志)
- [Tag 用法](#tag-用法)
- [运行时动态切换](#运行时动态切换)
- [本地文件日志](#本地文件日志)
- [接入远端日志服务](#接入远端日志服务)
- [日志格式说明](#日志格式说明)
- [Release 环境建议](#release-环境建议)

---

## 文件结构

```
XCCore/Logging/
├── HLLogLevel.swift            // 日志级别枚举
├── HLLogEntry.swift            // 日志条目结构体
├── HLLogOutput.swift           // 输出目标开关 (OptionSet) + Destination 协议
├── HLConsoleDestination.swift  // 控制台输出 (os_log)
├── HLFileDestination.swift     // 本地文件输出（按日期滚动）
├── HLRemoteDestination.swift   // 远端输出协议（预留，业务层实现）
└── HLLogger.swift              // 核心单例 + HLLog 全局入口
```

---

## 快速开始

在 `AppDelegate` 或 `App` 入口调用一次 `setup`，之后全局直接使用 `HLLog`。

```swift
// AppDelegate.swift
import XCCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // 开启控制台 + 本地文件，最低级别 debug
        HLLog.setup(outputs: [.console, .file], minimumLevel: .debug)

        return true
    }
}
```

SwiftUI 项目：

```swift
// MyApp.swift
import XCCore

@main
struct MyApp: App {
    init() {
        HLLog.setup(outputs: [.console, .file], minimumLevel: .debug)
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

---

## 日志级别

共四个级别，从低到高：

| 级别 | 方法 | 适用场景 |
|------|------|----------|
| `debug` | `HLLog.debug(...)` | 开发调试，详细流程追踪 |
| `info` | `HLLog.info(...)` | 关键业务节点，正常流程记录 |
| `warning` | `HLLog.warning(...)` | 非致命异常，值得关注但不影响主流程 |
| `error` | `HLLog.error(...)` | 错误、异常，需要排查处理 |

`minimumLevel` 控制最低输出级别，低于该级别的日志直接丢弃：

```swift
// 只输出 warning 及以上（适合 Release）
HLLog.setup(outputs: [.console], minimumLevel: .warning)

// 输出所有级别（适合 Debug）
HLLog.setup(outputs: [.console, .file], minimumLevel: .debug)
```

---

## 输出目标开关

使用 `HLLogOutput`（OptionSet）按需组合输出目标：

```swift
// 仅控制台
HLLog.setup(outputs: [.console])

// 控制台 + 文件
HLLog.setup(outputs: [.console, .file])

// 控制台 + 文件 + 远端
HLLog.setup(outputs: [.console, .file, .remote])

// 全部关闭（静默模式）
HLLogger.shared.isEnabled = false
```

---

## 写日志

所有方法支持**可变参数**，多个参数之间自动用空格拼接，调用位置（文件名、行号、函数名）由编译器自动注入，无需手动传入。

```swift
// 单个参数
HLLog.debug("pipeline started")
HLLog.info("stream connected")
HLLog.warning("buffer near limit")
HLLog.error("connection failed")

// 多个参数，空格拼接
HLLog.debug("user", userId, "logged in")
// 输出: user 12345 logged in

HLLog.info("response code", statusCode, "body", responseBody)
// 输出: response code 200 body {"status":"ok"}

HLLog.warning("retry attempt", retryCount, "of", maxRetry)
// 输出: retry attempt 2 of 3

HLLog.error("upload failed", error.localizedDescription, "size", fileSize)
// 输出: upload failed Network timeout. size 204800
```

---

## Tag 用法

`tag` 参数用于标注日志来源模块，便于过滤和搜索：

```swift
HLLog.debug("pipeline created", tag: "GStreamer")
HLLog.info("gift animation start", tag: "GiftTrack")
HLLog.warning("retry", count, "times", tag: "Network")
HLLog.error("stream crash", error, tag: "GStreamer")
```

输出格式中 tag 会显示在级别后面：

```
2026-04-02 14:23:01.456 🔴 [ERROR] [GStreamer] stream crash Pipeline error  (StreamVC.swift:88 viewDidLoad())
```

---

## 运行时动态切换

`HLLogger.shared` 支持在运行时随时切换输出目标和级别：

```swift
// 切换输出目标
HLLogger.shared.setOutputs([.console])           // 关闭文件写入
HLLogger.shared.setOutputs([.console, .file])    // 重新开启文件
HLLogger.shared.setOutputs([])                   // 全部关闭

// 修改全局最低级别
HLLogger.shared.minimumLevel = .warning

// 总开关
HLLogger.shared.isEnabled = false   // 全部静默
HLLogger.shared.isEnabled = true    // 恢复

// 单独调整某个 destination 的级别
// 例：控制台只看 warning 以上，文件继续记录 debug
HLLogger.shared.consoleDestination.minimumLevel = .warning
HLLogger.shared.fileDestination.minimumLevel = .debug
```

---

## 本地文件日志

### 存储位置

默认存放在：

```
Library/Logs/HLLogs/hllog-yyyy-MM-dd.log
```

每天自动生成新文件，例如：

```
hllog-2026-04-01.log
hllog-2026-04-02.log
```

### 保留策略

默认保留最近 **7 天**，每次日期轮转时自动清理旧文件：

```swift
// 修改保留天数
HLLogger.shared.fileDestination.maxRetainDays = 14
```

### 获取日志文件列表

```swift
let files = HLLogger.shared.fileDestination.allLogFiles()
// 返回 [URL]，按日期升序排列

// 例：上传最新一个日志文件
if let latest = files.last {
    uploadLogFile(at: latest)
}
```

### 自定义存储目录

在 `setup` 之前配置：

```swift
// 使用 Documents 目录（方便通过 iTunes 文件共享导出）
let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let logDir = docsDir.appendingPathComponent("Logs")
let fileDestination = HLLogger.shared.fileDestination
// 注意：如需自定义目录，直接在 HLFileDestination.init 传入
```

---

## 接入远端日志服务

实现 `HLRemoteDestination` 协议，注册到 `HLLogger`，在 `outputs` 中包含 `.remote` 即可生效。

### 示例：接入自建服务

```swift
import XCCore

final class MyRemoteLogger: HLRemoteDestination {
    // 只上报 warning 及以上
    var minimumLevel: HLLogLevel? = .warning

    func send(_ entry: HLLogEntry) {
        let params: [String: Any] = [
            "level":     entry.level.description,
            "message":   entry.message,
            "tag":       entry.tag ?? "",
            "file":      URL(fileURLWithPath: entry.file).lastPathComponent,
            "line":      entry.line,
            "timestamp": entry.timestamp.timeIntervalSince1970
        ]
        // 上报到自建服务、Sentry、Firebase Crashlytics 等
        MyAPIClient.post("/logs", params: params)
    }
}
```

注册并启用：

```swift
// AppDelegate
let remote = MyRemoteLogger()
HLLogger.shared.setRemoteDestination(remote)
HLLog.setup(outputs: [.console, .file, .remote], minimumLevel: .debug)
```

### 示例：只在 error 时触发远端

```swift
final class ErrorOnlyRemote: HLRemoteDestination {
    var minimumLevel: HLLogLevel? = .error

    func send(_ entry: HLLogEntry) {
        Sentry.capture(message: entry.formatted(includeEmoji: false))
    }
}
```

---

## 日志格式说明

每条日志的完整格式：

```
{时间戳} {emoji} [{级别}] [{tag}] {消息内容}  ({文件名}:{行号} {函数名})
```

实际示例：

```
// debug，无 tag
2026-04-02 14:23:01.123 🔍 [DEBUG] pipeline started  (GStreamerManager.swift:42 setupPipeline())

// info，有 tag
2026-04-02 14:23:01.456 ℹ️ [INFO] [Network] user 12345 logged in  (AuthService.swift:88 login())

// warning
2026-04-02 14:23:02.789 ⚠️ [WARN] [Network] retry attempt 2 of 3  (NetworkManager.swift:134 sendRequest())

// error
2026-04-02 14:23:03.001 🔴 [ERROR] [GStreamer] stream crash Pipeline error  (StreamVC.swift:201 handleError())
```

> 写入本地文件时不含 emoji，保持纯文本便于 grep 搜索。

---

## Release 环境建议

```swift
#if DEBUG
HLLog.setup(outputs: [.console, .file], minimumLevel: .debug)
#else
// Release：关闭控制台，只写文件，最低 warning
HLLog.setup(outputs: [.file], minimumLevel: .warning)
// 如有远端服务
// HLLog.setup(outputs: [.file, .remote], minimumLevel: .warning)
#endif
```
