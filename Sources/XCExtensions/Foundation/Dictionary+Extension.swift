// Dictionary+Extension.swift
// XCExtensions

import Foundation

// MARK: - 通用扩展

public extension Dictionary {

    // MARK: 合并

    /// 合并另一个字典，后者覆盖前者（返回新字典）
    func merging(_ other: [Key: Value]) -> [Key: Value] {
        merging(other) { _, new in new }
    }

    /// 合并另一个字典，后者覆盖前者（mutating）
    mutating func merge(_ other: [Key: Value]) {
        merge(other) { _, new in new }
    }

    /// `+` 运算符合并，右侧覆盖左侧
    static func + (lhs: [Key: Value], rhs: [Key: Value]) -> [Key: Value] {
        lhs.merging(rhs)
    }

    /// `+=` 运算符合并
    static func += (lhs: inout [Key: Value], rhs: [Key: Value]) {
        lhs.merge(rhs)
    }

    // MARK: 转换

    /// 转换所有 key，返回新字典（key 冲突时后者覆盖前者）
    func mapKeys<NewKey: Hashable>(_ transform: (Key) throws -> NewKey) rethrows -> [NewKey: Value] {
        try reduce(into: [:]) { result, pair in
            result[try transform(pair.key)] = pair.value
        }
    }

    /// 按 key 集合过滤，返回只包含指定 key 的子字典
    func filter(keys: Set<Key>) -> [Key: Value] {
        filter { keys.contains($0.key) }
    }

    /// 排除指定 key 集合，返回剩余子字典
    func excluding(keys: Set<Key>) -> [Key: Value] {
        filter { !keys.contains($0.key) }
    }
}

// MARK: - String Key 扩展

public extension Dictionary where Key == String {

    // MARK: JSON 序列化

    /// 序列化为 JSON Data
    var toJSONData: Data? {
        guard JSONSerialization.isValidJSONObject(self) else { return nil }
        return try? JSONSerialization.data(withJSONObject: self, options: [])
    }

    /// 序列化为格式化 JSON 字符串（prettify）
    var toJSONString: String? {
        toJSONData.flatMap { String(data: $0, encoding: .utf8) }
    }

    /// 序列化为格式化 JSON 字符串（带缩进）
    var toPrettyJSONString: String? {
        guard JSONSerialization.isValidJSONObject(self) else { return nil }
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: Codable 解码

    /// 直接解码为 Decodable 模型
    func decode<T: Decodable>(_ type: T.Type, decoder: JSONDecoder = JSONDecoder()) throws -> T {
        guard let data = toJSONData else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid JSON object"))
        }
        return try decoder.decode(type, from: data)
    }

    // MARK: 嵌套 KeyPath 取值

    /// 点语法嵌套取值，如 `dict.value(forKeyPath: "user.profile.name")`
    func value(forKeyPath keyPath: String) -> Any? {
        let keys = keyPath.components(separatedBy: ".")
        return keys.reduce(self as Any?) { current, key in
            (current as? [String: Any])?[key]
        }
    }

    /// 嵌套取值并尝试转为指定类型
    func value<T>(forKeyPath keyPath: String, as type: T.Type) -> T? {
        value(forKeyPath: keyPath) as? T
    }

    // MARK: URL Query

    /// 转为 URL query string，如 `"a=1&b=2"`
    var toQueryString: String {
        map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? key
            let encodedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "\(value)"
            return "\(encodedKey)=\(encodedValue)"
        }
        .sorted()
        .joined(separator: "&")
    }

    /// 从 URL query string 构造字典，如 `"a=1&b=2"` → `["a": "1", "b": "2"]`
    init(queryString: String) {
        self.init()
        guard let dict = self as? [String: String] as? [Key: Value] else { return }
        _ = dict
        queryString.components(separatedBy: "&").forEach { pair in
            let parts = pair.components(separatedBy: "=")
            guard parts.count == 2 else { return }
            let key = parts[0].removingPercentEncoding ?? parts[0]
            let value = parts[1].removingPercentEncoding ?? parts[1]
            if let k = key as? Key, let v = value as? Value {
                self[k] = v
            }
        }
    }
}
