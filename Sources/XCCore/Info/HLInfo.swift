import UIKit
import Darwin   // sysctlbyname

// MARK: - HLInfo namespace

/// 设备与 App 信息，按三个命名空间组织
/// 全部静态访问，内部懒加载
public enum HLInfo {}

// MARK: - HLInfo.App

public extension HLInfo {

    enum App {
        private static let bundle = Bundle.main

        /// Bundle Identifier，如 com.company.appname
        public static let bundleId: String =
            bundle.bundleIdentifier ?? ""

        /// 对外版本号，如 1.2.3
        public static let version: String =
            bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"

        /// 构建号，如 100
        public static let build: String =
            bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"

        /// App 显示名称
        public static let displayName: String =
            bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? ""

        /// 最低支持系统版本
        public static let minimumOSVersion: String =
            bundle.object(forInfoDictionaryKey: "MinimumOSVersion") as? String ?? ""

        /// 发布渠道
        public static let channel: AppChannel = {
            #if DEBUG
            return .debug
            #else
            if let receiptURL = bundle.appStoreReceiptURL {
                if receiptURL.path.contains("sandboxReceipt") { return .testFlight }
                return .appStore
            }
            return .debug
            #endif
        }()

        public var isDebug:      Bool { HLInfo.App.channel == .debug }
        public var isTestFlight: Bool { HLInfo.App.channel == .testFlight }
        public var isAppStore:   Bool { HLInfo.App.channel == .appStore }
    }
}

public enum AppChannel: String {
    case debug
    case testFlight = "testflight"
    case appStore   = "appstore"
}

// MARK: - HLInfo.Device

public extension HLInfo {

    enum Device {

        /// 设备硬件 identifier，如 iPhone16,1
        public static let identifier: String = {
            var size = 0
            sysctlbyname("hw.machine", nil, &size, nil, 0)
            var machine = [CChar](repeating: 0, count: size)
            sysctlbyname("hw.machine", &machine, &size, nil, 0)
            let id = String(cString: machine)
            // 模拟器从环境变量读真实机型
            if id == "x86_64" || id == "arm64" {
                return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? id
            }
            return id
        }()

        /// 友好型号名称，如 iPhone 15 Pro
        public static let model: String =
            DeviceModelMap.name(for: identifier)

        /// 系统版本，如 17.2
        public static let systemVersion: String =
            UIDevice.current.systemVersion

        /// 系统名称，如 iOS
        public static let systemName: String =
            UIDevice.current.systemName

        /// 是否运行在模拟器
        public static let isSimulator: Bool = {
            #if targetEnvironment(simulator)
            return true
            #else
            return false
            #endif
        }()

        /// 是否越狱（基础检测，无法 100% 覆盖）
        public static let isJailbroken: Bool = {
            #if targetEnvironment(simulator)
            return false
            #else
            let jailbreakPaths = [
                "/Applications/Cydia.app",
                "/Library/MobileSubstrate/MobileSubstrate.dylib",
                "/bin/bash",
                "/usr/sbin/sshd",
                "/etc/apt",
                "/private/var/lib/apt"
            ]
            if jailbreakPaths.contains(where: { FileManager.default.fileExists(atPath: $0) }) {
                return true
            }
            // 尝试写入沙盒外的路径
            let testPath = "/private/jailbreak_test_\(UUID().uuidString)"
            do {
                try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
                try FileManager.default.removeItem(atPath: testPath)
                return true
            } catch {
                return false
            }
            #endif
        }()

        /// 设备唯一标识（UUID + Keychain 持久化，重装 App 不变）
        public static let udid: String = DeviceUDID.fetch()
    }
}

// MARK: - HLInfo.Runtime

public extension HLInfo {

    enum Runtime {

        /// 屏幕物理尺寸（points）
        public static var screenSize: CGSize {
            UIScreen.main.bounds.size
        }

        /// 屏幕像素密度（@2x = 2.0，@3x = 3.0）
        public static var screenScale: CGFloat {
            UIScreen.main.scale
        }

        /// 屏幕像素尺寸
        public static var screenPixelSize: CGSize {
            CGSize(
                width:  screenSize.width  * screenScale,
                height: screenSize.height * screenScale
            )
        }

        /// 安全区 insets（需在主线程访问）
        @MainActor
        public static var safeAreaInsets: UIEdgeInsets {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)?
                .safeAreaInsets ?? .zero
        }

        /// 是否横屏
        public static var isLandscape: Bool {
            UIDevice.current.orientation.isLandscape
        }

        /// 当前时区
        public static var timezone: TimeZone {
            TimeZone.current
        }

        /// 当前 Locale
        public static var locale: Locale {
            Locale.current
        }

        /// 系统首选语言代码，如 zh-Hans / en
        public static var preferredLanguage: String {
            Locale.preferredLanguages.first ?? "en"
        }

        /// 系统首选语言的区域标识符，如 zh_CN / en_US
        public static var localeIdentifier: String {
            locale.identifier
        }
    }
}

// MARK: - DeviceUDID (Keychain persistence)

private enum DeviceUDID {
    private static let service = "com.hlcore.device"
    private static let account = "udid"

    static func fetch() -> String {
        if let existing = read() { return existing }
        let newUDID = UUID().uuidString
        save(newUDID)
        return newUDID
    }

    private static func read() -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      account,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne,
            // 重装后 Keychain 仍保留
            kSecAttrAccessible:   kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    private static func save(_ udid: String) {
        guard let data = udid.data(using: .utf8) else { return }
        let query: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrService:     service,
            kSecAttrAccount:     account,
            kSecValueData:       data,
            kSecAttrAccessible:  kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)   // 先删旧值
        SecItemAdd(query as CFDictionary, nil)
    }
}

// MARK: - DeviceModelMap

private enum DeviceModelMap {
    static func name(for identifier: String) -> String {
        modelMap[identifier] ?? identifier
    }

    // 覆盖主流机型，新机型 identifier 不在表内时降级返回原始字符串
    private static let modelMap: [String: String] = [
        // iPhone 15 系列
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone15,4": "iPhone 15",
        "iPhone15,5": "iPhone 15 Plus",
        // iPhone 14 系列
        "iPhone15,2": "iPhone 14 Pro",
        "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone14,7": "iPhone 14",
        "iPhone14,8": "iPhone 14 Plus",
        // iPhone 13 系列
        "iPhone14,2": "iPhone 13 Pro",
        "iPhone14,3": "iPhone 13 Pro Max",
        "iPhone14,4": "iPhone 13 mini",
        "iPhone14,5": "iPhone 13",
        // iPhone 12 系列
        "iPhone13,1": "iPhone 12 mini",
        "iPhone13,2": "iPhone 12",
        "iPhone13,3": "iPhone 12 Pro",
        "iPhone13,4": "iPhone 12 Pro Max",
        // iPhone 11 系列
        "iPhone12,1": "iPhone 11",
        "iPhone12,3": "iPhone 11 Pro",
        "iPhone12,5": "iPhone 11 Pro Max",
        // iPhone XS/XR
        "iPhone11,2": "iPhone XS",
        "iPhone11,4": "iPhone XS Max",
        "iPhone11,6": "iPhone XS Max",
        "iPhone11,8": "iPhone XR",
        // iPhone SE
        "iPhone14,6": "iPhone SE (3rd gen)",
        "iPhone12,8": "iPhone SE (2nd gen)",
        "iPhone8,4":  "iPhone SE (1st gen)",
        // iPad Pro (最新)
        "iPad14,3":   "iPad Pro 11-inch (4th gen)",
        "iPad14,4":   "iPad Pro 11-inch (4th gen)",
        "iPad14,5":   "iPad Pro 12.9-inch (6th gen)",
        "iPad14,6":   "iPad Pro 12.9-inch (6th gen)",
        // iPad Air
        "iPad13,16":  "iPad Air (5th gen)",
        "iPad13,17":  "iPad Air (5th gen)",
        // iPad mini
        "iPad14,1":   "iPad mini (6th gen)",
        "iPad14,2":   "iPad mini (6th gen)",
    ]
}
