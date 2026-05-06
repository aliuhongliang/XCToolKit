//
//  HLStringPickerController.swift
//  XCToolkit
//
//  单列字符串选择器，底部弹出
//
//  使用示例：
//  let picker = HLStringPickerController()
//  picker.setTitle("选择性别")
//  picker.setItems(["男", "女", "保密"])
//  picker.defaultIndex = 0
//  picker.onConfirm = { index, value in
//      print(index, value)
//  }
//  picker.show()

import UIKit

public final class HLStringPickerController: HLBasePopup {

    // MARK: - Public Config

    /// 默认选中的 index，默认 0
    public var defaultIndex: Int = 0

    /// 确认回调，返回选中的 index 和对应的值
    public var onConfirm: ((_ index: Int, _ value: String) -> Void)?

    // MARK: - Private

    private var titleText: String?
    private var items: [String] = []
    private var selectedIndex: Int = 0
    private var leftTitle: String? = "取消"
    private var rightTitle: String? = "确认"

    // MARK: - UI

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.layer.masksToBounds = true
        return v
    }()

    private let headerView = UIView()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .black
        l.textAlignment = .center
        return l
    }()

    private let leftButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = .systemFont(ofSize: 15)
        b.setTitleColor(UIColor(white: 0.4, alpha: 1), for: .normal)
        return b
    }()

    private let rightButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        b.setTitleColor(.systemBlue, for: .normal)
        return b
    }()

    private let headerSeparator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.9, alpha: 1)
        return v
    }()

    private lazy var pickerView: UIPickerView = {
        let pv = UIPickerView()
        pv.delegate = self
        pv.dataSource = self
        return pv
    }()

    // MARK: - Setup

    public override func setupContentView() {
        view.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Header
        containerView.addSubview(headerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 52),
        ])

        headerView.addSubview(leftButton)
        headerView.addSubview(rightButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(headerSeparator)

        leftButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerSeparator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            leftButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            leftButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),

            rightButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            rightButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leftButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: rightButton.leadingAnchor, constant: -8),

            headerSeparator.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            headerSeparator.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerSeparator.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerSeparator.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        leftButton.addTarget(self, action: #selector(onLeftTapped), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(onRightTapped), for: .touchUpInside)

        // PickerView
        containerView.addSubview(pickerView)
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pickerView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            pickerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            pickerView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
            pickerView.heightAnchor.constraint(equalToConstant: 216),
        ])
    }

    // MARK: - Public API

    public func setTitle(_ text: String) {
        titleText = text
    }

    public func setItems(_ items: [String]) {
        self.items = items
    }

    /// 自定义左侧按钮标题，传 nil 则隐藏
    public func setLeftAction(title: String?) {
        leftTitle = title
    }

    /// 自定义右侧按钮标题，传 nil 则隐藏
    public func setRightAction(title: String?) {
        rightTitle = title
    }

    // MARK: - Show Override

    public override func show() {
        titleLabel.text = titleText
        leftButton.setTitle(leftTitle, for: .normal)
        rightButton.setTitle(rightTitle, for: .normal)
        leftButton.isHidden = leftTitle == nil
        rightButton.isHidden = rightTitle == nil

        selectedIndex = max(0, min(defaultIndex, items.count - 1))
        pickerView.reloadAllComponents()

        if !items.isEmpty {
            pickerView.selectRow(selectedIndex, inComponent: 0, animated: false)
        }

        super.show()
    }

    // MARK: - Actions

    @objc private func onLeftTapped() {
        dismiss()
    }

    @objc private func onRightTapped() {
        guard !items.isEmpty else {
            dismiss()
            return
        }
        onConfirm?(selectedIndex, items[selectedIndex])
        dismiss()
    }

    // MARK: - Animation

    public override func animateIn() {
        containerView.transform = CGAffineTransform(translationX: 0, y: 300)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.maskView.alpha = 1
            self.containerView.transform = .identity
        }
    }

    public override func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.25, animations: {
            self.maskView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: 300)
        }, completion: { _ in completion() })
    }
}

// MARK: - UIPickerViewDataSource & Delegate

extension HLStringPickerController: UIPickerViewDataSource, UIPickerViewDelegate {

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return items.count
    }

    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return items[row]
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedIndex = row
    }
}
