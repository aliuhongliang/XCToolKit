//
//  HLSheetController.swift
//  XCToolkit
//
//  底部列表弹窗，支持单选/多选
//
//  使用示例：
//  let sheet = HLSheetController()
//  sheet.setTitle("请选择")
//  sheet.setItems(["选项一", "选项二", "选项三"])
//  sheet.selectionMode = .multiple
//  sheet.setLeftAction(title: "取消")
//  sheet.setRightAction(title: "确认") { indexes in
//      print(indexes)
//  }
//  sheet.show()

import UIKit

// MARK: - Selection Mode

public enum HLSheetSelectionMode {
    case single
    case multiple
}

// MARK: - HLSheetController

public final class HLSheetController: HLBasePopup {

    // MARK: - Public Config

    /// 选择模式，默认单选
    public var selectionMode: HLSheetSelectionMode = .single

    /// 选中回调（确认时触发，返回选中的 index 数组）
    public var onConfirm: (([Int]) -> Void)?

    // MARK: - Private

    private var titleText: String?
    private var items: [String] = []
    private var selectedIndexes: Set<Int> = []

    private var leftTitle: String?
    private var rightTitle: String?
    private var rightHandler: (([Int]) -> Void)?

    private var hasHeader: Bool { titleText != nil || leftTitle != nil || rightTitle != nil }

    // MARK: - UI

    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.layer.masksToBounds = true
        return v
    }()

    private let headerView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .black
        l.textAlignment = .center
        return l
    }()

    private let leftButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
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

    private let tableView: UITableView = {
        let t = UITableView()
        t.separatorStyle = .none
        t.rowHeight = 52
        t.showsVerticalScrollIndicator = false
        return t
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

        // 左按钮
        headerView.addSubview(leftButton)
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leftButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            leftButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
        ])
        leftButton.addTarget(self, action: #selector(onLeftTapped), for: .touchUpInside)

        // 右按钮
        headerView.addSubview(rightButton)
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rightButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            rightButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
        ])
        rightButton.addTarget(self, action: #selector(onRightTapped), for: .touchUpInside)

        // 标题
        headerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leftButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: rightButton.leadingAnchor, constant: -8),
        ])

        // Header 分割线
        headerView.addSubview(headerSeparator)
        headerSeparator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerSeparator.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            headerSeparator.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            headerSeparator.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            headerSeparator.heightAnchor.constraint(equalToConstant: 0.5),
        ])

        // TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(HLSheetCell.self, forCellReuseIdentifier: HLSheetCell.reuseID)

        containerView.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let maxHeight = UIScreen.main.bounds.height * 0.6
        let tableHeight = tableView.heightAnchor.constraint(equalToConstant: maxHeight)
        tableHeight.priority = .defaultHigh

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
            tableHeight,
        ])
    }

    // MARK: - Public API

    public func setTitle(_ text: String) {
        titleText = text
        titleLabel.text = text
    }

    public func setItems(_ items: [String]) {
        self.items = items
    }

    /// 设置左侧按钮（通常是取消），不设置则隐藏
    public func setLeftAction(title: String, handler: (() -> Void)? = nil) {
        leftTitle = title
        leftButton.setTitle(title, for: .normal)
    }

    /// 设置右侧按钮（通常是确认），不设置则隐藏
    public func setRightAction(title: String, handler: (([Int]) -> Void)? = nil) {
        rightTitle = title
        rightButton.setTitle(title, for: .normal)
        rightHandler = handler
    }

    // MARK: - Show Override

    public override func show() {
        leftButton.isHidden = leftTitle == nil
        rightButton.isHidden = rightTitle == nil
        headerView.isHidden = !hasHeader
        tableView.reloadData()
        super.show()
    }

    // MARK: - Actions

    @objc private func onLeftTapped() {
        dismiss()
    }

    @objc private func onRightTapped() {
        let indexes = Array(selectedIndexes).sorted()
        rightHandler?(indexes)
        onConfirm?(indexes)
        dismiss()
    }

    // MARK: - Animation Override

    public override func animateIn() {
        containerView.transform = CGAffineTransform(translationX: 0, y: containerView.bounds.height + 300)
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.maskView.alpha = 1
            self.containerView.transform = .identity
        }
    }

    public override func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.25, animations: {
            self.maskView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.containerView.bounds.height + 100)
        }, completion: { _ in completion() })
    }
}

// MARK: - UITableViewDataSource & Delegate

extension HLSheetController: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HLSheetCell.reuseID, for: indexPath) as! HLSheetCell
        let isSelected = selectedIndexes.contains(indexPath.row)
        cell.configure(title: items[indexPath.row], isSelected: isSelected)
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let index = indexPath.row

        switch selectionMode {
        case .single:
            selectedIndexes = [index]
            tableView.reloadData()
            // 单选直接回调并关闭
            onConfirm?([index])
            rightHandler?([index])
            dismiss()

        case .multiple:
            if selectedIndexes.contains(index) {
                selectedIndexes.remove(index)
            } else {
                selectedIndexes.insert(index)
            }
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}

// MARK: - HLSheetCell

private final class HLSheetCell: UITableViewCell {

    static let reuseID = "HLSheetCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16)
        l.textColor = .black
        return l
    }()

    private let checkmark: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "checkmark"))
        iv.tintColor = .systemBlue
        iv.isHidden = true
        return iv
    }()

    private let separator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.95, alpha: 1)
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        contentView.addSubview(checkmark)
        contentView.addSubview(separator)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        separator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: checkmark.leadingAnchor, constant: -8),

            checkmark.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmark.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            checkmark.widthAnchor.constraint(equalToConstant: 18),
            checkmark.heightAnchor.constraint(equalToConstant: 18),

            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, isSelected: Bool) {
        titleLabel.text = title
        checkmark.isHidden = !isSelected
        titleLabel.textColor = isSelected ? .systemBlue : .black
    }
}
