//
//  HLAlertController.swift
//  XCToolkit
//
//  中间弹窗，支持确认/取消/输入框
//
//  使用示例：
//  // 确认弹窗
//  let alert = HLAlertController()
//  alert.setHeader("提示")
//  alert.setTitle("退出登录")
//  alert.setContent("确定退出登录？")
//  alert.showCloseButton = true
//  alert.addAction(title: "取消", style: .cancel)
//  alert.addAction(title: "确认", style: .confirm) { self.request_logout() }
//  alert.show()
//
//  // 带输入框
//  let alert = HLAlertController()
//  alert.setTitle("请输入")
//  alert.addTextField(placeholder: "请输入姓名")
//  alert.addTextField(placeholder: "请输入手机号")
//  alert.addAction(title: "确认", style: .confirm) {
//      let values = alert.textFieldValues
//  }
//  alert.show()

import UIKit

// MARK: - Action Style

public enum HLAlertActionStyle {
    case confirm
    case cancel
    case destructive
}

// MARK: - Action Model

private struct HLAlertAction {
    let title: String
    let style: HLAlertActionStyle
    let handler: (() -> Void)?
}

// MARK: - TextField Config

private struct HLTextFieldConfig {
    let title: String?
    let placeholder: String?
}

// MARK: - HLAlertController

public final class HLAlertController: HLBasePopup {

    // MARK: - Public Config

    /// 是否显示右上角关闭按钮，默认 false
    public var showCloseButton: Bool = false {
        didSet { closeButton.isHidden = !showCloseButton }
    }

    /// 获取所有输入框的值（按添加顺序）
    public var textFieldValues: [String] {
        return textFields.map { $0.text ?? "" }
    }

    // MARK: - Private

    private var headerText: String?
    private var titleText: String?
    private var titleAttributed: NSAttributedString?
    private var contentText: String?
    private var contentAttributed: NSAttributedString?

    private var actions: [HLAlertAction] = []
    private var textFieldConfigs: [HLTextFieldConfig] = []
    private var textFields: [UITextField] = []

    // MARK: - UI

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.masksToBounds = true
        return v
    }()

    private let headerLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .regular)
        l.textColor = UIColor(white: 0.6, alpha: 1)
        l.textAlignment = .center
        l.isHidden = true
        return l
    }()

    private let closeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "xmark"), for: .normal)
        b.tintColor = UIColor(white: 0.6, alpha: 1)
        b.isHidden = true
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .black
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        return l
    }()

    private let contentLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = UIColor(white: 0.3, alpha: 1)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        return l
    }()

    private let textFieldStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 10
        s.isHidden = true
        return s
    }()

    private let buttonStack: UIStackView = {
        let s = UIStackView()
        s.spacing = 0
        s.distribution = .fillEqually
        return s
    }()

    private let separatorLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.9, alpha: 1)
        return v
    }()

    // MARK: - Setup

    public override func setupContentView() {
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 270),
        ])

        // 关闭按钮
        containerView.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),
        ])
        closeButton.addTarget(self, action: #selector(onCloseTapped), for: .touchUpInside)

        // 内容区 StackView
        let contentStack = UIStackView(arrangedSubviews: [
            headerLabel, titleLabel, contentLabel, textFieldStack
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 8
        contentStack.alignment = .fill

        containerView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
        ])

        // 分割线
        containerView.addSubview(separatorLine)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            separatorLine.topAnchor.constraint(equalTo: contentStack.bottomAnchor, constant: 20),
            separatorLine.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        // 按钮区
        containerView.addSubview(buttonStack)
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonStack.topAnchor.constraint(equalTo: separatorLine.bottomAnchor),
            buttonStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            buttonStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            buttonStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            buttonStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 50),
        ])
    }

    // MARK: - Public API

    /// 设置顶部小标题（header）
    public func setHeader(_ text: String) {
        headerText = text
        headerLabel.text = text
        headerLabel.isHidden = text.isEmpty
    }

    /// 设置主标题（普通文本）
    public func setTitle(_ text: String) {
        titleText = text
        titleLabel.text = text
        titleLabel.isHidden = text.isEmpty
    }

    /// 设置主标题（富文本）
    public func setTitle(attributedText: NSAttributedString) {
        titleAttributed = attributedText
        titleLabel.attributedText = attributedText
        titleLabel.isHidden = false
    }

    /// 设置内容（普通文本）
    public func setContent(_ text: String) {
        contentText = text
        contentLabel.text = text
        contentLabel.isHidden = text.isEmpty
    }

    /// 设置内容（富文本）
    public func setContent(attributedText: NSAttributedString) {
        contentAttributed = attributedText
        contentLabel.attributedText = attributedText
        contentLabel.isHidden = false
    }

    /// 添加输入框（最多 5 个）
    public func addTextField(title: String? = nil, placeholder: String? = nil) {
        guard textFieldConfigs.count < 5 else { return }
        textFieldConfigs.append(HLTextFieldConfig(title: title, placeholder: placeholder))
    }

    /// 添加按钮
    public func addAction(title: String, style: HLAlertActionStyle = .confirm, handler: (() -> Void)? = nil) {
        actions.append(HLAlertAction(title: title, style: style, handler: handler))
    }

    // MARK: - Show Override

    public override func show() {
        buildTextFields()
        buildButtons()
        super.show()
    }

    // MARK: - Build UI

    private func buildTextFields() {
        guard !textFieldConfigs.isEmpty else { return }
        textFieldStack.isHidden = false

        for config in textFieldConfigs {
            let wrapper = UIView()

            // 可选标题
            if let title = config.title, !title.isEmpty {
                let label = UILabel()
                label.text = title
                label.font = .systemFont(ofSize: 13, weight: .regular)
                label.textColor = UIColor(white: 0.4, alpha: 1)
                wrapper.addSubview(label)
                label.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    label.topAnchor.constraint(equalTo: wrapper.topAnchor),
                    label.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
                    label.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
                ])

                let tf = makeTextField(placeholder: config.placeholder)
                wrapper.addSubview(tf)
                tf.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    tf.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
                    tf.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
                    tf.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
                    tf.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
                    tf.heightAnchor.constraint(equalToConstant: 40),
                ])
                textFields.append(tf)
            } else {
                let tf = makeTextField(placeholder: config.placeholder)
                wrapper.addSubview(tf)
                tf.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    tf.topAnchor.constraint(equalTo: wrapper.topAnchor),
                    tf.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
                    tf.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
                    tf.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
                    tf.heightAnchor.constraint(equalToConstant: 40),
                ])
                textFields.append(tf)
            }
            textFieldStack.addArrangedSubview(wrapper)
        }
    }

    private func makeTextField(placeholder: String?) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.font = .systemFont(ofSize: 14)
        tf.borderStyle = .none
        tf.backgroundColor = UIColor(white: 0.96, alpha: 1)
        tf.layer.cornerRadius = 8
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        tf.leftViewMode = .always
        tf.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        tf.rightViewMode = .always
        return tf
    }

    private func buildButtons() {
        // 垂直布局（> 3个）
        let isVertical = actions.count > 3
        buttonStack.axis = isVertical ? .vertical : .horizontal
        buttonStack.distribution = .fill

        for (index, action) in actions.enumerated() {
            let button = makeButton(action)

            if index > 0 {
                let line = UIView()
                line.backgroundColor = UIColor(white: 0.9, alpha: 1)
                buttonStack.addArrangedSubview(line)
                line.translatesAutoresizingMaskIntoConstraints = false
                if isVertical {
                    line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
                } else {
                    line.widthAnchor.constraint(equalToConstant: 0.5).isActive = true
                }
            }
            buttonStack.addArrangedSubview(button)

            // 横向布局：所有按钮等宽
            if !isVertical, let first = buttonStack.arrangedSubviews.first(where: { $0 is UIButton }) as? UIButton, button != first {
                button.widthAnchor.constraint(equalTo: first.widthAnchor).isActive = true
            }
        }
    }

    private func makeButton(_ action: HLAlertAction) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(action.title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: action.style == .confirm ? .semibold : .regular)

        switch action.style {
        case .confirm:
            button.setTitleColor(UIColor.systemBlue, for: .normal)
        case .cancel:
            button.setTitleColor(UIColor(white: 0.4, alpha: 1), for: .normal)
        case .destructive:
            button.setTitleColor(UIColor.systemRed, for: .normal)
        }

        button.heightAnchor.constraint(equalToConstant: 50).isActive = true

        // 高亮效果
        button.addTarget(self, action: #selector(buttonHighlight(_:)), for: .touchDown)
        button.addTarget(self, action: #selector(buttonNormal(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        // 绑定 action
        let wrapper = HLActionWrapper(action: action.handler)
        button.addTarget(wrapper, action: #selector(HLActionWrapper.invoke), for: .touchUpInside)
        objc_setAssociatedObject(button, &AssociatedKeys.actionWrapper, wrapper, .OBJC_ASSOCIATION_RETAIN)

        // confirm 点击后收集输入值再 dismiss
        if action.style == .confirm || action.style == .destructive {
            button.addTarget(self, action: #selector(onActionTapped), for: .touchUpInside)
        } else {
            button.addTarget(self, action: #selector(onCancelTapped), for: .touchUpInside)
        }

        return button
    }

    // MARK: - Actions

    @objc private func onCloseTapped() {
        dismiss()
    }

    @objc private func onCancelTapped() {
        dismiss()
    }

    @objc private func onActionTapped() {
        // 先收集输入框值（在 dismiss 之前），值已通过 textFieldValues 暴露
        view.endEditing(true)
        dismiss()
    }

    @objc private func buttonHighlight(_ sender: UIButton) {
        sender.backgroundColor = UIColor(white: 0.95, alpha: 1)
    }

    @objc private func buttonNormal(_ sender: UIButton) {
        sender.backgroundColor = .clear
    }

    // MARK: - Animation Override

    public override func animateIn() {
        containerView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        containerView.alpha = 0
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.maskView.alpha = 1
            self.containerView.transform = .identity
            self.containerView.alpha = 1
        }
    }

    public override func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.2, animations: {
            self.maskView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.containerView.alpha = 0
        }, completion: { _ in completion() })
    }
}

// MARK: - Associated Keys

private enum AssociatedKeys {
    static var actionWrapper = "actionWrapper"
}

// MARK: - Action Wrapper（解决 closure target-action 问题）

private final class HLActionWrapper: NSObject {
    let action: (() -> Void)?
    init(action: (() -> Void)?) { self.action = action }

    @objc func invoke() { action?() }
}
