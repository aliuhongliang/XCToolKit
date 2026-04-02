import UIKit

// MARK: - Delegate

public protocol HLRangeSliderDelegate: AnyObject {
    func rangeSlider(_ slider: HLRangeSlider, didChangeLowerValue lower: Float, upperValue upper: Float)
    func rangeSliderDidBeginTracking(_ slider: HLRangeSlider)
    func rangeSliderDidEndTracking(_ slider: HLRangeSlider)
}

public extension HLRangeSliderDelegate {
    func rangeSliderDidBeginTracking(_ slider: HLRangeSlider) {}
    func rangeSliderDidEndTracking(_ slider: HLRangeSlider) {}
}

// MARK: - HLRangeSlider

/// 双滑块范围选择器
/// - lower / upper thumb 各自独立外观配置
/// - 支持步进吸附、最小间距约束、浮动标签
open class HLRangeSlider: UIControl {

    // MARK: - Public Properties

    public weak var delegate: HLRangeSliderDelegate?

    /// 最小值，默认 0
    public var minimumValue: Float = 0 { didSet { clampValues(); setNeedsLayout() } }
    /// 最大值，默认 1
    public var maximumValue: Float = 1 { didSet { clampValues(); setNeedsLayout() } }

    /// lower thumb 当前值
    public private(set) var lowerValue: Float = 0 {
        didSet { lowerValue = max(minimumValue, min(lowerValue, upperValue - minimumDistance)) }
    }
    /// upper thumb 当前值
    public private(set) var upperValue: Float = 1 {
        didSet { upperValue = min(maximumValue, max(upperValue, lowerValue + minimumDistance)) }
    }

    /// lower / upper 之间的最小距离，默认 0
    public var minimumDistance: Float = 0

    /// 步进配置，nil 为连续
    public var stepConfig: HLSliderStepConfig? { didSet { setNeedsLayout() } }

    /// 轨道外观
    public var trackConfig: HLSliderTrackConfig = HLSliderTrackConfig() { didSet { setNeedsLayout() } }

    /// lower thumb 外观
    public var lowerThumbConfig: HLSliderThumbConfig = HLSliderThumbConfig() {
        didSet { lowerThumbLayer.setNeedsDisplay() }
    }
    /// upper thumb 外观
    public var upperThumbConfig: HLSliderThumbConfig = HLSliderThumbConfig() {
        didSet { upperThumbLayer.setNeedsDisplay() }
    }

    /// lower 浮动标签，nil 不显示
    public var lowerLabelConfig: HLSliderLabelConfig? { didSet { applyLabelConfigs() } }
    /// upper 浮动标签，nil 不显示
    public var upperLabelConfig: HLSliderLabelConfig? { didSet { applyLabelConfigs() } }

    /// 设置 lower / upper 值（带动画可选）
    public func setLowerValue(_ lower: Float, upperValue upper: Float, animated: Bool) {
        let newLower = clamp(lower)
        let newUpper = clamp(upper)
        lowerValue = min(newLower, newUpper - minimumDistance)
        upperValue = max(newUpper, newLower + minimumDistance)
        if animated {
            UIView.animate(withDuration: 0.2) { self.setNeedsLayout(); self.layoutIfNeeded() }
        } else {
            setNeedsLayout()
        }
    }

    // MARK: - Private Layers / Views

    private let trackLayer = CALayer()
    private let rangeTrackLayer = CALayer()
    private let tickMarkContainer = UIView()

    private let lowerThumbLayer = HLThumbLayer()
    private let upperThumbLayer = HLThumbLayer()

    private let lowerLabel = UILabel()
    private let upperLabel = UILabel()

    // MARK: - Touch Tracking State

    private enum ActiveThumb { case lower, upper, none }
    private var activeThumb: ActiveThumb = .none
    private var lastTouchX: CGFloat = 0

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
        // Track layers
        layer.addSublayer(trackLayer)
        layer.addSublayer(rangeTrackLayer)

        // Tick marks
        addSubview(tickMarkContainer)
        tickMarkContainer.isUserInteractionEnabled = false

        // Thumb layers
        lowerThumbLayer.contentsScale = UIScreen.main.scale
        upperThumbLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(lowerThumbLayer)
        layer.addSublayer(upperThumbLayer)

        // Labels (added to superview in didMoveToSuperview)
        [lowerLabel, upperLabel].forEach {
            $0.textAlignment = .center
            $0.isHidden = true
        }
    }

    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        superview?.addSubview(lowerLabel)
        superview?.addSubview(upperLabel)
        applyLabelConfigs()
    }

    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            lowerLabel.removeFromSuperview()
            upperLabel.removeFromSuperview()
        }
    }

    // MARK: - Layout

    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutTrack()
        layoutThumbs()
        layoutTickMarks()
        layoutLabels()
    }

    private var trackRect: CGRect {
        let height = trackConfig.height
        let thumbDiameter = max(lowerThumbConfig.diameter, upperThumbConfig.diameter)
        let inset = thumbDiameter / 2
        return CGRect(
            x: inset,
            y: bounds.midY - height / 2,
            width: bounds.width - inset * 2,
            height: height
        )
    }

    private func layoutTrack() {
        let tr = trackRect
        let radius = trackConfig.cornerRadius ?? (trackConfig.height / 2)

        trackLayer.frame = tr
        trackLayer.cornerRadius = radius
        trackLayer.backgroundColor = (trackConfig.maximumTrackColor ?? UIColor.systemGray4).cgColor

        let lx = xPosition(for: lowerValue)
        let ux = xPosition(for: upperValue)
        rangeTrackLayer.frame = CGRect(x: lx, y: tr.minY, width: ux - lx, height: tr.height)
        rangeTrackLayer.cornerRadius = 0
        rangeTrackLayer.backgroundColor = (trackConfig.minimumTrackColor ?? tintColor).cgColor
    }

    private func layoutThumbs() {
        lowerThumbLayer.config = lowerThumbConfig
        upperThumbLayer.config = upperThumbConfig

        let lDiam = lowerThumbConfig.diameter
        let uDiam = upperThumbConfig.diameter
        let lx = xPosition(for: lowerValue)
        let ux = xPosition(for: upperValue)

        lowerThumbLayer.frame = CGRect(
            x: lx - lDiam / 2, y: bounds.midY - lDiam / 2,
            width: lDiam, height: lDiam
        )
        upperThumbLayer.frame = CGRect(
            x: ux - uDiam / 2, y: bounds.midY - uDiam / 2,
            width: uDiam, height: uDiam
        )
        lowerThumbLayer.setNeedsDisplay()
        upperThumbLayer.setNeedsDisplay()
    }

    private func layoutTickMarks() {
        tickMarkContainer.subviews.forEach { $0.removeFromSuperview() }
        guard let config = stepConfig, config.showTickMarks else {
            tickMarkContainer.isHidden = true
            return
        }
        tickMarkContainer.isHidden = false
        tickMarkContainer.frame = trackRect

        let range = maximumValue - minimumValue
        guard range > 0, config.step > 0 else { return }
        let count = Int(range / config.step) + 1

        for i in 0..<count {
            let pct = CGFloat(Float(i) * config.step / range)
            let x = trackRect.width * pct
            let dot = UIView()
            dot.backgroundColor = config.tickColor ?? UIColor.systemGray3
            dot.layer.cornerRadius = config.tickDiameter / 2
            dot.frame = CGRect(
                x: x - config.tickDiameter / 2,
                y: trackRect.height / 2 - config.tickDiameter / 2,
                width: config.tickDiameter,
                height: config.tickDiameter
            )
            tickMarkContainer.addSubview(dot)
        }
    }

    private func layoutLabels() {
        layoutLabel(lowerLabel, for: lowerValue, config: lowerLabelConfig)
        layoutLabel(upperLabel, for: upperValue, config: upperLabelConfig)
    }

    private func layoutLabel(_ label: UILabel, for value: Float, config: HLSliderLabelConfig?) {
        guard let config = config, !label.isHidden else { return }
        let text = config.formatter(value)
        label.text = text
        label.font = config.font
        label.textColor = config.textColor
        label.backgroundColor = config.backgroundColor
        label.layer.cornerRadius = config.cornerRadius
        label.layer.masksToBounds = true

        let textSize = (text as NSString).boundingRect(
            with: CGSize(width: 200, height: 44),
            options: .usesLineFragmentOrigin,
            attributes: [.font: config.font],
            context: nil
        ).size
        let w = ceil(textSize.width) + config.contentInsets.left + config.contentInsets.right
        let h = ceil(textSize.height) + config.contentInsets.top + config.contentInsets.bottom
        label.bounds.size = CGSize(width: w, height: h)

        guard let sv = superview else { return }
        let thumbTopY = convert(CGPoint(x: 0, y: bounds.midY - max(lowerThumbConfig.diameter, upperThumbConfig.diameter) / 2), to: sv).y
        let cx = convert(CGPoint(x: xPosition(for: value), y: 0), to: sv).x
        label.center = CGPoint(x: cx, y: thumbTopY - config.offset - h / 2)
    }

    private func applyLabelConfigs() {
        if let config = lowerLabelConfig {
            lowerLabel.isHidden = config.hidesWhenIdle
        } else {
            lowerLabel.isHidden = true
        }
        if let config = upperLabelConfig {
            upperLabel.isHidden = config.hidesWhenIdle
        } else {
            upperLabel.isHidden = true
        }
    }

    // MARK: - Touch Handling

    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let pt = touch.location(in: self)
        lastTouchX = pt.x

        let lx = xPosition(for: lowerValue)
        let ux = xPosition(for: upperValue)
        let lDist = abs(pt.x - lx)
        let uDist = abs(pt.x - ux)

        // 命中判定：在 thumb 直径范围内
        let hitRadius: CGFloat = max(lowerThumbConfig.diameter, upperThumbConfig.diameter) / 2 + 4

        if lDist <= hitRadius && uDist <= hitRadius {
            // 两个都命中时，选更近的；相等则选 lower（靠近左边）
            activeThumb = lDist <= uDist ? .lower : .upper
        } else if lDist <= hitRadius {
            activeThumb = .lower
        } else if uDist <= hitRadius {
            activeThumb = .upper
        } else {
            activeThumb = .none
            return false
        }

        // highlight
        if activeThumb == .lower {
            lowerThumbLayer.isHighlighted = true
            showLabel(lowerLabel, config: lowerLabelConfig)
        } else {
            upperThumbLayer.isHighlighted = true
            showLabel(upperLabel, config: upperLabelConfig)
        }

        delegate?.rangeSliderDidBeginTracking(self)
        return true
    }

    open override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let pt = touch.location(in: self)
        let delta = pt.x - lastTouchX
        lastTouchX = pt.x

        let range = maximumValue - minimumValue
        let valueDelta = Float(delta / trackRect.width) * range

        switch activeThumb {
        case .lower:
            var newVal = lowerValue + valueDelta
            if let step = stepConfig?.step, stepConfig?.snapsInRealTime == true {
                newVal = round(newVal / step) * step
            }
            lowerValue = max(minimumValue, min(newVal, upperValue - minimumDistance))
        case .upper:
            var newVal = upperValue + valueDelta
            if let step = stepConfig?.step, stepConfig?.snapsInRealTime == true {
                newVal = round(newVal / step) * step
            }
            upperValue = min(maximumValue, max(newVal, lowerValue + minimumDistance))
        case .none:
            break
        }

        setNeedsLayout()
        sendActions(for: .valueChanged)
        delegate?.rangeSlider(self, didChangeLowerValue: lowerValue, upperValue: upperValue)
        return true
    }

    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        // 松手步进吸附
        if let config = stepConfig, !config.snapsInRealTime {
            let step = config.step
            if activeThumb == .lower {
                lowerValue = clamp(round(lowerValue / step) * step)
            } else if activeThumb == .upper {
                upperValue = clamp(round(upperValue / step) * step)
            }
            setNeedsLayout()
            sendActions(for: .valueChanged)
            delegate?.rangeSlider(self, didChangeLowerValue: lowerValue, upperValue: upperValue)
        }

        lowerThumbLayer.isHighlighted = false
        upperThumbLayer.isHighlighted = false
        hideLabel(lowerLabel, config: lowerLabelConfig)
        hideLabel(upperLabel, config: upperLabelConfig)
        activeThumb = .none
        delegate?.rangeSliderDidEndTracking(self)
    }

    open override func cancelTracking(with event: UIEvent?) {
        endTracking(nil, with: event)
    }

    // MARK: - Helpers

    private func xPosition(for value: Float) -> CGFloat {
        let tr = trackRect
        let range = maximumValue - minimumValue
        guard range > 0 else { return tr.minX }
        let pct = CGFloat((value - minimumValue) / range)
        return tr.minX + tr.width * pct
    }

    private func clamp(_ value: Float) -> Float {
        max(minimumValue, min(maximumValue, value))
    }

    private func clampValues() {
        lowerValue = clamp(lowerValue)
        upperValue = clamp(upperValue)
    }

    // MARK: - Label Animation

    private func showLabel(_ label: UILabel, config: HLSliderLabelConfig?) {
        guard let config = config, config.hidesWhenIdle else { return }
        label.isHidden = false
        label.alpha = 0
        label.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            label.alpha = 1
            label.transform = .identity
        }
    }

    private func hideLabel(_ label: UILabel, config: HLSliderLabelConfig?) {
        guard let config = config, config.hidesWhenIdle else { return }
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn) {
            label.alpha = 0
            label.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        } completion: { _ in
            label.isHidden = true
            label.alpha = 1
            label.transform = .identity
        }
    }
}

// MARK: - HLThumbLayer (Internal)

/// 用 CALayer 绘制 thumb，避免 UIView 层级干扰 touch hit-test
private class HLThumbLayer: CALayer {

    var config: HLSliderThumbConfig = HLSliderThumbConfig() { didSet { setNeedsDisplay() } }
    var isHighlighted: Bool = false { didSet { setNeedsDisplay() } }

    override func draw(in ctx: CGContext) {
        let inset = config.shadowColor != nil
            ? config.shadowRadius + abs(config.shadowOffset.height) + 2
            : CGFloat(0)
        let circleRect = bounds.insetBy(dx: inset, dy: inset)

        // Shadow
        if let shadowColor = config.shadowColor {
            ctx.setShadow(
                offset: config.shadowOffset,
                blur: config.shadowRadius,
                color: shadowColor.cgColor
            )
        }

        let fillColor = isHighlighted
            ? config.fillColor.withAlphaComponent(0.85)
            : config.fillColor
        ctx.setFillColor(fillColor.cgColor)
        ctx.fillEllipse(in: circleRect)

        if let borderColor = config.borderColor, config.borderWidth > 0 {
            ctx.setShadow(offset: .zero, blur: 0, color: nil)
            ctx.setStrokeColor(borderColor.cgColor)
            ctx.setLineWidth(config.borderWidth)
            ctx.strokeEllipse(in: circleRect.insetBy(dx: config.borderWidth / 2, dy: config.borderWidth / 2))
        }
    }
}
