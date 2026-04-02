// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "XCToolkit",
//    defaultLocalization: "en",
    platforms: [
        .iOS(.v13) // 考虑到暗黑模式和现代 UI 组件
    ],
    products: [
        .library(name: "XCToolkit", targets: ["XCToolkit"]),
        .library(name: "XCNetwork", targets: ["XCNetwork"]),
        .library(name: "XCCrypto", targets: ["XCCrypto"]),
    ],
    dependencies: [
        // 只有核心 Target 需要依赖时才引入
        .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "15.0.0")),
        .package(url: "https://github.com/daltoniam/Starscream.git", .upToNextMajor(from: "4.0.0")),
        .package(url: "https://github.com/emqx/CocoaMQTT.git", .upToNextMajor(from: "2.1.0")),
    ],
    targets: [
        .target(
            name: "XCToolkit",
            dependencies: [
                "XCCore", "XCExtensions", "XCArchitecture", "XCComponents"
            ],
            path: "Sources/Main"
        ),
        .target(name: "XCCore", path: "Sources/XCCore"),
        .target(name: "XCExtensions", dependencies: ["XCCore"], path: "Sources/XCExtensions"),
        .target(name: "XCComponents", dependencies: ["XCExtensions"], path: "Sources/XCComponents"),
        .target(name: "XCArchitecture", dependencies: ["XCCore", "XCExtensions"], path: "Sources/XCArchitecture"),
        // 涉及三方的独立模块
        .target(
            name: "XCNetwork",
            dependencies: ["Moya", "Starscream", "CocoaMQTT", "XCCore"],
            path: "Sources/XCNetwork"
        ),
        .target(
            name: "XCCrypto",
            dependencies: [],
            path: "Sources/XCCrypto",
            linkerSettings: [
                .linkedFramework("Security")  // RSA 用到
                // CryptoKit、CommonCrypto 会自动链接，无需声明
            ]
        )
    ]
)
