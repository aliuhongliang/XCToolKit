import UIKit
 
// MARK: ========================================
// MARK: - 1. UILabel Extension
// MARK: ========================================
 
public extension UILabel {
 
    // MARK: 快速创建
 
    /// 工厂方法快速创建
    static func make(
        text: String? = nil,
        font: UIFont = .regular(14),
        color: UIColor = .black,
        alignment: NSTextAlignment = .left,
        lines: Int = 1
    ) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.textAlignment = alignment
        label.numberOfLines = lines
        return label
    }
 
    // MARK: 富文本快捷方法
    // 以下方法均基于当前 text/attributedText 叠加样式
    // 若已有 attributedText 则在其基础上追加，否则从 text 创建
 
    /// 设置行高
    func setLineHeight(_ lineHeight: CGFloat, alignment: NSTextAlignment? = nil) {
        let att = baseAttributedString()
        let style = existingParagraphStyle(from: att)
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        if let ali = alignment { style.alignment = ali }
        att.addAttribute(.paragraphStyle, value: style,
                         range: NSRange(location: 0, length: att.length))
        // 垂直居中补偿
        let offset = (lineHeight - (font?.lineHeight ?? lineHeight)) / 4
        att.addAttribute(.baselineOffset, value: offset,
                         range: NSRange(location: 0, length: att.length))
        attributedText = att
    }
 
    /// 设置字间距
    func setLetterSpacing(_ spacing: CGFloat) {
        let att = baseAttributedString()
        att.addAttribute(.kern, value: spacing,
                         range: NSRange(location: 0, length: att.length))
        attributedText = att
    }
 
    /// 设置删除线（默认当前文字颜色）
    func setStrikethrough(color: UIColor? = nil, style: NSUnderlineStyle = .single) {
        let att = baseAttributedString()
        let range = NSRange(location: 0, length: att.length)
        att.addAttribute(.strikethroughStyle, value: style.rawValue, range: range)
        att.addAttribute(.strikethroughColor, value: color ?? textColor ?? .black, range: range)
        attributedText = att
    }
 
    /// 设置下划线
    func setUnderline(color: UIColor? = nil, style: NSUnderlineStyle = .single) {
        let att = baseAttributedString()
        let range = NSRange(location: 0, length: att.length)
        att.addAttribute(.underlineStyle, value: style.rawValue, range: range)
        att.addAttribute(.underlineColor, value: color ?? textColor ?? .black, range: range)
        attributedText = att
    }
 
    /// 局部文字高亮（颜色 + 可选字体）
    /// - Parameters:
    ///   - target: 要高亮的子字符串
    ///   - color: 高亮颜色
    ///   - font: 高亮字体，nil 表示不改变字体
    func setHighlightedText(_ target: String,
                             color: UIColor,
                             font: UIFont? = nil) {
        let att = baseAttributedString()
        let fullText = att.string
        var searchRange = fullText.startIndex..<fullText.endIndex
        while let range = fullText.range(of: target, range: searchRange) {
            let nsRange = NSRange(range, in: fullText)
            att.addAttribute(.foregroundColor, value: color, range: nsRange)
            if let f = font {
                att.addAttribute(.font, value: f, range: nsRange)
            }
            searchRange = range.upperBound..<fullText.endIndex
        }
        attributedText = att
    }
 
    // MARK: 尺寸计算
 
    /// 当前文字实际渲染宽度
    var textWidth: CGFloat {
        guard let text = text, !text.isEmpty else { return 0 }
        return sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                   height: bounds.height)).width
    }
 
    /// 当前文字实际渲染高度
    var textHeight: CGFloat {
        guard let text = text, !text.isEmpty else { return 0 }
        return sizeThatFits(CGSize(width: bounds.width,
                                   height: CGFloat.greatestFiniteMagnitude)).height
    }
 
    /// 限制最大宽度，计算需要的 size
    func sizeThatFitsWidth(_ width: CGFloat) -> CGSize {
        sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
    }
 
    // MARK: 内容检测
 
    /// 文字是否被截断（用于展开/收起场景）
    var isTruncated: Bool {
        guard numberOfLines > 0 else { return false }
        // 用 TextKit 精确检测
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: bounds.width,
                                                         height: .greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode
        let textStorage = NSTextStorage(attributedString: baseAttributedString())
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        layoutManager.glyphRange(for: textContainer)
 
        let truncated = layoutManager.truncatedGlyphRange(inLineFragmentForGlyphAt:
            layoutManager.numberOfGlyphs - 1)
        return truncated.location != NSNotFound
    }
 
    // MARK: 私有工具
 
    /// 基于当前 text / attributedText 返回可变副本
    private func baseAttributedString() -> NSMutableAttributedString {
        if let att = attributedText {
            return NSMutableAttributedString(attributedString: att)
        }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font ?? UIFont.regular(14),
            .foregroundColor: textColor ?? UIColor.black
        ]
        return NSMutableAttributedString(string: text ?? "", attributes: attrs)
    }
 
    /// 提取已有 ParagraphStyle 副本（避免覆盖已设置的 alignment 等）
    private func existingParagraphStyle(from att: NSMutableAttributedString) -> NSMutableParagraphStyle {
        if att.length > 0,
           let existing = att.attribute(.paragraphStyle, at: 0, effectiveRange: nil)
                          as? NSParagraphStyle {
            return existing.mutableCopy() as! NSMutableParagraphStyle
        }
        let style = NSMutableParagraphStyle()
        style.alignment = textAlignment
        return style
    }
}
