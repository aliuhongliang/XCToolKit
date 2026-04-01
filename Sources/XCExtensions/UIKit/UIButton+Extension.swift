import UIKit

// MARK: ========================================
// MARK: - 2. UIButton Extension
// MARK: ========================================
 
public extension UIButton {
 
    // MARK: 工厂方法
 
    /// 快速创建文字按钮
    static func make(
        title: String,
        font: UIFont = .regular(15),
        color: UIColor = .black,
        backgroundColor: UIColor = .clear,
        target: Any? = nil,
        action: Selector? = nil
    ) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(color, for: .normal)
        btn.titleLabel?.font = font
        btn.backgroundColor = backgroundColor
        if let target, let action {
            btn.addTarget(target, action: action, for: .touchUpInside)
        }
        return btn
    }
 
    /// 快速创建图标按钮
    static func make(
        image: UIImage?,
        selectedImage: UIImage? = nil,
        tintColor: UIColor? = nil,
        target: Any? = nil,
        action: Selector? = nil
    ) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.setImage(image?.withRenderingMode(tintColor == nil ? .alwaysOriginal : .alwaysTemplate),
                     for: .normal)
        if let selected = selectedImage {
            btn.setImage(selected.withRenderingMode(tintColor == nil ? .alwaysOriginal : .alwaysTemplate),
                         for: .selected)
        }
        if let tint = tintColor { btn.tintColor = tint }
        if let target, let action {
            btn.addTarget(target, action: action, for: .touchUpInside)
        }
        return btn
    }
 
    /// 快速创建图文按钮（基于 HLButton）
    static func make(
        title: String,
        image: UIImage?,
        font: UIFont = .regular(15),
        color: UIColor = .black,
        imagePosition: HLButton.ImagePosition = .left,
        imageSpacing: CGFloat = 4,
        target: Any? = nil,
        action: Selector? = nil
    ) -> HLButton {
        let btn = HLButton(type: .custom)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(color, for: .normal)
        btn.titleLabel?.font = font
        btn.setImage(image, for: .normal)
        btn.imagePosition = imagePosition
        btn.imageSpacing = imageSpacing
        if let target, let action {
            btn.addTarget(target, action: action, for: .touchUpInside)
        }
        return btn
    }
 
    // MARK: 点击区域扩展
 
    /// 扩展点击区域（负值向外扩展，正值向内收缩）
    /// 示例：button.hitTestInset = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
    var hitTestInset: UIEdgeInsets {
        get { objc_getAssociatedObject(self, &AssociatedKeys.hitTestInset)
                as? UIEdgeInsets ?? .zero }
        set { objc_setAssociatedObject(self, &AssociatedKeys.hitTestInset,
                                       newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
              // 激活 swizzle
              _ = UIButton.swizzlePointInsideOnce
        }
    }
 
    /// 快捷设置四周相同的扩展量
    func expandHitTest(by inset: CGFloat) {
        hitTestInset = UIEdgeInsets(top: -inset, left: -inset,
                                    bottom: -inset, right: -inset)
    }
 
    // MARK: 防连点
 
    /// 防连点间隔（秒），默认 0 表示不限制
    var throttleInterval: TimeInterval {
        get { objc_getAssociatedObject(self, &AssociatedKeys.throttleInterval)
                as? TimeInterval ?? 0 }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.throttleInterval,
                                     newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            guard newValue > 0 else { return }
            _ = UIButton.swizzleSendActionOnce
        }
    }
 
    // MARK: Swizzle — point(inside:with:)
 
    fileprivate static let swizzlePointInsideOnce: Void = {
        guard
            let original = class_getInstanceMethod(UIButton.self,
                           #selector(point(inside:with:))),
            let swizzled = class_getInstanceMethod(UIButton.self,
                           #selector(_swizzled_point(inside:with:)))
        else { return }
        method_exchangeImplementations(original, swizzled)
    }()
 
    @objc private func _swizzled_point(inside point: CGPoint,
                                       with event: UIEvent?) -> Bool {
        // 隐藏、禁用、近乎透明时走系统默认逻辑，不扩展点击区域
        if isHidden || !isEnabled || alpha < 0.01 {
            return _swizzled_point(inside: point, with: event)
        }
        let inset = hitTestInset
        guard inset != .zero else {
            return _swizzled_point(inside: point, with: event)
        }
        let expanded = bounds.inset(by: inset)
        return expanded.contains(point)
    }
 
    // MARK: Swizzle — sendAction（防连点）
 
    fileprivate static let swizzleSendActionOnce: Void = {
        guard
            let original = class_getInstanceMethod(UIButton.self,
                           #selector(sendAction(_:to:for:))),
            let swizzled = class_getInstanceMethod(UIButton.self,
                           #selector(_swizzled_sendAction(_:to:for:)))
        else { return }
        method_exchangeImplementations(original, swizzled)
    }()
 
    @objc private func _swizzled_sendAction(_ action: Selector,
                                             to target: Any?,
                                             for event: UIEvent?) {
        let interval = throttleInterval
        guard interval > 0 else {
            _swizzled_sendAction(action, to: target, for: event)
            return
        }
        // 检查是否在冷却期
        let isThrottling = objc_getAssociatedObject(self,
                           &AssociatedKeys.isThrottling) as? Bool ?? false
        guard !isThrottling else { return }
 
        _swizzled_sendAction(action, to: target, for: event)
 
        // 进入冷却
        objc_setAssociatedObject(self, &AssociatedKeys.isThrottling,
                                 true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak self] in
            objc_setAssociatedObject(self, &AssociatedKeys.isThrottling,
                                     false, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
 
// MARK: ========================================
// MARK: - 私有：AssociatedKeys
// MARK: ========================================
 
private enum AssociatedKeys {
    static var hitTestInset    = "hitTestInset"
    static var throttleInterval = "throttleInterval"
    static var isThrottling    = "isThrottling"
}
