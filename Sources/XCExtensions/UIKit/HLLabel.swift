
import UIKit

// MARK: ========================================
// MARK: - 2. HLLabel 子类
// MARK: ========================================
 
/// 支持内边距 + 长按复制的 UILabel 子类
open class HLLabel: UILabel {
 
    // MARK: 内边距
 
    /// 文字内边距（影响绘制区域和 intrinsicContentSize）
    public var contentInset: UIEdgeInsets = .zero {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }
 
    open override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width  += contentInset.left + contentInset.right
        size.height += contentInset.top  + contentInset.bottom
        return size
    }
 
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let insetSize = CGSize(
            width:  size.width  - contentInset.left - contentInset.right,
            height: size.height - contentInset.top  - contentInset.bottom
        )
        var result = super.sizeThatFits(insetSize)
        result.width  += contentInset.left + contentInset.right
        result.height += contentInset.top  + contentInset.bottom
        return result
    }
 
    open override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInset))
    }
 
    // MARK: 可复制（长按）
 
    /// 开启长按复制
    public var copyable: Bool = false {
        didSet {
            if copyable {
                isUserInteractionEnabled = true
                addGestureRecognizer(longPressGesture)
            } else {
                removeGestureRecognizer(longPressGesture)
            }
        }
    }
 
    /// 复制的内容，默认取 text，可自定义
    public var copyContent: String? = nil
 
    private lazy var longPressGesture: UILongPressGestureRecognizer = {
        UILongPressGestureRecognizer(target: self,
                                     action: #selector(_handleLongPress(_:)))
    }()
 
    @objc private func _handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        becomeFirstResponder()
        let menu = UIMenuController.shared
        let copyItem = UIMenuItem(title: "复制", action: #selector(_copyText))
        menu.menuItems = [copyItem]
        if #available(iOS 13.0, *) {
            menu.showMenu(from: self, rect: bounds)
        } else {
            menu.setTargetRect(bounds, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }
 
    @objc private func _copyText() {
        UIPasteboard.general.string = copyContent ?? text
    }
 
    open override var canBecomeFirstResponder: Bool { copyable }
 
    open override func canPerformAction(_ action: Selector,
                                        withSender sender: Any?) -> Bool {
        action == #selector(_copyText)
    }
    
    // MARK: 点击链接
    
    /// 设置可点击的链接文字及回调
    /// - Parameters:
    ///   - text: 要设置为可点击的子字符串
    ///   - color: 链接颜色，默认蓝色
    ///   - handler: 点击回调，返回被点击的文字
    public func addLink(_ text: String,
                        color: UIColor = .systemBlue,
                        handler: @escaping (String) -> Void) {
        // 高亮链接文字
        setHighlightedText(text, color: color)
        
        // 记录链接
        var links = linkItems
        links.append(LinkItem(text: text, handler: handler))
        linkItems = links
        
        // 开启点击检测
        isUserInteractionEnabled = true
        if tapGesture.view == nil {
            addGestureRecognizer(tapGesture)
        }
    }
    
    /// 清除所有链接
    public func removeAllLinks() {
        linkItems = []
        removeGestureRecognizer(tapGesture)
    }
    
    // MARK: 私有 — TextKit 点击检测
    
    private struct LinkItem {
        let text: String
        let handler: (String) -> Void
    }
    
    private var linkItems: [LinkItem] {
        get { objc_getAssociatedObject(self, &HLLabelKeys.linkItems) as? [LinkItem] ?? [] }
        set { objc_setAssociatedObject(self, &HLLabelKeys.linkItems,
                                       newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    private lazy var tapGesture: UITapGestureRecognizer = {
        UITapGestureRecognizer(target: self, action: #selector(_handleTap(_:)))
    }()
    
    @objc private func _handleTap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let tapPoint = gesture.location(in: self)
        
        // bounds 为零时 TextKit 无法正常布局，提前退出
        guard bounds.width > 0, bounds.height > 0 else { return }
        
        // 构建带完整属性的 attributedString
        // TextKit 没有 font 信息会用系统默认字体，导致字形位置偏差
        let baseAtt: NSAttributedString
        if let att = attributedText, att.length > 0 {
            let mutable = NSMutableAttributedString(attributedString: att)
            let fullRange = NSRange(location: 0, length: mutable.length)
            let labelFont = font ?? UIFont.systemFont(ofSize: 17)
            
            // 补全缺失的 font
            mutable.enumerateAttribute(.font, in: fullRange) { value, range, _ in
                if value == nil {
                    mutable.addAttribute(.font, value: labelFont, range: range)
                }
            }
            // 补全缺失的 paragraphStyle（对齐方式影响水平布局）
            let style = NSMutableParagraphStyle()
            style.alignment = textAlignment
            style.lineBreakMode = lineBreakMode
            mutable.enumerateAttribute(.paragraphStyle, in: fullRange) { value, range, _ in
                if value == nil {
                    mutable.addAttribute(.paragraphStyle, value: style, range: range)
                }
            }
            baseAtt = mutable
        } else {
            let style = NSMutableParagraphStyle()
            style.alignment = textAlignment
            style.lineBreakMode = lineBreakMode
            baseAtt = NSAttributedString(string: text ?? "", attributes: [
                .font: font ?? UIFont.systemFont(ofSize: 17),
                .paragraphStyle: style
            ])
        }
        
        // 构建 TextKit 栈，container 尺寸去掉 contentInset
        let containerSize = CGSize(
            width:  bounds.width  - contentInset.left - contentInset.right,
            height: bounds.height - contentInset.top  - contentInset.bottom
        )
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: containerSize)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode
        
        let textStorage = NSTextStorage(attributedString: baseAtt)
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        layoutManager.ensureLayout(for: textContainer)
        
        // 文字在 container 内的实际占用区域
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        
        // 将点击坐标转换到 TextKit 坐标系
        // 需要补偿：contentInset + 文字垂直居中偏移 + 对齐水平偏移
        let offsetX = contentInset.left + (containerSize.width  - textBoundingBox.width)  * alignmentOffsetX()
        let offsetY = contentInset.top  + (containerSize.height - textBoundingBox.height) * 0.5
        let pointInText = CGPoint(
            x: tapPoint.x - offsetX + textBoundingBox.minX,
            y: tapPoint.y - offsetY + textBoundingBox.minY
        )
        
        // 找到点击位置对应的字形
        var fraction: CGFloat = 0
        let glyphIndex = layoutManager.glyphIndex(for: pointInText,
                                                  in: textContainer,
                                                  fractionOfDistanceThroughGlyph: &fraction)
        // fraction == 1.0 表示点在最后字形右侧空白，非文字区域
        guard fraction < 1.0 else { return }
        
        let charIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)
        let fullText  = baseAtt.string
        
        // 遍历链接，检查 charIndex 是否落在链接范围内
        for item in linkItems {
            var searchRange = fullText.startIndex..<fullText.endIndex
            while let range = fullText.range(of: item.text, range: searchRange) {
                let nsRange = NSRange(range, in: fullText)
                if NSLocationInRange(charIndex, nsRange) {
                    item.handler(item.text)
                    return
                }
                searchRange = range.upperBound..<fullText.endIndex
            }
        }
    }
    
    /// 根据 textAlignment 计算水平偏移系数
    private func alignmentOffsetX() -> CGFloat {
        switch textAlignment {
        case .center:                    return 0.5
        case .right, .natural where
            UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft:
            return 1.0
        default:                         return 0.0  // left / natural(LTR)
        }
    }
}


// MARK: - HLLabel AssociatedKeys

private enum HLLabelKeys {
   static var linkItems = "linkItems"
}
