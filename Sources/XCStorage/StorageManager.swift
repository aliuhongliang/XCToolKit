import Foundation

public class StorageManager {
    public static let shared = StorageManager()
    private let defaults = UserDefaults.standard
    private init() {}
    public func set<T>(_ value: T, forKey key: String) {
        defaults.set(value, forKey: key)
    }
    public func get<T>(forKey key: String) -> T? {
        return defaults.value(forKey: key) as? T
    }
    public func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
