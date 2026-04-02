import UIKit

/// 单滑块封装，支持自定义外观、离散步进、浮动标签，按需组合，互不干扰。
///
/// 基本用法：
/// ```swift
/// let slider = HLSlider()
/// slider.minimumValue = 0
/// slider.maximumValue = 100
///
/// // 自定义轨道
/// slider.trackConfig = HLSliderTrackConfig(height: 6, minimumTrackColor: .systemBlue)
///
/// // 步进（可选）
/// slider.stepConfig = HLSliderStepConfig(step: 10, showTickMarks: true)
///
/// // 浮动标签（可选）
/// slider.labelConfig = HLSliderLabelConfig(formatter: { "\(Int($0))%" })
/// ```
open class HLSlider: UISlider {

    // MARK: - Public Config

    /// 轨道外观，nil 时使用系统默认
    public var trackConfig: HLSliderTrackConfig? {
        didSet { applyTrackConfig() }
    }

    /// Thumb 外观，nil 时使用系统默认
    public var thumbConfig: HLSliderThumbConfig? {
        didSet { applyThumbConfig() }
    }

    /// 步进配置，nil 时为连续滑动
    public var stepConfig: HLSliderStepConfig? {
        didSet { updateTickMarks() }
    }

    /// 浮动标签配置，nil 时不显示标签
    public var labelConfig: HLSliderLabelConfig? {
        didSet { applyLabelConfig() }
    }

    // MARK: - Private Views

    /// 自定义轨道视图（覆盖在系统 track 上方）
    private let customTrackView = UIView()
    private let customMinTrackView = UIView()

    /// 刻度点容器
    private let tickMarkContainer = UIView()

    /// 浮动标签
    private let floatingLabel = UILabel()

    /// 标签是否正在显示（用于 hidesWhenIdle 动画）
    private var isLabelVisible = false

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
        // 添加自定义 track 层（插在 slider 最下方）
        insertSubview(customTrackView, at: 0)
        customTrackView.isUserInteractionEnabled = false
        customTrackView.addSubview(customMinTrackView)

        // 刻度点层
        addSubview(tickMarkContainer)
        tickMarkContainer.isUserInteractionEnabled = false

        // 浮动 label（加在父视图，避免被 slider bounds 裁剪）
        // 延迟到 didMoveToSuperview 再添加
        floatingLabel.textAlignment = .center
        floatingLabel.isHidden = true

        addTarget(self, action: #selector(valueDidChange), for: .valueChanged)
        addTarget(self, action: #selector(touchBegan), for: .touchDown)
        addTarget(self, action: #selector(touchEnded), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    // MARK: - Superview

    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        superview?.addSubview(floatingLabel)
    }

    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            floatingLabel.removeFromSuperview()
        }
    }

    // MARK: - Layout

    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutCustomTrack()
        layoutTickMarks()
        layoutFloatingLabel()
    }

    // MARK: - Track Rect Override

    open override func trackRect(forBounds bounds: CGRect) -> CGRect {
        guard let config = trackConfig else {
            return super.trackRect(forBounds: bounds)
        }
        let defaultRect = super.trackRect(forBounds: bounds)
        return CGRect(
            x: defaultRect.minX,
            y: bounds.midY - config.height / 2,
            width: defaultRect.width,
            height: config.height
        )
    }

    // MARK: - Thumb Rect Override

    open override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        guard let config = thumbConfig else {
            return super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        }
        let defaultRect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        let centerX = defaultRect.midX
        let centerY = bounds.midY
        return CGRect(
            x: centerX - config.diameter / 2,
            y: centerY - config.diameter / 2,
            width: config.diameter,
            height: config.diameter
        )
    }

    // MARK: - Apply Track Config

    private func applyTrackConfig() {
        guard let config = trackConfig else {
            customTrackView.isHidden = true
            setNeedsLayout()
            return
        }
        customTrackView.isHidden = false

        let radius = config.cornerRadius ?? (config.height / 2)
        customTrackView.layer.cornerRadius = radius
        customTrackView.backgroundColor = config.maximumTrackColor ?? UIColor.systemGray4

        customMinTrackView.layer.cornerRadius = radius
        customMinTrackView.backgroundColor = config.minimumTrackColor ?? tintColor

        // 隐藏系统 track（通过透明图片）
        let clearImage = UIImage()
        setMinimumTrackImage(clearImage, for: .normal)
        setMaximumTrackImage(clearImage, for: .normal)

        setNeedsLayout()
    }

    private func layoutCustomTrack() {
        guard let config = trackConfig, !customTrackView.isHidden else { return }

        let trackRect = self.trackRect(forBounds: bounds)
        customTrackView.frame = CGRect(
            x: trackRect.minX,
            y: bounds.midY - config.height / 2,
            width: trackRect.width,
            height: config.height
        )

        // minTrack 宽度按当前 value 百分比
        let percent = CGFloat((value - minimumValue) / (maximumValue - minimumValue))
        customMinTrackView.frame = CGRect(
            x: 0,
            y: 0,
            width: customTrackView.bounds.width * percent,
            height: config.height
        )
    }

    // MARK: - Apply Thumb Config

    private func applyThumbConfig() {
        guard let config = thumbConfig else {
            setThumbImage(nil, for: .normal)
            setThumbImage(nil, for: .highlighted)
            return
        }
        let image = makeThumbImage(config: config, highlighted: false)
        let highlightedImage = makeThumbImage(config: config, highlighted: true)
        setThumbImage(image, for: .normal)
        setThumbImage(highlightedImage, for: .highlighted)
    }

    private func makeThumbImage(config: HLSliderThumbConfig, highlighted: Bool) -> UIImage {
        let size = CGSize(width: config.diameter, height: config.diameter)
        let scale = UIScreen.main.scale
        // 留出阴影空间
        let shadowPadding: CGFloat = (config.shadowColor != nil) ? config.shadowRadius + abs(config.shadowOffset.height) + 2 : 0
        let canvasSize = CGSize(
            width: size.width + shadowPadding * 2,
            height: size.height + shadowPadding * 2
        )

        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }

        guard let ctx = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }

        // 阴影
        if let shadowColor = config.shadowColor {
            ctx.setShadow(
                offset: config.shadowOffset,
                blur: config.shadowRadius,
                color: shadowColor.cgColor
            )
        }

        let fillColor = highlighted
            ? config.fillColor.withAlphaComponent(0.85)
            : config.fillColor

        let circleRect = CGRect(
            x: shadowPadding,
            y: shadowPadding,
            width: size.width,
            height: size.height
        )

        ctx.setFillColor(fillColor.cgColor)
        ctx.fillEllipse(in: circleRect)

        // 边框
        if let borderColor = config.borderColor, config.borderWidth > 0 {
            ctx.setShadow(offset: .zero, blur: 0, color: nil) // 关闭阴影再画边框
            ctx.setStrokeColor(borderColor.cgColor)
            ctx.setLineWidth(config.borderWidth)
            ctx.strokeEllipse(in: circleRect.insetBy(dx: config.borderWidth / 2, dy: config.borderWidth / 2))
        }

        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        return image.withRenderingMode(.alwaysOriginal)
    }

    // MARK: - Tick Marks

    private func updateTickMarks() {
        tickMarkContainer.subviews.forEach { $0.removeFromSuperview() }
        guard let config = stepConfig, config.showTickMarks else {
            tickMarkContainer.isHidden = true
            return
        }
        tickMarkContainer.isHidden = false

        let range = maximumValue - minimumValue
        guard range > 0, config.step > 0 else { return }
        let count = Int(range / config.step) + 1

        for i in 0..<count {
            let dot = UIView()
            dot.backgroundColor = config.tickColor ?? UIColor.systemGray3
            dot.layer.cornerRadius = config.tickDiameter / 2
            tickMarkContainer.addSubview(dot)
            dot.tag = i
        }
        setNeedsLayout()
    }

    private func layoutTickMarks() {
        guard let config = stepConfig, config.showTickMarks else { return }

        let trackRect = self.trackRect(forBounds: bounds)
        tickMarkContainer.frame = trackRect

        let range = maximumValue - minimumValue
        guard range > 0 else { return }
        let count = Int(range / config.step) + 1

        for i in 0..<count {
            guard let dot = tickMarkContainer.viewWithTag(i) else { continue }
            let percent = CGFloat(Float(i) * config.step / range)
            let x = trackRect.width * percent
            let y = trackRect.height / 2
            dot.frame = CGRect(
                x: x - config.tickDiameter / 2,
                y: y - config.tickDiameter / 2,
                width: config.tickDiameter,
                height: config.tickDiameter
            )
        }
    }

    // MARK: - Apply Label Config

    private func applyLabelConfig() {
        guard let config = labelConfig else {
            floatingLabel.isHidden = true
            return
        }
        floatingLabel.font = config.font
        floatingLabel.textColor = config.textColor
        floatingLabel.backgroundColor = config.backgroundColor
        floatingLabel.layer.cornerRadius = config.cornerRadius
        floatingLabel.layer.masksToBounds = true

        if config.hidesWhenIdle {
            floatingLabel.isHidden = true
            isLabelVisible = false
        } else {
            floatingLabel.isHidden = false
            isLabelVisible = true
            updateFloatingLabel()
        }
    }

    private func updateFloatingLabel() {
        guard let config = labelConfig else { return }
        let text = config.formatter(value)
        floatingLabel.text = text

        // 计算 size
        let textSize = (text as NSString).boundingRect(
            with: CGSize(width: 200, height: 44),
            options: .usesLineFragmentOrigin,
            attributes: [.font: config.font],
            context: nil
        ).size
        let labelWidth = ceil(textSize.width) + config.contentInsets.left + config.contentInsets.right
        let labelHeight = ceil(textSize.height) + config.contentInsets.top + config.contentInsets.bottom
        floatingLabel.frame.size = CGSize(width: labelWidth, height: labelHeight)
    }

    private func layoutFloatingLabel() {
        guard let config = labelConfig, !floatingLabel.isHidden else { return }

        updateFloatingLabel()

        let trackRect = self.trackRect(forBounds: bounds)
        let thumbRect = self.thumbRect(forBounds: bounds, trackRect: trackRect, value: value)

        // 转换到父视图坐标
        guard let superview = superview else { return }
        let thumbCenter = convert(CGPoint(x: thumbRect.midX, y: thumbRect.minY), to: superview)

        floatingLabel.center = CGPoint(
            x: thumbCenter.x,
            y: thumbCenter.y - config.offset - floatingLabel.bounds.height / 2
        )
    }

    // MARK: - Value Change

    @objc private func valueDidChange() {
        // 步进吸附（实时）
        if let config = stepConfig, config.snapsInRealTime {
            snapToStep()
        }

        // 更新自定义 track 进度
        if trackConfig != nil {
            layoutCustomTrack()
        }

        // 更新浮动标签
        if labelConfig != nil {
            layoutFloatingLabel()
        }
    }

    @objc private func touchBegan() {
        guard let config = labelConfig, config.hidesWhenIdle else { return }
        showFloatingLabel()
    }

    @objc private func touchEnded() {
        // 步进吸附（松手）
        if let config = stepConfig, !config.snapsInRealTime {
            snapToStep()
        }

        // 隐藏标签
        if let config = labelConfig, config.hidesWhenIdle {
            hideFloatingLabel()
        }
    }

    private func snapToStep() {
        guard let config = stepConfig else { return }
        let step = config.step
        let snapped = round(value / step) * step
        let clamped = max(minimumValue, min(maximumValue, snapped))
        if value != clamped {
            setValue(clamped, animated: false)
            // 手动触发 valueChanged 让外部监听到最终吸附值
            sendActions(for: .valueChanged)
        }
    }

    // MARK: - Label Show / Hide Animation

    private func showFloatingLabel() {
        guard !isLabelVisible else { return }
        isLabelVisible = true
        floatingLabel.isHidden = false
        floatingLabel.alpha = 0
        floatingLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.floatingLabel.alpha = 1
            self.floatingLabel.transform = .identity
        }
    }

    private func hideFloatingLabel() {
        guard isLabelVisible else { return }
        isLabelVisible = false
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn) {
            self.floatingLabel.alpha = 0
            self.floatingLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        } completion: { _ in
            self.floatingLabel.isHidden = true
            self.floatingLabel.alpha = 1
            self.floatingLabel.transform = .identity
        }
    }
}



// MARK: - Track Config

/// 轨道外观配置
public struct HLSliderTrackConfig {
    /// 轨道高度，默认 4pt
    public var height: CGFloat
    /// minimum track 颜色，nil 则使用系统默认
    public var minimumTrackColor: UIColor?
    /// maximum track 颜色，nil 则使用系统默认
    public var maximumTrackColor: UIColor?
    /// 轨道圆角，nil 则自动使用 height / 2
    public var cornerRadius: CGFloat?

    public init(
        height: CGFloat = 4,
        minimumTrackColor: UIColor? = nil,
        maximumTrackColor: UIColor? = nil,
        cornerRadius: CGFloat? = nil
    ) {
        self.height = height
        self.minimumTrackColor = minimumTrackColor
        self.maximumTrackColor = maximumTrackColor
        self.cornerRadius = cornerRadius
    }
}

// MARK: - Thumb Config

/// Thumb 外观配置（纯色圆形，不依赖图片）
public struct HLSliderThumbConfig {
    /// Thumb 直径，默认 22pt
    public var diameter: CGFloat
    /// Thumb 填充色，默认白色
    public var fillColor: UIColor
    /// 边框颜色，nil 则无边框
    public var borderColor: UIColor?
    /// 边框宽度，默认 0
    public var borderWidth: CGFloat
    /// 阴影颜色，nil 则无阴影
    public var shadowColor: UIColor?
    /// 阴影偏移，默认 (0, 2)
    public var shadowOffset: CGSize
    /// 阴影半径，默认 4
    public var shadowRadius: CGFloat

    public init(
        diameter: CGFloat = 22,
        fillColor: UIColor = .white,
        borderColor: UIColor? = nil,
        borderWidth: CGFloat = 0,
        shadowColor: UIColor? = UIColor.black.withAlphaComponent(0.2),
        shadowOffset: CGSize = CGSize(width: 0, height: 2),
        shadowRadius: CGFloat = 4
    ) {
        self.diameter = diameter
        self.fillColor = fillColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.shadowColor = shadowColor
        self.shadowOffset = shadowOffset
        self.shadowRadius = shadowRadius
    }
}

// MARK: - Step Config

/// 离散步进配置
public struct HLSliderStepConfig {
    /// 步进值，必须 > 0
    public var step: Float
    /// true = 实时吸附（拖动中），false = 松手后吸附
    public var snapsInRealTime: Bool
    /// 是否显示刻度点
    public var showTickMarks: Bool
    /// 刻度点直径，默认 4pt
    public var tickDiameter: CGFloat
    /// 刻度点颜色，默认与 maximumTrack 一致
    public var tickColor: UIColor?

    public init(
        step: Float,
        snapsInRealTime: Bool = true,
        showTickMarks: Bool = false,
        tickDiameter: CGFloat = 4,
        tickColor: UIColor? = nil
    ) {
        precondition(step > 0, "HLSliderStepConfig: step must be > 0")
        self.step = step
        self.snapsInRealTime = snapsInRealTime
        self.showTickMarks = showTickMarks
        self.tickDiameter = tickDiameter
        self.tickColor = tickColor
    }
}

// MARK: - Label Config

/// 浮动标签配置（thumb 正上方实时显示当前值）
public struct HLSliderLabelConfig {
    /// 值格式化闭包，默认显示整数
    public var formatter: (Float) -> String
    /// label 距 thumb 顶部的间距，默认 8pt
    public var offset: CGFloat
    /// 字体
    public var font: UIFont
    /// 文字颜色
    public var textColor: UIColor
    /// 背景色，nil 则透明
    public var backgroundColor: UIColor?
    /// 内边距
    public var contentInsets: UIEdgeInsets
    /// 圆角
    public var cornerRadius: CGFloat
    /// 是否仅在拖动时显示（松手后隐藏）
    public var hidesWhenIdle: Bool

    public init(
        formatter: @escaping (Float) -> String = { "\(Int($0))" },
        offset: CGFloat = 8,
        font: UIFont = .systemFont(ofSize: 12, weight: .medium),
        textColor: UIColor = .white,
        backgroundColor: UIColor? = UIColor.black.withAlphaComponent(0.7),
        contentInsets: UIEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8),
        cornerRadius: CGFloat = 4,
        hidesWhenIdle: Bool = false
    ) {
        self.formatter = formatter
        self.offset = offset
        self.font = font
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.contentInsets = contentInsets
        self.cornerRadius = cornerRadius
        self.hidesWhenIdle = hidesWhenIdle
    }
}
