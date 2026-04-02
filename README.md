# XCToolkit

一个面向 iOS 13+ 的模块化 Swift 工具库，目标是把「基础能力、业务架构、UI 组件、网络通信」拆分为可组合的能力层。

## Why This Structure

这个项目采用分层架构，不按“文件类型”划分，而按“能力边界”划分，核心原则是：

- `XCCore` 作为底层基础能力，不依赖 UIKit 和业务层。
- `XCExtensions` 承载系统类增强，统一入口、统一命名、减少冲突。
- `XCArchitecture` 提供应用级骨架能力（基类、权限、主题、路由/响应链等）。
- `XCComponents` 负责可复用 UI 交互组件，与业务解耦。
- `XCNetwork` / `XCCrypto` 将三方依赖隔离在边界层，避免污染核心代码。
- `Main` 作为聚合入口，按需导出模块，提升接入体验。

这种划分的好处是：**依赖关系清晰、可单独演进、可按模块引入、便于测试和维护**。

## Module Layers

### 1) 基础层 `XCCore` (Core Foundation)

不依赖业务，不依赖重型三方库，提供全局可复用的底层能力。

- `Binary`: Hex/Byte/Data 转换（蓝牙、设备通信、协议报文）。
- `Log`: 日志系统（文件、函数、行号、环境开关）。
- `Regex`: 常用正则校验（手机号、邮箱、身份证、纯数字等）。
- `Info`: 系统信息（BundleId、版本、设备、系统信息）。
- `Language`: 国际化语言管理（手动切换、多语言读取）。
- `Storage`: 轻量存储封装（如 UserDefaults/Keychain 抽象）。
- `Model`: 通用模型解析、字典映射能力（可选）。

### 2) 扩展层 `XCExtensions` (System Enhancements)

- `UIKit`:
  - `UIView`: 尺寸、布局、阴影/圆角/边框共存、渐变。✅
  - `UIButton`: 图文布局、点击区域、状态样式管理、快速创建。 ✅
  - `UILabel`: 行距字距、富文本快捷构建、快速创建。 ✅
  - `UIImage`: 扩展。✅
  - `UITextField` / `UITextView`: placeholder、输入限制、光标处理。  ✅
  - `UIColor`: 扩展。 ✅
  - `UIFont` : 扩展。 ✅
  - `UISlider`: 扩展。 ✅
- `Foundation`:
  - `String`: 校验、尺寸计算、子串安全访问、富文本构建。 ✅
  - `Date`: 格式化、时间差、时区处理。 Calendar ✅
  - `Data`: 编解码、哈希、进制转换桥接。
  - `Array` / `Dictionary`: 安全取值、防越界辅助。

### 3) 架构层 `XCArchitecture` (App Infrastructure)

面向业务工程的“骨架能力”，降低项目初始化成本。

- `Base`: `BaseViewController` / `BaseNavigationController` / `BaseTabBarController` / `BaseWebViewController`。 ✅
- `Permission`: 相机、相册、定位、通知等权限申请封装。
- `Theme`: 自定义主题 + 系统深浅色模式适配。
- `Responder`: 当前顶层控制器、可见页面获取。
- `Adapter`: 屏幕尺寸比例与安全区适配。      ✅
- `Protocol`: 协议点击跳转、数据协议头管理。
- `Transition`: 常见页面转场与动画管理。

### 4) 组件层 `XCComponents` (Reusable UI Components)

沉淀可直接复用的 UI 组件，强调“低业务耦合、高复用”。

- `Popup`: 输入弹窗、确认弹窗、选择弹窗、气泡弹层。
- `Toast`: 轻提示、加载中、全局状态提示。
- `Picker`: 时间选择器、城市级联选择器等。
- `ImagePicker`: 相机/相册/裁剪统一入口。
- `ViewStates`: 空数据、加载中、网络异常占位页。
- `Keyboard/Animation`: 自定义键盘与常用交互动画。

### 5) 边界层 `XCNetwork` / `XCCrypto` / `XCThird`

把三方依赖和外部通信放在边界，控制依赖扩散。

- `XCNetwork`:
  - `Http`: Moya 二次封装（插件、Token 注入、统一错误处理）。
  - `Socket`: WebSocket（Starscream）与 MQTT（CocoaMQTT）封装。
  - 可扩展 `GCDWebServer` 等局域网能力。
- `XCCrypto`:
  - 基于 CryptoSwift 的 AES/MD5/RSA 等加密能力封装。
- `XCThird` (可选设计):
  - 集中管理 SnapKit/Kingfisher/Moya 等第三方适配器，避免业务层直接耦合具体实现。

### 6) 聚合层 `Main`

`Sources/Main/XCToolkit.swift` 作为总入口，对外导出模块，简化接入。

## Recommended Directory Layout

```text
XCToolkit/
├── Sources/
│   ├── Core/                    # XCCore
│   │   ├── Binary/
│   │   ├── Log/
│   │   ├── Regex/
│   │   ├── Info/
│   │   ├── Language/
│   │   ├── Storage/
│   │   └── Model/
│   ├── Extensions/              # XCExtensions
│   │   ├── UIKit/
│   │   └── Foundation/
│   ├── Architecture/            # XCArchitecture
│   │   ├── Base/
│   │   ├── Permission/
│   │   ├── Theme/
│   │   ├── Responder/
│   │   ├── Adapter/
│   │   ├── Protocol/
│   │   └── Transition/
│   ├── Components/              # XCComponents
│   │   ├── Popup/
│   │   ├── Toast/
│   │   ├── Picker/
│   │   ├── ImagePicker/
│   │   ├── ViewStates/
│   │   └── KeyboardAnimation/
│   ├── Network/                 # XCNetwork
│   │   ├── Http/
│   │   ├── Socket/
│   │   └── WebServer/
│   ├── Crypto/                  # XCCrypto
│   └── Main/                    # XCToolkit 聚合入口
├── Package.swift
├── XCToolkit.podspec
└── README.md
```

## Dependency Rules

建议遵循以下依赖方向（高层依赖低层，禁止反向依赖）：

- `XCCore` <- `XCExtensions` <- `XCComponents`
- `XCCore` <- `XCArchitecture`
- `XCCore` <- `XCNetwork`
- `XCCrypto` 独立存在，按需被 `XCNetwork` 或业务层引用
- `Main` 只做聚合导出，不承载业务逻辑

## Installation

### Swift Package Manager

在 `Package.swift` 中添加：

```swift
dependencies: [
    .package(url: "https://github.com/aliuhongliang/XCToolkit.git", from: "0.1.1")
]
```

使用（示例）：

```swift
import XCToolkit

Logger.log("Hello XCToolkit")
```

### CocoaPods

在 `Podfile` 中添加：

```ruby
pod 'XCToolkit', '~> 0.1'
```

按需引入子模块（示例）：

```ruby
pod 'XCToolkit/Core'
pod 'XCToolkit/Extensions'
pod 'XCToolkit/Architecture'
pod 'XCToolkit/Components'
pod 'XCToolkit/Network'
pod 'XCToolkit/Crypto'
```

## Current Status

当前仓库已具备基础入口与部分能力，模块目录正在逐步完善中。建议优先按以下顺序推进：

1. `XCCore`（日志/进制/正则/信息/语言/存储）。
2. `XCExtensions`（UIView/UIButton/UILabel/String/Date 等高频扩展）。
3. `XCArchitecture`（Base、Permission、Theme、Responder、Adapter）。
4. `XCComponents`（Toast/Popup/ViewStates/ImagePicker）。
5. `XCNetwork` + `XCCrypto`（Moya、Socket、MQTT、加密）。

## Roadmap

- [ ] 完成各模块最小可用 API（MVP）。
- [ ] 补齐单元测试与示例工程。
- [ ] 完善 API 文档与最佳实践。
- [ ] 建立版本化变更日志（CHANGELOG）。

## License

MIT.
