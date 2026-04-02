// Array+Extension.swift
// XCExtensions

import Foundation

// MARK: - 通用扩展

public extension Array {

    // MARK: 安全访问

    /// 安全下标，越界返回 nil
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }

    // MARK: 分组

    /// 按固定大小分组，如 [1,2,3,4,5].chunked(size:2) → [[1,2],[3,4],[5]]
    func chunked(size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }

    // MARK: 变换

    /// 返回删除指定 index 元素后的新数组（非 mutating）
    func removed(at index: Int) -> [Element] {
        guard indices.contains(index) else { return self }
        var copy = self
        copy.remove(at: index)
        return copy
    }

    // MARK: 转换

    /// 转换为字典，以 keyPath 的值为 key（key 重复时后者覆盖前者）
    func toDictionary<Key: Hashable>(_ keyPath: KeyPath<Element, Key>) -> [Key: Element] {
        reduce(into: [:]) { $0[$1[keyPath: keyPath]] = $1 }
    }

    /// 按 keyPath 查找第一个满足条件的元素
    func first<Value: Equatable>(where keyPath: KeyPath<Element, Value>, equals value: Value) -> Element? {
        first { $0[keyPath: keyPath] == value }
    }
}

// MARK: - Equatable 扩展

public extension Array where Element: Equatable {

    /// 去重，保留原始顺序
    var unique: [Element] {
        reduce(into: []) { if !$0.contains($1) { $0.append($1) } }
    }

    /// 是否包含另一个数组的所有元素
    func containsAll(_ elements: [Element]) -> Bool {
        elements.allSatisfy { contains($0) }
    }
}

// MARK: - Hashable 扩展

public extension Array where Element: Hashable {

    /// 按 Hashable 属性去重，效率更高，保留原始顺序
    var uniqued: [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }

    /// 按 keyPath 去重，保留原始顺序
    func uniqued<Value: Hashable>(by keyPath: KeyPath<Element, Value>) -> [Element] {
        var seen = Set<Value>()
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }

    /// 转为 Set
    var toSet: Set<Element> {
        Set(self)
    }
}

// MARK: - Optional 元素扩展

public extension Array {

    /// 过滤掉所有 nil，返回解包后的数组（等价于 compactMap { $0 }）
    func compacted<T>() -> [T] where Element == T? {
        compactMap { $0 }
    }
}

// MARK: - Comparable 扩展

public extension Array where Element: Comparable {

    /// 按 keyPath 升序排序（返回新数组）
    func sorted<Value: Comparable>(by keyPath: KeyPath<Element, Value>, ascending: Bool = true) -> [Element] {
        sorted {
            ascending
                ? $0[keyPath: keyPath] < $1[keyPath: keyPath]
                : $0[keyPath: keyPath] > $1[keyPath: keyPath]
        }
    }
}

// MARK: - Numeric 扩展

public extension Array where Element: Numeric {

    /// 求和
    var sum: Element {
        reduce(0, +)
    }
}

public extension Array where Element: BinaryInteger {

    /// 求平均值（返回 Double）
    var average: Double {
        isEmpty ? 0 : Double(sum) / Double(count)
    }
}

public extension Array where Element: BinaryFloatingPoint {

    /// 求和
    var sum: Element {
        reduce(0, +)
    }

    /// 求平均值
    var average: Element {
        isEmpty ? 0 : sum / Element(count)
    }
}
