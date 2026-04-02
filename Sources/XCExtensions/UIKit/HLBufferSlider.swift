import UIKit

// MARK: - Delegate

public protocol HLBufferSliderDelegate: AnyObject {
    /// 用户拖动中（scrubbing）
    func bufferSlider(_ slider: HLBufferSlider, didScrubToValue value: Float)
    /// 用户松手，确认 seek 到该时间点
    func bufferSlider(_ slider: HLBufferSlider, didSeekToValue value: Float)
}

public extension HLBufferSliderDelegate {
    func bufferSlider(_ slider: HLBufferSlider, didScrubToValue value: Float) {}
}

// MARK: - Buffer Appearance

/// 缓冲层外观配置
public struct HLBufferSliderBufferConfig {
    /// 缓冲进度颜色，默认半透明白色
    public var color: UIColor
    /// 缓冲动画：加载中显示 shimmer，默认 true
    public var showShimmer: Bool

    public init(
        color: UIColor = UIColor.white.withAlphaComponent(0.4),
        showShimmer: Bool = true
    ) {
        self.color = color
        self.showShimmer = showShimmer
    }
}

// MARK: - HLBufferSlider

/// 播放器进度条
/// - 三层轨道：background / buffer（缓冲）/ progress（播放）
/// - 拖动中显示预览时间标签
/// - 支持 scrubbing 速度（模拟 iOS 系统播放器的精确 scrub）
open class HLBufferSlider: UIControl {

    // MARK: - Public Properties

    public weak var delegate: HLBufferSliderDelegate?

    /// 当前播放进度 0~1
    public var value: Float = 0 {
        didSet {
            value = max(0, min(1, value))
            if !isDragging { setNeedsLayout() }
        }
    }

    /// 缓冲进度 0~1
    public var bufferValue: Float = 0 {
        didSet {
            bufferValue = max(0, min(1, bufferValue))
            setNeedsLayout()
        }
    }

    /// 是否正在拖动
    public private(set) var isDragging: Bool = false

    /// 拖动中的临时值（显示用）
    public private(set) var scrubbingValue: Float = 0

    /// 轨道外观
    public var trackConfig: HLSliderTrackConfig = HLSliderTrackConfig(
        height: 3,
        minimumTrackColor: .white,
        maximumTrackColor: UIColor.white.withAlphaComponent(0.2)
    ) {
        didSet { setNeedsLayout() }
    }

    /// 缓冲层外观
    public var bufferConfig: HLBufferSliderBufferConfig = HLBufferSliderBufferConfig() {
        didSet { applyBufferConfig() }
    }

    /// Thumb 外观
    public var thumbConfig: HLSliderThumbConfig = HLSliderThumbConfig(
        diameter: 14,
        fillColor: .white,
        shadowColor: UIColor.black.withAlphaComponent(0.3)
    ) {
        didSet { applyThumbConfig() }
    }

    /// 时间标签配置，nil 不显示
    public var timeLabelConfig: HLSliderLabelConfig? = HLSliderLabelConfig(
        formatter: { _ in "--:--" },
        offset: 6,
        font: .monospacedDigitSystemFont(ofSize: 11, weight: .medium),
        textColor: .white,
        backgroundColor: UIColor.black.withAlphaComponent(0.6),
        contentInsets: UIEdgeInsets(top: 3, left: 6, bottom: 3, right: 6),
        cornerRadius: 4,
        hidesWhenIdle: true
    ) {
        didSet { applyTimeLabelConfig() }
    }

    /// Scrubbing 速度（精确拖动比例），参考 iOS 系统播放器
    /// 1.0 = 正常，0.5 = 半速，0.1 = 精细
    public var scrubbingSpeed: Float = 1.0

    // MARK: - Private Views / Layers

    private let backgroundTrackView = UIView()
    private let bufferTrackView = UIView()
    private let progressTrackView = UIView()
    private let shimmerLayer = CAGradientLayer()

    private let thumbView = UIView()
    private let timeLabel = UILabel()

    // MARK: - Touch State

    private var touchStartX: CGFloat = 0
    private var touchStartValue: Float = 0
    /// 拖动起始 Y，用于计算 scrubbing speed 降速（垂直滑动降速，模拟系统行为）
    private var touchCurrentY: CGFloat = 0

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
        // 层级：background → buffer → progress → thumb
        [backgroundTrackView, bufferTrackView, progressTrackView].forEach {
            addSubview($0)
            $0.isUserInteractionEnabled = false
        }

        // Shimmer layer on buffer track
        shimmerLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.3).cgColor,
            UIColor.clear.cgColor
        ]
        shimmerLayer.locations = [0, 0.5, 1]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
        bufferTrackView.layer.addSublayer(shimmerLayer)

        // Thumb
        addSubview(thumbView)
        thumbView.isUserInteractionEnabled = false

        // Time label → superview
        timeLabel.textAlignment = .center
        timeLabel.isHidden = true

        applyThumbConfig()
        applyBufferConfig()
    }

    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        superview?.addSubview(timeLabel)
        applyTimeLabelConfig()
    }

    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil { timeLabel.removeFromSuperview() }
    }

    // MARK: - Layout

    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutTracks()
        layoutThumb()
        layoutTimeLabel()
        if bufferConfig.showShimmer { layoutShimmer() }
    }

    private var trackRect: CGRect {
        let h = trackConfig.height
        let thumbDiam = thumbConfig.diameter
        let inset = thumbDiam / 2
        return CGRect(x: inset, y: bounds.midY - h / 2, width: bounds.width - inset * 2, height: h)
    }

    private func layoutTracks() {
        let tr = trackRect
        let radius = trackConfig.cornerRadius ?? (trackConfig.height / 2)

        backgroundTrackView.frame = tr
        backgroundTrackView.layer.cornerRadius = radius
        backgroundTrackView.backgroundColor = trackConfig.maximumTrackColor ?? UIColor.white.withAlphaComponent(0.2)

        // Buffer
        let bw = tr.width * CGFloat(bufferValue)
        bufferTrackView.frame = CGRect(x: tr.minX, y: tr.minY, width: bw, height: tr.height)
        bufferTrackView.layer.cornerRadius = radius
        bufferTrackView.backgroundColor = bufferConfig.color

        // Progress
        let displayValue = isDragging ? scrubbingValue : value
        let pw = tr.width * CGFloat(displayValue)
        progressTrackView.frame = CGRect(x: tr.minX, y: tr.minY, width: pw, height: tr.height)
        progressTrackView.layer.cornerRadius = radius
        progressTrackView.backgroundColor = trackConfig.minimumTrackColor ?? .white
    }

    private func layoutThumb() {
        let tr = trackRect
        let displayValue = isDragging ? scrubbingValue : value
        let cx = tr.minX + tr.width * CGFloat(displayValue)
        let diam = thumbConfig.diameter
        thumbView.frame = CGRect(x: cx - diam / 2, y: bounds.midY - diam / 2, width: diam, height: diam)
    }

    private func layoutTimeLabel() {
        guard let config = timeLabelConfig, !timeLabel.isHidden else { return }
        let text = timeLabel.text ?? ""
        let textSize = (text as NSString).boundingRect(
            with: CGSize(width: 200, height: 44),
            options: .usesLineFragmentOrigin,
            attributes: [.font: config.font],
            context: nil
        ).size
        let w = ceil(textSize.width) + config.contentInsets.left + config.contentInsets.right
        let h = ceil(textSize.height) + config.contentInsets.top + config.contentInsets.bottom
        timeLabel.bounds.size = CGSize(width: w, height: h)

        guard let sv = superview else { return }
        let thumbCenter = convert(thumbView.center, to: sv)
        timeLabel.center = CGPoint(
            x: thumbCenter.x,
            y: thumbCenter.y - thumbConfig.diameter / 2 - config.offset - h / 2
        )
    }

    private func layoutShimmer() {
        shimmerLayer.frame = bufferTrackView.bounds
        // 如果缓冲还未完成，播放 shimmer 动画
        if shimmerLayer.animation(forKey: "shimmer") == nil && bufferValue < 1.0 {
            startShimmer()
        } else if bufferValue >= 1.0 {
            shimmerLayer.removeAnimation(forKey: "shimmer")
        }
    }

    // MARK: - Apply Configs

    private func applyThumbConfig() {
        let config = thumbConfig
        thumbView.bounds.size = CGSize(width: config.diameter, height: config.diameter)
        thumbView.layer.cornerRadius = config.diameter / 2
        thumbView.backgroundColor = config.fillColor

        if let borderColor = config.borderColor {
            thumbView.layer.borderColor = borderColor.cgColor
            thumbView.layer.borderWidth = config.borderWidth
        }
        if let shadowColor = config.shadowColor {
            thumbView.layer.shadowColor = shadowColor.cgColor
            thumbView.layer.shadowOffset = config.shadowOffset
            thumbView.layer.shadowRadius = config.shadowRadius
            thumbView.layer.shadowOpacity = 1
        }
    }

    private func applyBufferConfig() {
        bufferTrackView.backgroundColor = bufferConfig.color
        if bufferConfig.showShimmer {
            startShimmer()
        } else {
            shimmerLayer.removeAnimation(forKey: "shimmer")
        }
    }

    private func applyTimeLabelConfig() {
        guard let config = timeLabelConfig else {
            timeLabel.isHidden = true
            return
        }
        timeLabel.font = config.font
        timeLabel.textColor = config.textColor
        timeLabel.backgroundColor = config.backgroundColor
        timeLabel.layer.cornerRadius = config.cornerRadius
        timeLabel.layer.masksToBounds = true
        timeLabel.isHidden = config.hidesWhenIdle
    }

    // MARK: - Shimmer Animation

    private func startShimmer() {
        guard shimmerLayer.animation(forKey: "shimmer") == nil else { return }
        let anim = CABasicAnimation(keyPath: "locations")
        anim.fromValue = [-0.5, -0.25, 0]
        anim.toValue = [1.0, 1.25, 1.5]
        anim.duration = 1.6
        anim.repeatCount = .infinity
        shimmerLayer.add(anim, forKey: "shimmer")
    }

    // MARK: - Touch Handling

    open override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let pt = touch.location(in: self)

        // 命中检测：thumb 区域 或 整个 track 区域
        let tr = trackRect
        let expandedThumbRect = thumbView.frame.insetBy(dx: -10, dy: -bounds.height / 2)
        let expandedTrackRect = tr.insetBy(dx: 0, dy: -12)
        guard expandedThumbRect.contains(pt) || expandedTrackRect.contains(pt) else { return false }

        isDragging = true
        touchStartX = pt.x
        touchCurrentY = pt.y
        touchStartValue = value
        scrubbingValue = value

        // 如果点击非 thumb 区域，直接跳到该位置
        if !expandedThumbRect.contains(pt) {
            let pct = Float((pt.x - tr.minX) / tr.width)
            scrubbingValue = max(0, min(1, pct))
            touchStartValue = scrubbingValue
        }

        showTimeLabel()
        setNeedsLayout()
        return true
    }

    open override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let pt = touch.location(in: self)
        let tr = trackRect

        // 垂直偏移越大，scrubbing 速度越慢（精细控制）
        let verticalOffset = abs(pt.y - bounds.midY)
        let speedMultiplier: Float
        if verticalOffset < 50 {
            speedMultiplier = scrubbingSpeed
        } else if verticalOffset < 150 {
            speedMultiplier = scrubbingSpeed * 0.5
        } else {
            speedMultiplier = scrubbingSpeed * 0.1
        }

        let dx = Float((pt.x - touchStartX) / tr.width)
        scrubbingValue = max(0, min(1, touchStartValue + dx * speedMultiplier))

        updateTimeLabelText()
        setNeedsLayout()
        sendActions(for: .valueChanged)
        delegate?.bufferSlider(self, didScrubToValue: scrubbingValue)
        return true
    }

    open override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        value = scrubbingValue
        isDragging = false
        hideTimeLabel()
        setNeedsLayout()
        sendActions(for: .valueChanged)
        delegate?.bufferSlider(self, didSeekToValue: value)
    }

    open override func cancelTracking(with event: UIEvent?) {
        isDragging = false
        scrubbingValue = value
        hideTimeLabel()
        setNeedsLayout()
    }

    // MARK: - Time Label

    private func updateTimeLabelText() {
        guard let config = timeLabelConfig else { return }
        timeLabel.text = config.formatter(scrubbingValue)
        setNeedsLayout()
    }

    private func showTimeLabel() {
        guard let config = timeLabelConfig, config.hidesWhenIdle else { return }
        updateTimeLabelText()
        timeLabel.isHidden = false
        timeLabel.alpha = 0
        timeLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.timeLabel.alpha = 1
            self.timeLabel.transform = .identity
        }
    }

    private func hideTimeLabel() {
        guard let config = timeLabelConfig, config.hidesWhenIdle else { return }
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseIn) {
            self.timeLabel.alpha = 0
            self.timeLabel.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        } completion: { _ in
            self.timeLabel.isHidden = true
            self.timeLabel.alpha = 1
            self.timeLabel.transform = .identity
        }
    }
}
