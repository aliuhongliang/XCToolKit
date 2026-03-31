// MARK: ========================================
// MARK: - 2. UITextView
// MARK: ========================================

import UIKit

/// 带 placeholder 支持的 UITextView
/// 直接替换系统 UITextView 使用，无需子类化
public extension UITextView {
    
    // MARK: Placeholder
 
    /// 设置 placeholder（UITextView 系统不支持，通过 label 模拟）
    var placeholder: String? {
        get { placeholderLabel?.text }
        set {
            ensurePlaceholderLabel()
            placeholderLabel?.text = newValue
            _tv_updatePlaceholder()
        }
    }
 
    /// placeholder 颜色
    var placeholderColor: UIColor {
        get { placeholderLabel?.textColor ?? UIColor.black.withAlphaComponent(0.3) }
        set {
            ensurePlaceholderLabel()
            placeholderLabel?.textColor = newValue
        }
    }
 
    /// placeholder 字体（不设置则跟随 textView.font）
    var placeholderFont: UIFont? {
        get { placeholderLabel?.font }
        set {
            ensurePlaceholderLabel()
            placeholderLabel?.font = newValue ?? font ?? .regular(14)
        }
    }
 
    // MARK: 输入限制
 
    /// 绑定最大输入长度（超出自动截断，中文/emoji 安全处理）
    func limitLength(_ maxLength: Int) {
        objc_setAssociatedObject(self, &AssociatedKeys.maxLength,
                                 maxLength, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_tv_limitLength),
            name: UITextView.textDidChangeNotification,
            object: self
        )
    }
 
    /// 禁止输入 emoji
    func disableEmoji() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_tv_filterEmoji),
            name: UITextView.textDidChangeNotification,
            object: self
        )
    }
 
    /// 当前已输入字符数
    var characterCount: Int { text?.count ?? 0 }
 
    // MARK: 高度自适应
 
    /// 开启高度自适应（内容增加时自动撑高，配合 Auto Layout 使用）
    /// - Parameter maxHeight: 最大高度限制，超出后变为可滚动，nil 表示不限
    func enableAutoHeight(maxHeight: CGFloat? = nil) {
        isScrollEnabled = false
        if let max = maxHeight {
            objc_setAssociatedObject(self, &AssociatedKeys.maxHeight,
                                     max, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_tv_autoHeight),
            name: UITextView.textDidChangeNotification,
            object: self
        )
    }
 
    // MARK: 光标处理
 
    /// 将光标移到文字末尾
    func moveCursorToEnd() {
        DispatchQueue.main.async {
            let end = self.endOfDocument
            self.selectedTextRange = self.textRange(from: end, to: end)
        }
    }
 
    /// 将光标移到文字开头
    func moveCursorToBeginning() {
        DispatchQueue.main.async {
            let start = self.beginningOfDocument
            self.selectedTextRange = self.textRange(from: start, to: start)
        }
    }
 
    /// 获取当前光标位置偏移量
    var cursorOffset: Int {
        guard let range = selectedTextRange else { return 0 }
        return offset(from: beginningOfDocument, to: range.start)
    }
 
    /// 滚动到光标可见位置
    func scrollToCursor() {
        DispatchQueue.main.async {
            guard let range = self.selectedTextRange else { return }
            let rect = self.caretRect(for: range.end)
            self.scrollRectToVisible(rect, animated: false)
        }
    }
 
    // MARK: 私有 — placeholder label 管理
 
    private var placeholderLabel: UILabel? {
        objc_getAssociatedObject(self, &AssociatedKeys.placeholderLabel) as? UILabel
    }
 
    private func ensurePlaceholderLabel() {
        guard placeholderLabel == nil else { return }
 
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.black.withAlphaComponent(0.3)
        label.font = font ?? .regular(14)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
 
        // 和 textView 的文字区域对齐（考虑 textContainerInset）
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor,
                constant: textContainerInset.top),
            label.leadingAnchor.constraint(equalTo: leadingAnchor,
                constant: textContainerInset.left + textContainer.lineFragmentPadding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor,
                constant: -(textContainerInset.right + textContainer.lineFragmentPadding)),
        ])
 
        objc_setAssociatedObject(self, &AssociatedKeys.placeholderLabel,
                                 label, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
 
        // 监听文字变化同步显示/隐藏
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_tv_updatePlaceholder),
            name: UITextView.textDidChangeNotification,
            object: self
        )
        
        addObserver(self, forKeyPath: #keyPath(UITextView.text),
                    options: [.new], context: nil)
        addObserver(self, forKeyPath: #keyPath(UITextView.attributedText),
                    options: [.new], context: nil)
    }
    
    public override func observeValue(forKeyPath keyPath: String?,
                                      of object: Any?,
                                      change: [NSKeyValueChangeKey: Any]?,
                                      context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(UITextView.text) ||
            keyPath == #keyPath(UITextView.attributedText) {
            _tv_updatePlaceholder()
            _tv_limitLength()
        } else {
            super.observeValue(forKeyPath: keyPath, of: object,
                               change: change, context: context)
        }
    }
    
    @objc private func _tv_updatePlaceholder() {
        placeholderLabel?.isHidden = !(text?.isEmpty ?? true)
    }
 
    // MARK: 私有 — 输入限制
 
    @objc private func _tv_limitLength() {
        guard let max = objc_getAssociatedObject(self,
                        &AssociatedKeys.maxLength) as? Int,
              let text = self.text
        else { return }
        
        if markedTextRange != nil { return }
        
        guard text.count > max else { return }
        
        let index = text.index(text.startIndex, offsetBy: max)
        self.text = String(text[..<index])
        moveCursorToEnd()
        _tv_updatePlaceholder()
    }
 
    @objc private func _tv_filterEmoji() {
        guard let text = self.text else { return }
        let filtered = text.unicodeScalars
            .filter { !CharacterSet.emoji.contains($0) }
        let result = String(String.UnicodeScalarView(filtered))
        if result != text {
            let offset = cursorOffset - (text.count - result.count)
            self.text = result
            // 光标归位
            if let pos = position(from: beginningOfDocument,
                                  offset: max(0, offset)) {
                selectedTextRange = textRange(from: pos, to: pos)
            }
            _tv_updatePlaceholder()
        }
    }
 
    // MARK: 私有 — 高度自适应
 
    @objc private func _tv_autoHeight() {
        let maxH = objc_getAssociatedObject(self,
                   &AssociatedKeys.maxHeight) as? CGFloat
 
        let fitsSize = sizeThatFits(CGSize(width: bounds.width,
                                          height: CGFloat.greatestFiniteMagnitude))
        if let max = maxH, fitsSize.height >= max {
            isScrollEnabled = true
        } else {
            isScrollEnabled = false
            invalidateIntrinsicContentSize()
        }
    }
}
 
// MARK: ========================================
// MARK: - 私有：AssociatedKeys & CharacterSet
// MARK: ========================================
 
private enum AssociatedKeys {
    static var maxLength          = "maxLength"
    static var allowedCharacterSet = "allowedCharacterSet"
    static var placeholderLabel   = "placeholderLabel"
    static var maxHeight          = "maxHeight"
}
 
private extension CharacterSet {
    /// emoji 字符集
    static var emoji: CharacterSet {
        var set = CharacterSet()
        // Emoticons、Misc Symbols、Supplemental Symbols、Transport、Enclosed
        set.insert(charactersIn: "\u{1F600}"..."\u{1F64F}")
        set.insert(charactersIn: "\u{1F300}"..."\u{1F5FF}")
        set.insert(charactersIn: "\u{1F680}"..."\u{1F6FF}")
        set.insert(charactersIn: "\u{1F900}"..."\u{1F9FF}")
        set.insert(charactersIn: "\u{2600}"..."\u{26FF}" )
        set.insert(charactersIn: "\u{2700}"..."\u{27BF}" )
        set.insert(charactersIn: "\u{FE00}"..."\u{FE0F}" )  // variation selectors
        set.insert(charactersIn: "\u{1FA00}"..."\u{1FA6F}")
        set.insert(charactersIn: "\u{1FA70}"..."\u{1FAFF}")
        return set
    }
}
