//
//  File.swift
//  XCToolkit
//
//  Created by wintop on 2026/3/31.
//

// 使用示例:
//   UIColor(hex: "#fff")
//   UIColor(hex: "#ff6600")
//   UIColor(hex: "#ff660080")
//   UIColor(hex: "0xFF6600")
//   UIColor(hex: "rgb(255, 102, 0)")
//   UIColor(hex: "rgba(255, 102, 0, 0.5)")
//   UIColor(rgb: 0xFF6600)
//   UIColor(argb: 0x80FF6600)

import UIKit

// MARK: - UIColor + Hex / RGB 字符串 初始化

public extension UIColor {

    // MARK: 字符串初始化入口

    /// 通用字符串初始化
    /// - Parameters:
    ///   - hex: 支持 #rgb / #rrggbb / #rrggbbaa / 0xRRGGBB / 0xRRGGBBAA / rgb(...) / rgba(...)
    ///   - defaultColor: 解析失败时的兜底颜色，默认 clear
    convenience init(hex: String, default defaultColor: UIColor = .clear) {
        let parsed = UIColor.parse(hex) ?? defaultColor
        // 取出 RGBA 分量再初始化，避免直接转型
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        parsed.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(red: r, green: g, blue: b, alpha: a)
    }
    
    /// 通用字符串初始化 + 独立 Alpha 覆盖
    /// - Parameters:
    ///   - hex: 支持 #rgb / #rrggbb / 0xRRGGBB / rgb(...) 等（字符串自带的 alpha 会被此参数覆盖）
    ///   - alpha: 透明度 0.0 ~ 1.0
    /// - Example: UIColor(hex: "#FF6600", alpha: 0.5)
    convenience init(hex: String, alpha: CGFloat) {
        let parsed = UIColor.parse(hex) ?? .clear
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        parsed.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.init(red: r, green: g, blue: b, alpha: alpha.clamped(to: 0...1))
    }
    
    // MARK: 整数初始化（RGB / ARGB / RGBA）

    /// 从 0xRRGGBB 整数初始化，Alpha = 1.0
    convenience init(rgb value: UInt32) {
        self.init(
            red:   CGFloat((value >> 16) & 0xFF) / 255.0,
            green: CGFloat((value >>  8) & 0xFF) / 255.0,
            blue:  CGFloat( value        & 0xFF) / 255.0,
            alpha: 1.0
        )
    }

    /// 从 0xRRGGBB 整数 + 独立 Alpha 初始化
    /// - Parameters:
    ///   - rgb: 0xRRGGBB 颜色值
    ///   - alpha: 透明度 0.0 ~ 1.0，默认 1.0
    /// - Example: UIColor(rgb: 0xFF6600, alpha: 0.5)
    convenience init(rgb value: UInt32, alpha: CGFloat) {
        self.init(
            red:   CGFloat((value >> 16) & 0xFF) / 255.0,
            green: CGFloat((value >>  8) & 0xFF) / 255.0,
            blue:  CGFloat( value        & 0xFF) / 255.0,
            alpha: alpha.clamped(to: 0...1)
        )
    }

    /// 从 0xAARRGGBB 整数初始化（高位为 Alpha）
    convenience init(argb value: UInt32) {
        self.init(
            red:   CGFloat((value >> 16) & 0xFF) / 255.0,
            green: CGFloat((value >>  8) & 0xFF) / 255.0,
            blue:  CGFloat( value        & 0xFF) / 255.0,
            alpha: CGFloat((value >> 24) & 0xFF) / 255.0
        )
    }

    /// 从 0xRRGGBBAA 整数初始化（低位为 Alpha）
    convenience init(rgba value: UInt32) {
        self.init(
            red:   CGFloat((value >> 24) & 0xFF) / 255.0,
            green: CGFloat((value >> 16) & 0xFF) / 255.0,
            blue:  CGFloat((value >>  8) & 0xFF) / 255.0,
            alpha: CGFloat( value        & 0xFF) / 255.0
        )
    }

    // MARK: 分量初始化（0-255 整数值）

    /// 使用 0~255 整数分量初始化
    convenience init(r: Int, g: Int, b: Int, a: Int = 255) {
        self.init(
            red:   CGFloat(r.clamped(to: 0...255)) / 255.0,
            green: CGFloat(g.clamped(to: 0...255)) / 255.0,
            blue:  CGFloat(b.clamped(to: 0...255)) / 255.0,
            alpha: CGFloat(a.clamped(to: 0...255)) / 255.0
        )
    }

    // MARK: 导出

    /// 转换为 #RRGGBB 字符串
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X",
                      Int(r * 255), Int(g * 255), Int(b * 255))
    }

    /// 转换为 #RRGGBBAA 字符串（含透明度）
    var hexStringWithAlpha: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X%02X",
                      Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
    }

    /// 转换为 rgba(r, g, b, a) 字符串
    var rgbaString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let alpha = (a * 100).rounded() / 100   // 保留两位小数
        return "rgba(\(Int(r*255)), \(Int(g*255)), \(Int(b*255)), \(alpha))"
    }

    // MARK: - 私有核心解析

    private static func parse(_ raw: String) -> UIColor? {
        let str = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // rgb(...) / rgba(...)
        if str.lowercased().hasPrefix("rgb") {
            return parseRGBFunction(str)
        }

        // 提取纯 Hex 字符串
        var hexPart = str
        if hexPart.hasPrefix("#")  { hexPart = String(hexPart.dropFirst()) }
        if hexPart.lowercased().hasPrefix("0x") { hexPart = String(hexPart.dropFirst(2)) }

        guard hexPart.allSatisfy({ $0.isHexDigit }) else { return nil }

        switch hexPart.count {
        case 3:  return parseHex3(hexPart)
        case 4:  return parseHex4(hexPart)   // #rgba (CSS 短写，Alpha 在末尾)
        case 6:  return parseHex6(hexPart)
        case 8:  return parseHex8(hexPart)   // #rrggbbaa
        default: return nil
        }
    }

    // #rgb → #rrggbb
    private static func parseHex3(_ s: String) -> UIColor? {
        let chars = Array(s)
        let r = String(repeating: chars[0], count: 2)
        let g = String(repeating: chars[1], count: 2)
        let b = String(repeating: chars[2], count: 2)
        return parseHex6(r + g + b)
    }

    // #rgba → #rrggbbaa
    private static func parseHex4(_ s: String) -> UIColor? {
        let chars = Array(s)
        let r = String(repeating: chars[0], count: 2)
        let g = String(repeating: chars[1], count: 2)
        let b = String(repeating: chars[2], count: 2)
        let a = String(repeating: chars[3], count: 2)
        return parseHex8(r + g + b + a)
    }

    // #rrggbb
    private static func parseHex6(_ s: String) -> UIColor? {
        guard let value = UInt32(s, radix: 16) else { return nil }
        return UIColor(rgb: value)
    }

    // #rrggbbaa (末尾为 Alpha)
    private static func parseHex8(_ s: String) -> UIColor? {
        guard let value = UInt32(s, radix: 16) else { return nil }
        return UIColor(rgba: value)
    }

    // rgb(r, g, b) / rgba(r, g, b, a)
    private static func parseRGBFunction(_ s: String) -> UIColor? {
        // 去掉函数名和括号，提取参数部分
        guard let open  = s.firstIndex(of: "("),
              let close = s.lastIndex(of: ")")
        else { return nil }

        let inner = String(s[s.index(after: open)..<close])
        let parts = inner.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        guard parts.count == 3 || parts.count == 4,
              let r = Double(parts[0]),
              let g = Double(parts[1]),
              let b = Double(parts[2])
        else { return nil }

        // Alpha: 0-1 浮点 或 0-255 整数 均支持
        let alpha: CGFloat
        if parts.count == 4 {
            guard let rawA = Double(parts[3]) else { return nil }
            alpha = rawA > 1.0 ? CGFloat(rawA / 255.0) : CGFloat(rawA)
        } else {
            alpha = 1.0
        }

        return UIColor(
            red:   CGFloat(r / 255.0),
            green: CGFloat(g / 255.0),
            blue:  CGFloat(b / 255.0),
            alpha: alpha
        )
    }
    
    // MARK: - 随机色
    
    /// 生成一个随机颜色 (Alpha = 1.0)
    static var random: UIColor {
        return UIColor(
            red:   CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue:  CGFloat.random(in: 0...1),
            alpha: 1.0
        )
    }
    
    /// 生成一个带指定透明度的随机颜色
    /// - Parameter alpha: 透明度 0.0 ~ 1.0
    static func random(alpha: CGFloat) -> UIColor {
        return UIColor(
            red:   CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue:  CGFloat.random(in: 0...1),
            alpha: alpha.clamped(to: 0...1)
        )
    }
}

// MARK: - 私有辅助

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        return Swift.max(range.lowerBound, Swift.min(self, range.upperBound))
    }
}

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        return Swift.max(range.lowerBound, Swift.min(self, range.upperBound))
    }
}

// MARK: - 便捷全局函数（可选，仿 SwiftUI 风格）

/// 快速从字符串创建颜色，失败返回 nil
public func color(_ hex: String) -> UIColor? {
    let c = UIColor(hex: hex)
    // 检查是否等于 .clear（即解析失败的兜底值）
    var a: CGFloat = 0
    c.getWhite(nil, alpha: &a)
    return c
}
