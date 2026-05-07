//
//  HLBasePopup.swift
//  XCToolkit
//
//  所有弹窗的基类，处理遮罩、呈现、消失逻辑

import UIKit

open class HLBasePopup: UIViewController {

    // MARK: - 全局注册表

    private static var registry: [String: WeakPopupRef] = [:]

    private struct WeakPopupRef {
        weak var popup: HLBasePopup?
    }
    // MARK: - Public Config

    /// 点击遮罩是否关闭弹窗，默认 true
    public var tapMaskToDismiss: Bool = true

    // MARK: - UI

    /// 遮罩视图
    public let hlMaskView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        v.alpha = 0
        return v
    }()

    /// 内容容器
    public let contentView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupMask()
        setupContentView()
    }
    
    /// 根据类型 dismiss
    public static func dismiss(_ type: HLBasePopup.Type) {
        let key = String(describing: type)
        registry[key]?.popup?.dismiss()
    }
    

    // MARK: - Setup

    private func setupMask() {
        view.addSubview(hlMaskView)
        hlMaskView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hlMaskView.topAnchor.constraint(equalTo: view.topAnchor),
            hlMaskView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hlMaskView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hlMaskView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(onMaskTapped))
        hlMaskView.addGestureRecognizer(tap)
    }

    open func setupContentView() {
        // 子类实现具体布局
    }

    // MARK: - Show / Dismiss

    /// 显示弹窗
    public func show() {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        else { return }

        let key = String(describing: Swift.type(of: self))
        HLBasePopup.registry[key] = WeakPopupRef(popup: self)
        
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve

        window.rootViewController?.topMost.present(self, animated: false) {
            self.animateIn()
        }
    }

    /// 消失弹窗（任意地方可调用）
    public func dismiss() {
        animateOut {
            self.dismiss(animated: false)
            let key = String(describing: Swift.type(of: self))
            HLBasePopup.registry.removeValue(forKey: key)
        }
    }

    // MARK: - Animation（子类可重写）

    open func animateIn() {
        UIView.animate(withDuration: 0.25) {
            self.hlMaskView.alpha = 1
        }
    }

    open func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, animations: {
            self.hlMaskView.alpha = 0
        }, completion: { _ in
            completion()
        })
    }

    // MARK: - Actions

    @objc private func onMaskTapped() {
        guard tapMaskToDismiss else { return }
        dismiss()
    }
}

// MARK: - UIViewController TopMost

private extension UIViewController {
    var topMost: UIViewController {
        if let presented = presentedViewController {
            return presented.topMost
        }
        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.topMost ?? self
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMost ?? self
        }
        return self
    }
}
