import Foundation

public enum AppInfo {
    public static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? ""
    }

    public static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    public static var buildVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    }

    public static var appDisplayName: String {
        if let localized = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return localized
        }
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
    }
}
