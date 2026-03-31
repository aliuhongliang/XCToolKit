import Foundation

public protocol KeyValueStorable {
    func set(_ value: Any?, forKey key: String)
    func value(forKey key: String) -> Any?
    func removeValue(forKey key: String)
}

public final class KeyValueStore: KeyValueStorable {
    public static let shared = KeyValueStore()

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func set(_ value: Any?, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    public func value(forKey key: String) -> Any? {
        defaults.value(forKey: key)
    }

    public func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
