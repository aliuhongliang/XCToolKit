import UIKit
 
// MARK: ========================================
// MARK: - 1. UIView Extension
// MARK: ========================================
 
public extension UIView {
 
    // MARK: 尺寸 / 位置快捷属性
 
    var x: CGFloat {
        get { frame.origin.x }
        set { frame.origin.x = newValue }
    }
 
    var y: CGFloat {
        get { frame.origin.y }
        set { frame.origin.y = newValue }
    }
 
    var width: CGFloat {
        get { frame.size.width }
        set { frame.size.width = newValue }
    }
 
    var height: CGFloat {
        get { frame.size.height }
        set { frame.size.height = newValue }
    }
 
    var top: CGFloat {
        get { frame.minY }
        set { frame.origin.y = newValue }
    }
 
    var bottom: CGFloat {
        get { frame.maxY }
        set { frame.origin.y = newValue - frame.height }
    }
 
    var left: CGFloat {
        get { frame.minX }
        set { frame.origin.x = newValue }
    }
 
    var right: CGFloat {
        get { frame.maxX }
        set { frame.origin.x = newValue - frame.width }
    }
 
    var centerX: CGFloat {
        get { center.x }
        set { center.x = newValue }
    }
 
    var centerY: CGFloat {
        get { center.y }
        set { center.y = newValue }
    }
 
    var size: CGSize {
        get { frame.size }
        set { frame.size = newValue }
    }
 
    var origin: CGPoint {
        get { frame.origin }
        set { frame.origin = newValue }
    }
 
    // MARK: 截图
 
    /// 将当前视图渲染为 UIImage
    func snapshot() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        return UIGraphicsImageRenderer(size: bounds.size, format: format).image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
 
    // MARK: 查找父子视图
 
    /// 找到第一个指定类型的子视图（深度优先）
    func firstSubview<T: UIView>(of type: T.Type) -> T? {
        for subview in subviews {
            if let target = subview as? T { return target }
            if let found = subview.firstSubview(of: type) { return found }
        }
        return nil
    }
 
    /// 找到指定类型的父视图
    func parentView<T: UIView>(of type: T.Type) -> T? {
        var current = superview
        while let view = current {
            if let target = view as? T { return target }
            current = view.superview
        }
        return nil
    }
 
    // MARK: 手势快捷添加
 
    /// 添加单击手势
    @discardableResult
    func addTapGesture(numberOfTaps: Int = 1,
                       handler: @escaping () -> Void) -> UITapGestureRecognizer {
        isUserInteractionEnabled = true
        let gesture = ClosureTapGesture(handler: handler)
        gesture.numberOfTapsRequired = numberOfTaps
        addGestureRecognizer(gesture)
        return gesture
    }
 
    /// 添加长按手势
    @discardableResult
    func addLongPressGesture(minimumDuration: TimeInterval = 0.5,
                              handler: @escaping () -> Void) -> UILongPressGestureRecognizer {
        isUserInteractionEnabled = true
        let gesture = ClosureLongPressGesture(handler: handler)
        gesture.minimumPressDuration = minimumDuration
        addGestureRecognizer(gesture)
        return gesture
    }
 
    // MARK: 模糊效果
 
    /// 添加毛玻璃效果
    /// - Parameter style: 模糊风格，默认 .regular
    func addBlur(style: UIBlurEffect.Style = .regular) {
        removeBlur()
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: style))
        blur.frame = bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blur.tag = ViewTags.blur
        insertSubview(blur, at: 0)
    }
 
    /// 移除毛玻璃效果
    func removeBlur() {
        viewWithTag(ViewTags.blur)?.removeFromSuperview()
    }
 
    // MARK: 简单圆角 / 边框
    // 适用于无需指定角、无组合阴影需求的轻量场景
    // 需要组合阴影或指定角时，请使用 HLView
 
    /// 设置全圆角
    func setCornerRadius(_ radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }
 
    /// 设置边框
    func setBorder(color: UIColor, width: CGFloat = 1) {
        layer.borderColor = color.cgColor
        layer.borderWidth = width
    }
}
 
// MARK: - 手势闭包封装（私有）
 
private final class ClosureTapGesture: UITapGestureRecognizer {
    private let handler: () -> Void
    init(handler: @escaping () -> Void) {
        self.handler = handler
        super.init(target: nil, action: nil)
        addTarget(self, action: #selector(invoke))
    }
    @objc private func invoke() { handler() }
}
 
private final class ClosureLongPressGesture: UILongPressGestureRecognizer {
    private let handler: () -> Void
    init(handler: @escaping () -> Void) {
        self.handler = handler
        super.init(target: nil, action: nil)
        addTarget(self, action: #selector(invoke))
    }
    @objc private func invoke() {
        if state == .began { handler() }
    }
}
 
private enum ViewTags {
    static let blur = 99_001
}
