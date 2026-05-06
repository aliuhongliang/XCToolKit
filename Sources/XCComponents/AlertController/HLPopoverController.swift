//
//  HLPopoverController.swift
//  XCToolkit
//
//  气泡弹层，支持列表单选和自定义内容，自动计算弹出方向
//
//  使用示例：
//  // 列表单选
//  let popover = HLPopoverController()
//  popover.setItems(["编辑", "删除", "分享"])
//  popover.onSelect = { index in print(index) }
//  popover.show(from: someButton)
//
//  // 自定义内容
//  let popover = HLPopoverController()
//  popover.setCustomView(myView, size: CGSize(width: 200, height: 150))
//  popover.show(from: someButton)

import UIKit

public final class HLPopoverController: HLBasePopup {

    // MARK: - Public Config

    /// 列表选中回调
    public var onSelect: ((Int) -> Void)?

    /// Popover 宽度，默认 160
    public var popoverWidth: CGFloat = 160

    /// 每行高度，默认 44
    public var itemHeight: CGFloat = 44

    // MARK: - Private

    private enum PopoverMode {
        case list([String])
        case custom(UIView, CGSize)
    }

    enum ArrowDirection {
        case up, down, left, right
    }

    private var mode: PopoverMode = .list([])
    private var arrowDirection: ArrowDirection = .up
    private var anchorFrame: CGRect = .zero

    // Arrow 尺寸
    private let arrowWidth: CGFloat = 12
    private let arrowHeight: CGFloat = 7

    // MARK: - UI

    private let popoverContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 10
        v.layer.masksToBounds = false
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.15
        v.layer.shadowOffset = CGSize(width: 0, height: 4)
        v.layer.shadowRadius = 10
        return v
    }()

    private let arrowView = HLArrowView()

    private let tableView: UITableView = {
        let t = UITableView()
        t.separatorStyle = .none
        t.showsVerticalScrollIndicator = false
        t.isScrollEnabled = false
        t.layer.cornerRadius = 10
        t.layer.masksToBounds = true
        return t
    }()

    // MARK: - Setup

    public override func setupContentView() {
        // 点击空白区域关闭
        maskView.backgroundColor = .clear

        view.addSubview(arrowView)
        view.addSubview(popoverContainer)
    }

    // MARK: - Public API

    public func setItems(_ items: [String]) {
        mode = .list(items)
    }

    public func setCustomView(_ customView: UIView, size: CGSize) {
        mode = .custom(customView, size)
    }

    /// 从指定控件弹出
    public func show(from sourceView: UIView) {
        guard let window = sourceView.window else { return }
        anchorFrame = sourceView.convert(sourceView.bounds, to: window)
        calculateDirection(in: window)
        super.show()
    }

    // MARK: - Show Override

    public override func show() {
        // 需要通过 show(from:) 调用，直接 show 不处理
    }

    // MARK: - Layout

    private func calculateDirection(in window: UIView) {
        let screenHeight = window.bounds.height
        let screenWidth = window.bounds.width
        let spaceBelow = screenHeight - anchorFrame.maxY
        let spaceAbove = anchorFrame.minY
        let spaceRight = screenWidth - anchorFrame.maxX
        let spaceLeft = anchorFrame.minX

        let contentSize = calculateContentSize()
        let neededHeight = contentSize.height + arrowHeight + 8

        if spaceBelow >= neededHeight {
            arrowDirection = .up
        } else if spaceAbove >= neededHeight {
            arrowDirection = .down
        } else if spaceRight >= contentSize.width + arrowHeight {
            arrowDirection = .right
        } else if spaceLeft >= contentSize.width + arrowHeight {
            arrowDirection = .left
        } else {
            arrowDirection = .up
        }
    }

    private func calculateContentSize() -> CGSize {
        switch mode {
        case .list(let items):
            return CGSize(width: popoverWidth, height: CGFloat(items.count) * itemHeight)
        case .custom(_, let size):
            return size
        }
    }

    private func layoutPopover() {
        let contentSize = calculateContentSize()
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height

        buildContent(contentSize: contentSize)

        // 计算 popoverContainer 的 origin
        var containerX: CGFloat = 0
        var containerY: CGFloat = 0
        var arrowX: CGFloat = 0
        var arrowY: CGFloat = 0

        let anchorCenterX = anchorFrame.midX
        let anchorCenterY = anchorFrame.midY

        switch arrowDirection {
        case .up:
            containerY = anchorFrame.maxY + arrowHeight + 4
            containerX = min(max(anchorCenterX - contentSize.width / 2, 8), screenWidth - contentSize.width - 8)
            arrowX = anchorCenterX - arrowWidth / 2
            arrowY = anchorFrame.maxY + 2

        case .down:
            containerY = anchorFrame.minY - arrowHeight - 4 - contentSize.height
            containerX = min(max(anchorCenterX - contentSize.width / 2, 8), screenWidth - contentSize.width - 8)
            arrowX = anchorCenterX - arrowWidth / 2
            arrowY = anchorFrame.minY - arrowHeight - 2

        case .right:
            containerX = anchorFrame.maxX + arrowHeight + 4
            containerY = min(max(anchorCenterY - contentSize.height / 2, 8), screenHeight - contentSize.height - 8)
            arrowX = anchorFrame.maxX + 2
            arrowY = anchorCenterY - arrowWidth / 2

        case .left:
            containerX = anchorFrame.minX - arrowHeight - 4 - contentSize.width
            containerY = min(max(anchorCenterY - contentSize.height / 2, 8), screenHeight - contentSize.height - 8)
            arrowX = anchorFrame.minX - arrowHeight - 2
            arrowY = anchorCenterY - arrowWidth / 2
        }

        popoverContainer.frame = CGRect(origin: CGPoint(x: containerX, y: containerY), size: contentSize)

        // Arrow
        arrowView.direction = arrowDirection
        switch arrowDirection {
        case .up, .down:
            arrowView.frame = CGRect(x: arrowX, y: arrowY, width: arrowWidth, height: arrowHeight)
        case .left, .right:
            arrowView.frame = CGRect(x: arrowX, y: arrowY, width: arrowHeight, height: arrowWidth)
        }
    }

    private func buildContent(contentSize: CGSize) {
        popoverContainer.subviews.forEach { $0.removeFromSuperview() }

        switch mode {
        case .list(let items):
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(HLPopoverCell.self, forCellReuseIdentifier: HLPopoverCell.reuseID)
            tableView.rowHeight = itemHeight
            tableView.frame = CGRect(origin: .zero, size: contentSize)
            popoverContainer.addSubview(tableView)

        case .custom(let customView, let size):
            customView.frame = CGRect(origin: .zero, size: size)
            customView.layer.cornerRadius = 10
            customView.layer.masksToBounds = true
            popoverContainer.addSubview(customView)
        }
    }

    // MARK: - Animation Override

    public override func animateIn() {
        layoutPopover()

        popoverContainer.alpha = 0
        popoverContainer.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        arrowView.alpha = 0

        // 设置缩放锚点
        switch arrowDirection {
        case .up:
            setAnchorPoint(CGPoint(x: 0.5, y: 0), for: popoverContainer)
        case .down:
            setAnchorPoint(CGPoint(x: 0.5, y: 1), for: popoverContainer)
        case .right:
            setAnchorPoint(CGPoint(x: 0, y: 0.5), for: popoverContainer)
        case .left:
            setAnchorPoint(CGPoint(x: 1, y: 0.5), for: popoverContainer)
        }

        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0) {
            self.maskView.alpha = 1
            self.popoverContainer.alpha = 1
            self.popoverContainer.transform = .identity
            self.arrowView.alpha = 1
        }
    }

    public override func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.15, animations: {
            self.maskView.alpha = 0
            self.popoverContainer.alpha = 0
            self.popoverContainer.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.arrowView.alpha = 0
        }, completion: { _ in completion() })
    }

    private func setAnchorPoint(_ point: CGPoint, for view: UIView) {
        let oldFrame = view.frame
        view.layer.anchorPoint = point
        view.frame = oldFrame
    }
}

// MARK: - UITableViewDataSource & Delegate

extension HLPopoverController: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if case .list(let items) = mode { return items.count }
        return 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HLPopoverCell.reuseID, for: indexPath) as! HLPopoverCell
        if case .list(let items) = mode {
            let isLast = indexPath.row == items.count - 1
            cell.configure(title: items[indexPath.row], showSeparator: !isLast)
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        onSelect?(indexPath.row)
        dismiss()
    }
}

// MARK: - HLPopoverCell

private final class HLPopoverCell: UITableViewCell {

    static let reuseID = "HLPopoverCell"

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = .black
        l.textAlignment = .center
        return l
    }()

    private let separator: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.92, alpha: 1)
        return v
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        contentView.addSubview(titleLabel)
        contentView.addSubview(separator)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        separator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),

            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            separator.heightAnchor.constraint(equalToConstant: 0.5),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, showSeparator: Bool) {
        titleLabel.text = title
        separator.isHidden = !showSeparator
    }
}

// MARK: - HLArrowView

private final class HLArrowView: UIView {

    var direction: HLPopoverController.ArrowDirection = .up {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        UIColor.white.setFill()

        let path = UIBezierPath()
        switch direction {
        case .up:
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        case .down:
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        case .right:
            path.move(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        case .left:
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        path.close()
        ctx.addPath(path.cgPath)
        ctx.fillPath()
    }
}
