
import UIKit

// MARK: ========================================
// MARK: - 2. HLView 子类
// MARK: ========================================
 
/// 支持渐变 + 指定角圆角 + 边框 + 阴影组合的 UIView 子类
/// 所有样式在 layoutSubviews 中自动刷新，frame 变化无需手动更新
open class HLView: UIView {
 
    // MARK: 渐变
 
    /// 渐变方向
    public enum GradientDirection {
        case horizontal             // 左 → 右
        case vertical               // 上 → 下
        case diagonalDownRight      // 左上 → 右下
        case diagonalDownLeft       // 右上 → 左下
        case custom(start: CGPoint, end: CGPoint)  // 自定义起止点（归一化）
    }
 
    /// 渐变颜色数组，设置后自动显示渐变背景
    public var gradientColors: [UIColor]? {
        didSet { setNeedsLayout() }
    }
 
    /// 渐变方向，默认垂直
    public var gradientDirection: GradientDirection = .vertical {
        didSet { setNeedsLayout() }
    }
 
    /// 渐变颜色位置（0~1），nil 表示均匀分布
    public var gradientLocations: [CGFloat]? {
        didSet { setNeedsLayout() }
    }
 
    private var gradientLayer: CAGradientLayer?
 
    // MARK: 圆角（支持指定角）
 
    /// 圆角半径
    public var cornerRadius: CGFloat = 0 {
        didSet { setNeedsLayout() }
    }
 
    /// 需要圆角的角，默认全部
    public var roundedCorners: UIRectCorner = .allCorners {
        didSet { setNeedsLayout() }
    }
 
    private var maskLayer: CAShapeLayer?
 
    // MARK: 边框
 
    /// 边框颜色
    public var borderColor: UIColor? {
        didSet { setNeedsLayout() }
    }
 
    /// 边框宽度
    public var borderWidth: CGFloat = 0 {
        didSet { setNeedsLayout() }
    }
 
    private var borderLayer: CAShapeLayer?
 
    // MARK: 阴影
    // 阴影直接加在 self.layer 上
    // 注意：开启阴影时不能同时 masksToBounds，否则阴影被裁掉
    // 圆角通过 maskLayer（CAShapeLayer）实现，不依赖 masksToBounds，两者可共存
 
    /// 阴影颜色
    public var shadowColor: UIColor = .black {
        didSet { updateShadow() }
    }
 
    /// 阴影透明度，0 表示无阴影
    public var shadowOpacity: Float = 0 {
        didSet { updateShadow() }
    }
 
    /// 阴影模糊半径
    public var shadowRadius: CGFloat = 4 {
        didSet { updateShadow() }
    }
 
    /// 阴影偏移
    public var shadowOffset: CGSize = .zero {
        didSet { updateShadow() }
    }
 
    // MARK: layoutSubviews
 
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
        applyGradient()
        applyCornerAndBorder()
    }
 
    // MARK: 私有 — 渐变
 
    private func applyGradient() {
        guard let colors = gradientColors, colors.count >= 2 else {
            gradientLayer?.removeFromSuperlayer()
            gradientLayer = nil
            return
        }
 
        let gl = gradientLayer ?? {
            let l = CAGradientLayer()
            layer.insertSublayer(l, at: 0)
            gradientLayer = l
            return l
        }()
 
        gl.frame  = bounds
        gl.colors = colors.map(\.cgColor)
 
        if let locations = gradientLocations {
            gl.locations = locations.map { NSNumber(value: Double($0)) }
        }
 
        let (start, end) = gradientPoints(for: gradientDirection)
        gl.startPoint = start
        gl.endPoint   = end
    }
 
    private func gradientPoints(for direction: GradientDirection) -> (CGPoint, CGPoint) {
        switch direction {
        case .horizontal:           return (CGPoint(x: 0, y: 0.5), CGPoint(x: 1, y: 0.5))
        case .vertical:             return (CGPoint(x: 0.5, y: 0), CGPoint(x: 0.5, y: 1))
        case .diagonalDownRight:    return (CGPoint(x: 0, y: 0),   CGPoint(x: 1, y: 1))
        case .diagonalDownLeft:     return (CGPoint(x: 1, y: 0),   CGPoint(x: 0, y: 1))
        case .custom(let s, let e): return (s, e)
        }
    }
 
    // MARK: 私有 — 圆角 + 边框
 
    private func applyCornerAndBorder() {
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: roundedCorners,
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
 
        // 圆角 mask
        if cornerRadius > 0 {
            let mask = maskLayer ?? {
                let l = CAShapeLayer()
                layer.mask = l
                maskLayer = l
                return l
            }()
            mask.path = path.cgPath
        } else {
            layer.mask = nil
            maskLayer  = nil
        }
 
        // 边框（跟随圆角路径，覆盖在最上层）
        if borderWidth > 0, let color = borderColor {
            let border = borderLayer ?? {
                let l = CAShapeLayer()
                layer.addSublayer(l)
                borderLayer = l
                return l
            }()
            border.path        = path.cgPath
            border.strokeColor = color.cgColor
            border.fillColor   = UIColor.clear.cgColor
            border.lineWidth   = borderWidth * 2  // 路径描边居中，一半在外被裁掉，*2 保证内侧宽度正确
            border.frame       = bounds
        } else {
            borderLayer?.removeFromSuperlayer()
            borderLayer = nil
        }
    }
 
    // MARK: 私有 — 阴影
 
    private func updateShadow() {
        layer.shadowColor   = shadowColor.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius  = shadowRadius
        layer.shadowOffset  = shadowOffset
        // 不设置 masksToBounds，保证阴影不被裁剪
        // 圆角通过 maskLayer 实现，与阴影互不干扰
    }
}
