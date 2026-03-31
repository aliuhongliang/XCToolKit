//
//  BaseViewController.swift
//  XCToolkit
//
//  Created by wintop on 2026/3/31.
//

import UIKit
#if canImport(XCExtensions)
import XCExtensions
#endif

open class BaseViewController: UIViewController {
    
    var firstLoad: Bool = true
    
    
    open var popGestureEnable: Bool { true }
    
    open var navigationBarHidden: Bool { false }
    
    open var navigationBarColor: UIColor { .clear }
    
    
    // MARK: - 自定义导航栏开关（navigationBarHidden = true 时生效）
    open var showCustomNavigationBar: Bool { false }
    open var customNavigationBarHeight: CGFloat { 44 }
    open var customNavigationBarColor: UIColor { .yellow }
    open var customNavigationBarSeparatorColor: UIColor? { nil }
    public private(set) lazy var customNavBar: CustomNavigationBar = {
        let bar = CustomNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    open override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 15.0, *) {
        } else {
            navigationController?.navigationBar.shadowImage = UIImage()
        }
        
        if navigationBarHidden && showCustomNavigationBar {
            setupCustomNavigationBar()
            if (navigationController?.viewControllers.count ?? 0) > 1 {
                navigationController?.interactivePopGestureRecognizer?.delegate = nil
            }
        }
        
        if !navigationBarHidden && (navigationController?.viewControllers.count ?? 0) > 1 {
            setBackButton()
            navigationController?.interactivePopGestureRecognizer?.delegate = nil
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(navigationBarHidden, animated: animated)
        
        if !navigationBarHidden {
            applySystemNavigationBarAppearance()
        }
        
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if navigationController?.viewControllers.count == 1 {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        } else {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = self.popGestureEnable
        }
    
        if firstLoad {
            firstLoad = false
            viewDidAppearFirstLoad()
        }
    }
    
    open func viewDidAppearFirstLoad() {}


    // MARK: 屏幕旋转
    open override var shouldAutorotate: Bool {
        return false
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}

extension BaseViewController {
    
    // MARK: 系统导航栏 — 标题
    
    /// 设置系统导航栏标题文字及样式
    public func setNavigationTitle(
        _ title: String,
        color: UIColor = .black,
        font: UIFont = .semibold(17)
    ) {
        self.navigationItem.title = title
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: font
        ]
        if #available(iOS 15.0, *) {
            let appearance = currentNavigationBarAppearance()
            appearance.titleTextAttributes = attrs
            applyAppearance(appearance)
        } else {
            navigationController?.navigationBar.titleTextAttributes = attrs
        }
    }
    
    // MARK: 系统导航栏 — 返回按钮
    
    /// 设置返回按钮（纯图标，无文字）
    /// - Parameters:
    ///   - image: 自定义图标，不传则使用系统 chevron.left
    ///   - tintColor: 图标颜色，默认黑色
    public func setBackButton(image: UIImage? = nil, tintColor: UIColor = .black) {
        let icon = (image ?? UIImage(systemName: "chevron.left"))?
            .withRenderingMode(.alwaysTemplate)
        
        let btn = UIButton(type: .system)
        btn.setImage(icon, for: .normal)
        btn.tintColor = tintColor
        btn.frame.size = CGSize(width: 44, height: 44)
        btn.contentHorizontalAlignment = .left  // 图标靠左，视觉上贴边
        btn.addTarget(self, action: #selector(_navBack), for: .touchUpInside)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: btn)
    }
    
    /// 添加多个左侧按钮
    public func setLeftBarButtons(_ views: [UIView]) {
        navigationItem.leftBarButtonItems = views.map { UIBarButtonItem(customView: $0) }
    }
    
    // MARK: 系统导航栏 — 右侧按钮
    
    /// 添加单个右侧按钮（文字）
    public func setRightBarButton(
        title: String,
        color: UIColor = .black,
        font: UIFont = .regular(15),
        action: Selector
    ) {
        let btn = makeTextBarButton(title: title, color: color, font: font, action: action)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: btn)
    }
    
    /// 添加单个右侧按钮（图标）
    public func setRightBarButton(
        image: UIImage?,
        tintColor: UIColor = .black,
        action: Selector
    ) {
        let btn = makeIconBarButton(image: image, tintColor: tintColor, action: action)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: btn)
    }
    
    /// 添加多个右侧按钮（自定义 View 数组，从右到左排列）
    public func setRightBarButtons(_ views: [UIView]) {
        navigationItem.rightBarButtonItems = views.map { UIBarButtonItem(customView: $0) }
    }
    
    // MARK: 私有 — 按钮工厂
    
    private func makeTextBarButton(
        title: String,
        color: UIColor,
        font: UIFont,
        action: Selector
    ) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(color, for: .normal)
        btn.titleLabel?.font = font
        btn.addTarget(self, action: action, for: .touchUpInside)
        btn.sizeToFit()
        return btn
    }
    
    private func makeIconBarButton(
        image: UIImage?,
        tintColor: UIColor,
        action: Selector
    ) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = tintColor
        btn.addTarget(self, action: action, for: .touchUpInside)
        btn.sizeToFit()
        return btn
    }
    
    @available(iOS 15.0, *)
    private func currentNavigationBarAppearance() -> UINavigationBarAppearance {
        navigationController?.navigationBar.standardAppearance.copy()
        ?? UINavigationBarAppearance()
    }
    
    @available(iOS 13.0, *)
    private func applyAppearance(_ appearance: UINavigationBarAppearance) {
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        if #available(iOS 15.0, *) {
            navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
        }
    }
    
    // MARK: 私有 — 应用系统导航栏外观
    private func applySystemNavigationBarAppearance() {
//        if #available(iOS 15.0, *) {
//            let appearance = currentNavigationBarAppearance()
//            appearance.backgroundColor = navigationBarColor
//            appearance.shadowColor = .clear
//            appearance.backgroundEffect = nil
//            appearance.shadowColor = nil
//            applyAppearance(appearance)
//        } else {
//            let image = UIImage(color: navigationBarColor)
//            navigationController?.navigationBar.setBackgroundImage(image, for: .default)
//            navigationController?.navigationBar.shadowImage = image
//        }
        guard let nav = navigationController else { return }
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = navigationBarColor
            appearance.shadowColor = .clear
            appearance.shadowImage = UIImage()
            appearance.backgroundEffect = nil
            applyAppearance(appearance)
        } else {
            let img = UIImage(color: navigationBarColor)
            nav.navigationBar.setBackgroundImage(img, for: .default)
            nav.navigationBar.shadowImage = UIImage()
        }
        
        // 🔥 强制刷新（关键！解决闪屏）
        nav.navigationBar.layoutIfNeeded()
    }
}

// MARK: - 自定义导航栏安装
 
extension BaseViewController {
 
    private func setupCustomNavigationBar() {
        customNavBar.backgroundColor = customNavigationBarColor
        customNavBar.separatorColor  = customNavigationBarSeparatorColor
        view.addSubview(customNavBar)
 
        NSLayoutConstraint.activate([
            customNavBar.topAnchor.constraint(equalTo: view.topAnchor),
            customNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // 高度 = SafeArea top + 内容高度
            customNavBar.heightAnchor.constraint(
                equalToConstant: customNavigationBarHeight + safeAreaTopInset()
            )
        ])
    }
 
    private func safeAreaTopInset() -> CGFloat {
        if #available(iOS 13.0, *) {
            return view.window?.safeAreaInsets.top
                ?? UIApplication.shared.windows.first?.safeAreaInsets.top
                ?? 44
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }
}
 

// MARK: - CustomNavigationBar
/// 自定义导航栏视图
/// 内容区域固定在底部 44pt（SafeArea 以上），左中右三栏布局
public final class CustomNavigationBar: UIView {
 
    // MARK: 公开子视图
 
    /// 左侧容器（默认宽度自适应内容，最小 44pt）
    public let leftContainer  = UIView()
    /// 中间容器（自动填充剩余空间）
    public let centerContainer = UIView()
    /// 右侧容器
    public let rightContainer = UIView()
 
    /// 默认标题 Label（在 centerContainer 内）
    public let titleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = UIFont.semibold(17)
        lbl.textColor = .black
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
 
    // MARK: 分割线
 
    public var separatorColor: UIColor? {
        didSet { separator.backgroundColor = separatorColor
                 separator.isHidden = separatorColor == nil }
    }
 
    private let separator: UIView = {
        let v = UIView()
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
 
    // MARK: 内容区（SafeArea 以下 44pt）
 
    private let contentBar = UIView()
 
    // MARK: Init
 
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
 
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
 
    private func setup() {
        [leftContainer, centerContainer, rightContainer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        contentBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentBar)
        contentBar.addSubview(leftContainer)
        contentBar.addSubview(centerContainer)
        contentBar.addSubview(rightContainer)
        addSubview(separator)
 
        // 内容区贴底 44pt
        NSLayoutConstraint.activate([
            contentBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentBar.heightAnchor.constraint(equalToConstant: 44),
        ])
 
        
        // 左 — 固定左边距 8pt，宽度自适应，最小 44
        NSLayoutConstraint.activate([
            leftContainer.leadingAnchor.constraint(equalTo: contentBar.leadingAnchor, constant: 10),
            leftContainer.centerYAnchor.constraint(equalTo: contentBar.centerYAnchor),
            leftContainer.heightAnchor.constraint(equalToConstant: 44),
            leftContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
        leftContainer.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        leftContainer.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // 右 — 固定右边距 8pt，宽度自适应，最小 44
        NSLayoutConstraint.activate([
            rightContainer.trailingAnchor.constraint(equalTo: contentBar.trailingAnchor, constant: -10),
            rightContainer.centerYAnchor.constraint(equalTo: contentBar.centerYAnchor),
            rightContainer.heightAnchor.constraint(equalToConstant: 44),
            rightContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
        rightContainer.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rightContainer.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // 中 — 左右都不超过左右容器，保持居中
        NSLayoutConstraint.activate([
            centerContainer.leadingAnchor.constraint(greaterThanOrEqualTo: leftContainer.trailingAnchor, constant: 4),
            centerContainer.trailingAnchor.constraint(lessThanOrEqualTo: rightContainer.leadingAnchor, constant: -4),
            centerContainer.centerXAnchor.constraint(equalTo: contentBar.centerXAnchor),
            centerContainer.centerYAnchor.constraint(equalTo: contentBar.centerYAnchor),
            centerContainer.heightAnchor.constraint(equalToConstant: 44),
        ])
        centerContainer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        centerContainer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // 默认把 titleLabel 放进 centerContainer
        centerContainer.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: centerContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: centerContainer.trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerContainer.centerYAnchor),
        ])
 
        // 分割线
        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }
}
 
// MARK: - CustomNavigationBar 便捷配置
 
public extension CustomNavigationBar {
 
    // MARK: 标题
 
    /// 设置纯文字标题
    func setTitle(_ text: String, color: UIColor = .black, font: UIFont = .semibold(17)) {
        titleLabel.text      = text
        titleLabel.textColor = color
        titleLabel.font      = font
    }
 
    /// 用自定义 View 替换中间标题区域
    func setCenterView(_ view: UIView) {
        centerContainer.subviews.forEach { $0.removeFromSuperview() }
        view.translatesAutoresizingMaskIntoConstraints = false
        centerContainer.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: centerContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: centerContainer.trailingAnchor),
            view.centerYAnchor.constraint(equalTo: centerContainer.centerYAnchor),
        ])
    }
 
    // MARK: 左侧
 
    /// 设置默认返回按钮（自动判断 pop / dismiss）
    func setBackButton(
        image: UIImage? = UIImage(systemName: "chevron.left"),
        tintColor: UIColor = .black,
        target: UIViewController
    ) {
        let btn = makeButton(image: image, tintColor: tintColor,
                             target: target, action: #selector(UIViewController._navBack))
        setLeftView(btn)
    }
 
    /// 设置左侧文字按钮
    func setLeftTextButton(
        title: String,
        color: UIColor = .black,
        font: UIFont = .regular(15),
        target: Any,
        action: Selector
    ) {
        let btn = makeTextButton(title: title, color: color, font: font,
                                 target: target, action: action)
        setLeftView(btn)
    }
 
    /// 用自定义 View 替换左侧区域
    func setLeftView(_ view: UIView) {
        leftContainer.subviews.forEach { $0.removeFromSuperview() }
        view.translatesAutoresizingMaskIntoConstraints = false
        leftContainer.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor),
            view.centerYAnchor.constraint(equalTo: leftContainer.centerYAnchor),
        ])
    }
 
    // MARK: 右侧
 
    /// 设置单个右侧图标按钮
    func setRightButton(
        image: UIImage?,
        tintColor: UIColor = .black,
        target: Any,
        action: Selector
    ) {
        let btn = makeButton(image: image, tintColor: tintColor, target: target, action: action)
        setRightView(btn)
    }
 
    /// 设置单个右侧文字按钮
    func setRightTextButton(
        title: String,
        color: UIColor = .black,
        font: UIFont = .regular(15),
        target: Any,
        action: Selector
    ) {
        let btn = makeTextButton(title: title, color: color, font: font,
                                 target: target, action: action)
        setRightView(btn)
    }
 
    /// 设置多个右侧按钮（从右到左排列）
    func setRightButtons(_ views: [UIView], spacing: CGFloat = 8) {
        rightContainer.subviews.forEach { $0.removeFromSuperview() }
 
        let stack = UIStackView(arrangedSubviews: views.reversed())
        stack.axis = .horizontal
        stack.spacing = spacing
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
 
        rightContainer.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: rightContainer.centerYAnchor),
        ])
    }
 
    /// 用自定义 View 替换右侧区域
    func setRightView(_ view: UIView) {
        rightContainer.subviews.forEach { $0.removeFromSuperview() }
        view.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: rightContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor),
            view.centerYAnchor.constraint(equalTo: rightContainer.centerYAnchor),
        ])
    }
    
    // MARK: 私有工厂
 
    private func makeButton(
        image: UIImage?,
        tintColor: UIColor,
        target: Any,
        action: Selector
    ) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.tintColor = tintColor
        btn.addTarget(target, action: action, for: .touchUpInside)
        btn.frame.size = CGSize(width: 44, height: 44)
        return btn
    }
 
    private func makeTextButton(
        title: String,
        color: UIColor,
        font: UIFont,
        target: Any,
        action: Selector
    ) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.setTitleColor(color, for: .normal)
        btn.titleLabel?.font = font
        btn.addTarget(target, action: action, for: .touchUpInside)
        btn.sizeToFit()
        // 保证最小点击区域
        if btn.frame.width < 44 {
            btn.frame.size.width = 44
        }
        return btn
    }
}
 
// MARK: - UIViewController 返回逻辑
 
extension UIViewController {
    /// 自动判断 pop / dismiss
    @objc func _navBack() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
}
