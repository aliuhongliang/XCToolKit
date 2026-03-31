// UIFont+Extension.swift
// 字体工具扩展
//
// 模块：
//   1. 语义化快捷构造（regular / medium / semibold / bold）
//   2. 动态字体 / 无障碍支持
//   3. 自定义字体注册 & 加载
//   4. 字体变体修改（加粗 / 斜体 / 缩放）
//   5. 属性字符串快捷生成
//   6. 行高工具

import UIKit

// MARK: - 1. 语义化快捷构造

public extension UIFont {

    static func regular(_ size: CGFloat) -> UIFont {
        .systemFont(ofSize: size, weight: .regular)
    }

    static func medium(_ size: CGFloat) -> UIFont {
        .systemFont(ofSize: size, weight: .medium)
    }

    static func semibold(_ size: CGFloat) -> UIFont {
        .systemFont(ofSize: size, weight: .semibold)
    }

    static func bold(_ size: CGFloat) -> UIFont {
        .systemFont(ofSize: size, weight: .bold)
    }

    static func light(_ size: CGFloat) -> UIFont {
        .systemFont(ofSize: size, weight: .light)
    }

    static func thin(_ size: CGFloat) -> UIFont {
        .systemFont(ofSize: size, weight: .thin)
    }

    static func heavy(_ size: CGFloat) -> UIFont {
        .systemFont(ofSize: size, weight: .heavy)
    }
}

// MARK: - 2. 动态字体 / 无障碍支持

public extension UIFont {

    /// 创建跟随系统「字体大小」设置自动缩放的字体
    /// - Parameters:
    ///   - style: UIFont.TextStyle，如 .body / .headline / .caption1
    ///   - weight: 字重，默认 .regular
    static func dynamic(style: TextStyle, weight: Weight = .regular) -> UIFont {
        let descriptor = UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: style)
            .addingAttributes([
                .traits: [UIFontDescriptor.TraitKey.weight: weight]
            ])
        return UIFont(descriptor: descriptor, size: 0) // size=0 表示使用描述符中的字号
    }

    /// 将任意字体包装为支持动态缩放，并限制最大字号
    /// - Parameters:
    ///   - style: 对应的 TextStyle（决定缩放基准）
    ///   - maxSize: 最大字号上限，nil 表示不限制
    func scaledFont(style: TextStyle = .body, maxSize: CGFloat? = nil) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        if let max = maxSize {
            return metrics.scaledFont(for: self, maximumPointSize: max)
        }
        return metrics.scaledFont(for: self)
    }
}

// MARK: - 3. 自定义字体注册 & 加载

public extension UIFont {

    /// 从 Bundle 注册字体文件（支持 .ttf / .otf）
    /// 通常在 AppDelegate 或字体命名空间初始化时调用一次
    /// - Parameters:
    ///   - name: 字体文件名（不含扩展名），如 "PingFangSC-Medium"
    ///   - bundle: 字体所在 Bundle，默认 main
    @discardableResult
    static func register(name: String, bundle: Bundle = .main) -> Bool {
        let extensions = ["ttf", "otf"]
        for ext in extensions {
            guard let url = bundle.url(forResource: name, withExtension: ext) else { continue }
            var error: Unmanaged<CFError>?
            let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            if !success, let e = error?.takeRetainedValue() {
                print("[UIFont] 注册失败 \(name).\(ext): \(e)")
            }
            return success
        }
        print("[UIFont] 未找到字体文件: \(name)")
        return false
    }

    /// 加载自定义字体，找不到时自动 fallback
    /// - Parameters:
    ///   - name: PostScript 字体名，如 "PingFangSC-Medium"
    ///   - size: 字号
    ///   - fallback: 加载失败时的兜底字体，默认 .regular(size)
    static func custom(_ name: String,
                       size: CGFloat,
                       fallback: UIFont? = nil) -> UIFont {
        if let font = UIFont(name: name, size: size) { return font }
        print("[UIFont] 未找到字体: \(name)，使用 fallback")
        return fallback ?? .regular(size)
    }
}

// MARK: - 4. 字体变体修改

public extension UIFont {

    /// 加粗（基于当前字体的 descriptor，尽量保持字族）
    func bolded() -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.traitBold)
        return UIFont(descriptor: descriptor ?? fontDescriptor, size: pointSize)
    }

    /// 斜体
    func italicized() -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.traitItalic)
        return UIFont(descriptor: descriptor ?? fontDescriptor, size: pointSize)
    }

    /// 粗斜体
    func boldItalicized() -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic])
        return UIFont(descriptor: descriptor ?? fontDescriptor, size: pointSize)
    }

    /// 等宽字体变体（适合数字对齐，如直播计数器）
    @available(iOS 15.0, *)
    func monospaced() -> UIFont {
        let features: [[UIFontDescriptor.FeatureKey: Int]] = [[
            .type:     kNumberSpacingType,
            .selector: kMonospacedNumbersSelector
        ]]
        let descriptor = fontDescriptor.addingAttributes([.featureSettings: features])
        return UIFont(descriptor: descriptor, size: pointSize)
    }

    /// 按比例缩放字号（保持字族 & 字重）
    func scaled(by ratio: CGFloat) -> UIFont {
        return withSize((pointSize * ratio).rounded())
    }

    /// 安全 withSize（字号 < 1 时兜底为 1）
    func withSize(safe size: CGFloat) -> UIFont {
        withSize(max(1, size))
    }
}

// MARK: - 5. 属性字符串快捷生成

public extension UIFont {

    /// 快速生成 NSAttributedString
    /// - Parameters:
    ///   - text: 文字内容
    ///   - color: 文字颜色，默认黑色
    ///   - lineHeight: 固定行高（点），nil 表示不设置
    ///   - alignment: 对齐方式，默认 .left
    ///   - kern: 字间距，默认 0
    func attributed(
        _ text: String,
        color: UIColor = .label,
        lineHeight: CGFloat? = nil,
        alignment: NSTextAlignment = .left,
        kern: CGFloat = 0
    ) -> NSAttributedString {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: self,
            .foregroundColor: color,
        ]
        if kern != 0 {
            attrs[.kern] = kern
        }
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        if let lh = lineHeight {
            style.minimumLineHeight = lh
            style.maximumLineHeight = lh
            // 垂直居中补偿
            let offset = (lh - self.lineHeight) / 4
            attrs[.baselineOffset] = offset
        }
        attrs[.paragraphStyle] = style
        return NSAttributedString(string: text, attributes: attrs)
    }
}

// MARK: - 6. 行高工具

public extension UIFont {

    /// 根据倍数计算实际行高（点）
    /// 例：UIFont.regular(16).lineHeight(multiple: 1.5) → 24
    func lineHeight(multiple: CGFloat) -> CGFloat {
        (lineHeight * multiple).rounded()
    }

    /// 计算指定行高对应的 baselineOffset 补偿值
    /// 用于 NSAttributedString 行高精确居中
    func baselineOffset(forLineHeight targetLineHeight: CGFloat) -> CGFloat {
        (targetLineHeight - lineHeight) / 4
    }

    /// 段落样式：固定行高 + 对齐（直接用于 NSAttributedString）
    func paragraphStyle(lineHeight: CGFloat,
                        alignment: NSTextAlignment = .left) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        style.alignment = alignment
        return style
    }
}
