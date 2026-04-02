import UIKit

// MARK: - VerticalDirection

public enum HLVerticalSliderDirection {
    /// 默认：底部 = minimumValue，顶部 = maximumValue
    case bottomToTop
    /// 顶部 = minimumValue，底部 = maximumValue
    case topToBottom
}

// MARK: - HLVerticalSlider

/// 垂直方向滑块
/// - 内部持有一个 HLSlider，通过 transform 旋转实现垂直布局
/// - 修正触摸坐标，对外暴露与 HLSlider 相同的配置接口
open class HLVerticalSlider: UIView {

    // MARK: - Public Properties

    /// 方向，默认 bottomToTop
    public var direction: HLVerticalSliderDirection = .bottomToTop {
        didSet { applyDirection() }
    }

    public var minimumValue: Float {
        get { innerSlider.minimumValue }
        set { innerSlider.minimumValue = newValue }
    }

    public var maximumValue: Float {
        get { innerSlider.maximumValue }
        set { innerSlider.maximumValue = newValue }
    }

    public var value: Float {
        get { innerSlider.value }
        set { innerSlider.value = newValue }
    }

    public func setValue(_ value: Float, animated: Bool) {
        innerSlider.setValue(value, animated: animated)
    }

    public var isContinuous: Bool {
        get { innerSlider.isContinuous }
        set { innerSlider.isContinuous = newValue }
    }

    // MARK: - Config 透传

    public var trackConfig: HLSliderTrackConfig? {
        get { innerSlider.trackConfig }
        set { innerSlider.trackConfig = newValue }
    }

    public var thumbConfig: HLSliderThumbConfig? {
        get { innerSlider.thumbConfig }
        set { innerSlider.thumbConfig = newValue }
    }

    public var stepConfig: HLSliderStepConfig? {
        get { innerSlider.stepConfig }
        set { innerSlider.stepConfig = newValue }
    }

    /// 注意：垂直模式下浮动 label 自动偏移方向为左侧（thumb 左边）
    public var labelConfig: HLSliderLabelConfig? {
        get { innerSlider.labelConfig }
        set { innerSlider.labelConfig = newValue }
    }

    // MARK: - Target / Action 透传

    public func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        innerSlider.addTarget(target, action: action, for: controlEvents)
    }

    public func removeTarget(_ target: Any?, action: Selector?, for controlEvents: UIControl.Event) {
        innerSlider.removeTarget(target, action: action, for: controlEvents)
    }

    // MARK: - Inner Slider

    public private(set) lazy var innerSlider: HLSlider = {
        let s = HLSlider()
        return s
    }()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        addSubview(innerSlider)
        applyDirection()
    }

    // MARK: - Layout

    open override func layoutSubviews() {
        super.layoutSubviews()
        // 旋转后 slider 的宽度 = 容器高度，高度 = 容器宽度
        let sliderWidth = bounds.height
        let sliderHeight = bounds.width
        innerSlider.bounds = CGRect(x: 0, y: 0, width: sliderWidth, height: sliderHeight)
        innerSlider.center = CGPoint(x: bounds.midX, y: bounds.midY)
        applyDirection()
    }

    private func applyDirection() {
        switch direction {
        case .bottomToTop:
            // 逆时针 90°：slider 的 maxX（右端）对应视图底部
            innerSlider.transform = CGAffineTransform(rotationAngle: -.pi / 2)
        case .topToBottom:
            // 顺时针 90°：slider 的 minX（左端）对应视图底部
            innerSlider.transform = CGAffineTransform(rotationAngle: .pi / 2)
        }
    }

    // MARK: - Intrinsic Content Size

    open override var intrinsicContentSize: CGSize {
        // 垂直模式下宽度给 thumb 直径，高度自适应
        let thumbDiam = thumbConfig?.diameter ?? 22
        return CGSize(width: thumbDiam + 16, height: UIView.noIntrinsicMetric)
    }
}
