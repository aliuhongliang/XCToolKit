import UIKit

// MARK: - Button Style

public enum HLAlertButtonStyle {
    case `default`
    case cancel
    case destructive
    case custom(UIColor)
}

// MARK: - Alert Action

public final class HLAlertViewAction {
    public let title: String
    public let style: HLAlertButtonStyle
    public let handler: ((HLAlertViewAction) -> Void)?
    
    public weak var alert: HLAlert?
    
    init(title: String, style: HLAlertButtonStyle, handler: ((HLAlertViewAction) -> Void)?) {
        self.title = title
        self.style = style
        self.handler = handler
    }
    
    public static func `default`(_ title: String, handler: ((HLAlertViewAction) -> Void)? = nil) -> HLAlertViewAction {
        HLAlertViewAction(title: title, style: .default, handler: handler)
    }
    
    public static func cancel(_ title: String = "取消", handler: ((HLAlertViewAction) -> Void)? = nil) -> HLAlertViewAction {
        HLAlertViewAction(title: title, style: .cancel, handler: handler)
    }
    
    public static func destructive(_ title: String, handler: ((HLAlertViewAction) -> Void)? = nil) -> HLAlertViewAction {
        HLAlertViewAction(title: title, style: .destructive, handler: handler)
    }
    
    public static func custom(_ title: String, color: UIColor, handler: ((HLAlertViewAction) -> Void)? = nil) -> HLAlertViewAction {
        HLAlertViewAction(title: title, style: .custom(color), handler: handler)
    }
}

// MARK: - HLAlert

public final class HLAlert {
    public let title: String?
    public let message: String?
    public var attributedTitle: NSAttributedString?
    public var attributedMessage: NSAttributedString?
    public var actions: [HLAlertViewAction] = []
    public var textFieldInstances: [UITextField] = []
    public var textFields: [UITextField] = []
    
    public var canDismissByBackdrop: Bool = true
    public var showCloseButton: Bool = false
    public var preferredWidth: CGFloat = 270
    
    public var onDismiss: ((HLAlert) -> Void)?
    
    private lazy var backdropView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.alpha = 0
        return view
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 14
        view.layer.masksToBounds = true
        view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        view.alpha = 0
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.alignment = .fill
        return stack
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 0
        stack.distribution = .fillEqually
        stack.alignment = .fill
        return stack
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .secondaryLabel
        button.isHidden = true
        return button
    }()
    
    private var isShowing = false
    private static var activeAlerts: [HLAlert] = []
    
    public init(title: String? = nil, message: String? = nil) {
        self.title = title
        self.message = message
    }
    
    // MARK: - Public API
    
    public func addAction(_ action: HLAlertViewAction) {
        action.alert = self
        actions.append(action)
    }
    
    public func addTextField(configure: ((UITextField) -> Void)? = nil) {
        guard textFieldInstances.count < 2 else { return }
        let tf = UITextField()
        configure?(tf)
        textFieldInstances.append(tf)
    }
    
    public func show(in window: UIWindow? = nil) {
        guard !isShowing else { return }
        isShowing = true
        Self.activeAlerts.append(self)
        
        guard let targetWindow = window ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        else {
            isShowing = false
            return
        }
        
        setupUI()
        layoutContent()
        
        targetWindow.addSubview(backdropView)
        targetWindow.addSubview(containerView)
        
        backdropView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backdropView.topAnchor.constraint(equalTo: targetWindow.topAnchor),
            backdropView.leadingAnchor.constraint(equalTo: targetWindow.leadingAnchor),
            backdropView.trailingAnchor.constraint(equalTo: targetWindow.trailingAnchor),
            backdropView.bottomAnchor.constraint(equalTo: targetWindow.bottomAnchor),
            
            containerView.centerXAnchor.constraint(equalTo: targetWindow.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: targetWindow.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: preferredWidth),
            containerView.widthAnchor.constraint(lessThanOrEqualTo: targetWindow.widthAnchor, multiplier: 0.85),
        ])
        
        backdropView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backdropTapped)))
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.curveEaseOut], animations: {
            self.backdropView.alpha = 1
            self.containerView.transform = .identity
            self.containerView.alpha = 1
        })
    }
    
    public func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        guard isShowing else { return }
        
        let dismissBlock = { [weak self] in
            guard let self = self else { return }
            Self.activeAlerts.removeAll { $0 === self }
            self.backdropView.removeFromSuperview()
            self.containerView.removeFromSuperview()
            self.isShowing = false
            self.onDismiss?(self)
            completion?()
        }
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.backdropView.alpha = 0
                self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                self.containerView.alpha = 0
            }, completion: { _ in
                dismissBlock()
            })
        } else {
            dismissBlock()
        }
    }
    
    // MARK: - Private
    
    private func setupUI() {
        containerView.addSubview(contentStackView)
        containerView.addSubview(closeButton)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
        ])
        
        if let attributedTitle = attributedTitle {
            titleLabel.isHidden = false
            titleLabel.attributedText = attributedTitle
        } else {
            titleLabel.isHidden = title?.isEmpty ?? true
            titleLabel.text = title
        }
        
        if let attributedMessage = attributedMessage {
            messageLabel.isHidden = false
            messageLabel.attributedText = attributedMessage
        } else {
            messageLabel.isHidden = message?.isEmpty ?? true
            messageLabel.text = message
        }
    }
    
    private func layoutContent() {
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buttonStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        textFields.removeAll()
        
        let hasTitle = attributedTitle != nil || !(title?.isEmpty ?? true)
        let hasMessage = attributedMessage != nil || !(message?.isEmpty ?? true)
        let hasTextFields = !textFieldInstances.isEmpty
        
        if hasTitle {
            let titleContainer = UIView()
            titleContainer.addSubview(titleLabel)
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: titleContainer.topAnchor, constant: 18),
                titleLabel.leadingAnchor.constraint(equalTo: titleContainer.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: titleContainer.trailingAnchor, constant: -16),
                titleLabel.bottomAnchor.constraint(equalTo: titleContainer.bottomAnchor),
            ])
            contentStackView.addArrangedSubview(titleContainer)
        }
        
        if hasMessage {
            let messageContainer = UIView()
            messageContainer.addSubview(messageLabel)
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            let topConstant: CGFloat = hasTitle ? 8 : 18
            NSLayoutConstraint.activate([
                messageLabel.topAnchor.constraint(equalTo: messageContainer.topAnchor, constant: topConstant),
                messageLabel.leadingAnchor.constraint(equalTo: messageContainer.leadingAnchor, constant: 16),
                messageLabel.trailingAnchor.constraint(equalTo: messageContainer.trailingAnchor, constant: -16),
                messageLabel.bottomAnchor.constraint(equalTo: messageContainer.bottomAnchor, constant: -16),
            ])
            contentStackView.addArrangedSubview(messageContainer)
        }
        
        if hasTextFields {
            let textFieldContainer = UIView()
            textFieldContainer.translatesAutoresizingMaskIntoConstraints = false
            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = 8
            stack.alignment = .fill
            stack.distribution = .fill
            stack.translatesAutoresizingMaskIntoConstraints = false
            
            for (index, tf) in textFieldInstances.enumerated() {
                textFields.append(tf)
                stack.addArrangedSubview(tf)
            }
            
            textFieldContainer.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: textFieldContainer.topAnchor, constant: hasTitle || hasMessage ? 8 : 18),
                stack.leadingAnchor.constraint(equalTo: textFieldContainer.leadingAnchor, constant: 16),
                stack.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor, constant: -16),
                stack.bottomAnchor.constraint(equalTo: textFieldContainer.bottomAnchor, constant: -16),
            ])
            contentStackView.addArrangedSubview(textFieldContainer)
        }
        
        let buttonContainer = UIView()
        buttonContainer.translatesAutoresizingMaskIntoConstraints = false
        buttonContainer.addSubview(buttonStackView)
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let isVerticalButtons = actions.count > 3
        
        buttonStackView.axis = isVerticalButtons ? .vertical : .horizontal
        buttonStackView.spacing = isVerticalButtons ? 1 / UIScreen.main.scale : 0
        buttonStackView.distribution = isVerticalButtons ? .fillEqually : .fillEqually
        
        if isVerticalButtons {
            for (index, action) in actions.enumerated() {
                let btn = makeButton(for: action)
                btn.tag = index
                buttonStackView.addArrangedSubview(btn)
                if index < actions.count - 1 {
                    let separator = UIView()
                    separator.backgroundColor = .separator
                    separator.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
                    ])
                    btn.addSubview(separator)
                    NSLayoutConstraint.activate([
                        separator.leadingAnchor.constraint(equalTo: btn.leadingAnchor, constant: 16),
                        separator.trailingAnchor.constraint(equalTo: btn.trailingAnchor),
                        separator.bottomAnchor.constraint(equalTo: btn.bottomAnchor),
                    ])
                }
            }
        } else {
            for (index, action) in actions.enumerated() {
                let btn = makeButton(for: action)
                btn.tag = index
                buttonStackView.addArrangedSubview(btn)
                if index > 0 {
                    let separator = UIView()
                    separator.backgroundColor = .separator
                    separator.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        separator.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
                    ])
                    buttonStackView.insertArrangedSubview(separator, at: buttonStackView.arrangedSubviews.count - 2)
                }
            }
        }
        
        let topPadding: CGFloat
        if hasTitle || hasMessage || hasTextFields {
            topPadding = hasTextFields ? 0 : 16
        } else {
            topPadding = 18
        }
        
        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: buttonContainer.topAnchor, constant: topPadding),
            buttonStackView.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
            buttonStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])
        
        contentStackView.addArrangedSubview(buttonContainer)
        
        if !showCloseButton {
            closeButton.isHidden = true
        }
    }
    
    private func makeButton(for action: HLAlertViewAction) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(action.title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        btn.titleLabel?.textAlignment = .center
        btn.titleLabel?.numberOfLines = 0
        
        switch action.style {
        case .default:
            btn.setTitleColor(.systemBlue, for: .normal)
        case .cancel:
            btn.setTitleColor(.systemBlue, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        case .destructive:
            btn.setTitleColor(.systemRed, for: .normal)
        case .custom(let color):
            btn.setTitleColor(color, for: .normal)
        }
        
        btn.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return btn
    }
    
    @objc private func backdropTapped() {
        guard canDismissByBackdrop else { return }
        dismiss()
    }
    
    @objc private func closeButtonTapped() {
        dismiss()
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        guard sender.tag < actions.count else { return }
        let action = actions[sender.tag]
        action.handler?(action)
        dismiss()
    }
    
    @objc private func textFieldDidChange(_ sender: UITextField) {
        // 用户可通过 addTarget 自行监听
    }
}
