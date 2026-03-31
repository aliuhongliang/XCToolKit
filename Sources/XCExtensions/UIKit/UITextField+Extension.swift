import UIKit
 
// MARK: ========================================
// MARK: - 1. UITextField
// MARK: ========================================
 
public extension UITextField {
 
    // MARK: Placeholder 样式
 
    /// 设置 placeholder 文字及颜色
    func setPlaceholder(_ text: String,
                        color: UIColor = UIColor.black.withAlphaComponent(0.3),
                        font: UIFont? = nil) {
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: font ?? self.font ?? UIFont.regular(14)
        ]
        attributedPlaceholder = NSAttributedString(string: text, attributes: attrs)
    }
 
    // MARK: 输入限制
 
    /// 绑定最大输入长度限制（中文/emoji 安全截断，基于 shouldChangeCharactersIn）
    /// 用法：在 viewDidLoad 调用，内部自动注册通知
    func limitLength(_ maxLength: Int) {
        objc_setAssociatedObject(self, &AssociatedKeys.maxLength,
                                 maxLength, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(self, action: #selector(_tf_limitLength),
                  for: .editingChanged)
    }
 
    /// 限制只能输入指定字符集
    /// - Parameter set: 允许输入的字符集，例如 .decimalDigits / .letters
    func limitCharacters(in set: CharacterSet) {
        objc_setAssociatedObject(self, &AssociatedKeys.allowedCharacterSet,
                                 set, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(self, action: #selector(_tf_limitCharacters),
                  for: .editingChanged)
    }
 
    /// 禁止输入 emoji
    func disableEmoji() {
        limitCharacters(in: CharacterSet.emoji.inverted)
    }
 
    /// 当前已输入字符数（按字符计，非字节）
    var characterCount: Int {
        text?.count ?? 0
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
 
    /// 移动光标到指定位置（offset 从 0 开始）
    func moveCursor(to offset: Int) {
        DispatchQueue.main.async {
            guard let pos = self.position(from: self.beginningOfDocument,
                                          offset: offset) else { return }
            self.selectedTextRange = self.textRange(from: pos, to: pos)
        }
    }
 
    /// 获取当前光标位置（从文字起始算的偏移量）
    var cursorOffset: Int {
        guard let range = selectedTextRange else { return 0 }
        return offset(from: beginningOfDocument, to: range.start)
    }
 
    // MARK: 快捷配置
 
    /// 链式配置：字体
    @discardableResult
    func font(_ font: UIFont) -> Self {
        self.font = font
        return self
    }
 
    /// 链式配置：文字颜色
    @discardableResult
    func textColor(_ color: UIColor) -> Self {
        self.textColor = color
        return self
    }
 
    /// 链式配置：对齐方式
    @discardableResult
    func alignment(_ alignment: NSTextAlignment) -> Self {
        self.textAlignment = alignment
        return self
    }
 
    /// 链式配置：键盘类型
    @discardableResult
    func keyboardType(_ type: UIKeyboardType) -> Self {
        self.keyboardType = type
        return self
    }
 
    /// 链式配置：returnKey 类型
    @discardableResult
    func returnKeyType(_ type: UIReturnKeyType) -> Self {
        self.returnKeyType = type
        return self
    }
 
    /// 链式配置：密码输入
    @discardableResult
    func secureEntry(_ secure: Bool = true) -> Self {
        self.isSecureTextEntry = secure
        return self
    }
 
    /// 链式配置：clearButton 显示模式
    @discardableResult
    func clearButtonMode(_ mode: UITextField.ViewMode) -> Self {
        self.clearButtonMode = mode
        return self
    }
 
    /// 左侧内边距（常用于搜索框、输入框留白）
    func setLeftPadding(_ padding: CGFloat) {
        leftView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: frame.height))
        leftViewMode = .always
    }
 
    /// 右侧内边距
    func setRightPadding(_ padding: CGFloat) {
        rightView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: frame.height))
        rightViewMode = .always
    }
 
    /// 同时设置左右内边距
    func setPadding(horizontal: CGFloat) {
        setLeftPadding(horizontal)
        setRightPadding(horizontal)
    }
 
    // MARK: 私有实现
 
    @objc private func _tf_limitLength() {
        guard let max = objc_getAssociatedObject(self, &AssociatedKeys.maxLength) as? Int,
              let text = self.text
        else { return }
        
        if markedTextRange != nil { return }
        
        guard text.count > max else { return }
 
        // 安全截断：避免截断 emoji / 多字节字符
        let index = text.index(text.startIndex, offsetBy: max)
        self.text = String(text[..<index])
 
        // 截断后光标归位末尾，避免光标跳动
        moveCursorToEnd()
 
        // 触发 editingChanged 让外部监听者感知到值变化
        sendActions(for: .editingChanged)
    }
 
    @objc private func _tf_limitCharacters() {
        guard let set = objc_getAssociatedObject(self,
                        &AssociatedKeys.allowedCharacterSet) as? CharacterSet,
              let text = self.text
        else { return }
 
        let filtered = text.unicodeScalars
            .filter { set.contains($0) }
        let result = String(String.UnicodeScalarView(filtered))
 
        if result != text {
            let offset = cursorOffset - (text.count - result.count)
            self.text = result
            moveCursor(to: max(0, offset))
            sendActions(for: .editingChanged)
        }
    }
}

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
