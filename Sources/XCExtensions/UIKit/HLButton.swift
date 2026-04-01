import UIKit
 
// MARK: ========================================
// MARK: - 1. HLButton
// MARK: ========================================
 
/// 支持图文布局 + 状态样式管理的 UIButton 子类
open class HLButton: UIButton {
 
    // MARK: 图文布局
 
    /// 图文排列方式
    public enum ImagePosition {
        case left       // 图左文右（系统默认）
        case right      // 图右文左
        case top        // 图上文下
        case bottom     // 图下文上
    }
 
    /// 图文间距
    public var imageSpacing: CGFloat = 4 {
        didSet { setNeedsLayout() }
    }
 
    /// 图文排列方向
    public var imagePosition: ImagePosition = .left {
        didSet { setNeedsLayout() }
    }
 
    // MARK: 状态样式
 
    /// 各状态背景色
    private var backgroundColors: [UInt: UIColor] = [:]
 
    /// 各状态边框色
    private var borderColors: [UInt: UIColor] = [:]
 
    /// 各状态边框宽度（统一）
    public var borderWidth: CGFloat = 0 {
        didSet { layer.borderWidth = borderWidth }
    }
 
    /// 高亮时自动降低透明度（默认 true，关闭后完全由 backgroundColors 控制）
    public var adjustsAlphaWhenHighlighted: Bool = false
 
    // MARK: 状态 override
 
    open override var isHighlighted: Bool {
        didSet {
            applyStateStyles()
            if adjustsAlphaWhenHighlighted && backgroundColors[UIControl.State.highlighted.rawValue] == nil {
                alpha = isHighlighted ? 0.6 : 1.0
            }
        }
    }
 
    open override var isSelected: Bool {
        didSet { applyStateStyles() }
    }
 
    open override var isEnabled: Bool {
        didSet { applyStateStyles() }
    }
 
    // MARK: Init
 
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
 
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
 
    open func setup() {}
 
    // MARK: 状态样式设置
 
    /// 设置指定状态的背景色
    public func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        backgroundColors[state.rawValue] = color
        applyStateStyles()
    }
 
    /// 设置指定状态的边框色
    public func setBorderColor(_ color: UIColor, for state: UIControl.State) {
        borderColors[state.rawValue] = color
        applyStateStyles()
    }
 
    private func applyStateStyles() {
        // 按优先级查找：当前精确状态 → .normal 兜底
        let stateKey = state.rawValue
        if let bg = backgroundColors[stateKey] ?? backgroundColors[UIControl.State.normal.rawValue] {
            backgroundColor = bg
        }
        if let border = borderColors[stateKey] ?? borderColors[UIControl.State.normal.rawValue] {
            layer.borderColor = border.cgColor
        }
    }
 
    // MARK: 图文布局
 
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard imagePosition != .left else { return }  // .left 是系统默认，不干预
        layoutImageAndTitle()
    }
 
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let imageSize  = imageView?.intrinsicContentSize  ?? .zero
        let titleSize  = titleLabel?.intrinsicContentSize ?? .zero
        let spacing    = (imageSize == .zero || titleSize == .zero) ? 0 : imageSpacing
 
        switch imagePosition {
        case .left, .right:
            return CGSize(
                width:  imageSize.width + spacing + titleSize.width,
                height: max(imageSize.height, titleSize.height)
            )
        case .top, .bottom:
            return CGSize(
                width:  max(imageSize.width, titleSize.width),
                height: imageSize.height + spacing + titleSize.height
            )
        }
    }
 
    private func layoutImageAndTitle() {
        guard let imageView = imageView, let titleLabel = titleLabel else { return }
 
        let imageSize = imageView.intrinsicContentSize
        let titleSize = titleLabel.intrinsicContentSize
        let spacing   = (imageSize == .zero || titleSize == .zero) ? 0 : imageSpacing
        let totalW    = bounds.width
        let totalH    = bounds.height
 
        switch imagePosition {
 
        case .left:
            break   // 系统处理，不到这里
 
        case .right:
            // 图右文左
            let totalWidth = imageSize.width + spacing + titleSize.width
            let startX = (totalW - totalWidth) / 2
            titleLabel.frame = CGRect(
                x: startX,
                y: (totalH - titleSize.height) / 2,
                width: titleSize.width,
                height: titleSize.height
            )
            imageView.frame = CGRect(
                x: startX + titleSize.width + spacing,
                y: (totalH - imageSize.height) / 2,
                width: imageSize.width,
                height: imageSize.height
            )
 
        case .top:
            // 图上文下
            let totalHeight = imageSize.height + spacing + titleSize.height
            let startY = (totalH - totalHeight) / 2
            imageView.frame = CGRect(
                x: (totalW - imageSize.width) / 2,
                y: startY,
                width: imageSize.width,
                height: imageSize.height
            )
            titleLabel.frame = CGRect(
                x: (totalW - titleSize.width) / 2,
                y: startY + imageSize.height + spacing,
                width: titleSize.width,
                height: titleSize.height
            )
 
        case .bottom:
            // 图下文上
            let totalHeight = imageSize.height + spacing + titleSize.height
            let startY = (totalH - totalHeight) / 2
            titleLabel.frame = CGRect(
                x: (totalW - titleSize.width) / 2,
                y: startY,
                width: titleSize.width,
                height: titleSize.height
            )
            imageView.frame = CGRect(
                x: (totalW - imageSize.width) / 2,
                y: startY + titleSize.height + spacing,
                width: imageSize.width,
                height: imageSize.height
            )
        }
    }
}
