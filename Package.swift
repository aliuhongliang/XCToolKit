
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "XCToolkit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(name: "XCFoundation", targets: ["XCFoundation"]),
        .library(name: "XCLogger", targets: ["XCLogger"]),
        .library(name: "XCStorage", targets: ["XCStorage"]),
    ],
    targets: [
        // MARK: - Core
        .target(
            name: "XCFoundation",
            path: "Sources/XCFoundation"
        ),
        
        // MARK: - Logger
        .target(
            name: "XCLogger",
            dependencies: ["XCFoundation"],
            path: "Sources/XCLogger"
        ),
        
        // MARK: - Storage
        .target(
            name: "XCStorage",
            dependencies: ["XCFoundation"],
            path: "Sources/XCStorage"
        ),
        
        // MARK: - Tests
//        .testTarget(
//            name: "XCToolkitTests",
//            dependencies: ["XCFoundation"],
//            path: "Tests"
//        )
    ]
)
