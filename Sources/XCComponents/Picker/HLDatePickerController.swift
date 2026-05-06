//
//  HLDatePickerController.swift
//  XCToolkit
//
//  日期时间选择器，底部弹出
//
//  使用示例：
//  let picker = HLDatePickerController()
//  picker.setTitle("选择日期")
//  picker.mode = .date
//  picker.defaultDate = Date()
//  picker.minimumDate = Calendar.current.date(byAdding: .year, value: -10, to: Date())
//  picker.maximumDate = Date()
//  picker.onConfirm = { date in print(date) }
//  picker.show()

import UIKit

// MARK: - HLDatePickerMode

public enum HLDatePickerMode {
    /// 年月日
    case date
    /// 年月（自定义 UIPickerView）
    case yearMonth
    /// 时分
    case time
    /// 年月日 时分
    case dateTime
    /// 倒计时（时 分）
    case countDown
}

// MARK: - HLDatePickerController

public final class HLDatePickerController: HLBasePopup {

    // MARK: - Public Config

    /// 选择模式，默认年月日
    public var mode: HLDatePickerMode = .date

    /// 默认选中日期，默认当前时间
    public var defaultDate: Date = Date()

    /// 最小日期（不设置则不限制）
    public var minimumDate: Date? = nil

    /// 最大日期（不设置则不限制）
    public var maximumDate: Date? = nil

    /// 年月模式下的年份范围，默认前后各 50 年
    public var yearRange: ClosedRange<Int> = {
        let current = Calendar.current.component(.year, from: Date())
        return (current - 50)...(current + 50)
    }()

    /// 确认回调
    public var onConfirm: ((Date) -> Void)?

    // MARK: - Private

    private var titleText: String?
    private var leftTitle: String? = "取消"
    private var rightTitle: String? = "确认"

    /// yearMonth 模式下选中的年月
    private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    private var selectedMonth: Int = Calendar.current.component(.month, from: Date())

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

    /// 系统 DatePicker（date / time / dateTime / countDown）
    private lazy var datePicker: UIDatePicker = {
        let dp = UIDatePicker()
        if #available(iOS 13.4, *) {
            dp.preferredDatePickerStyle = .wheels
        } else {
            // Fallback on earlier versions
        }
        dp.locale = Locale(identifier: "zh_CN")
        return dp
    }()

    /// 自定义 PickerView（yearMonth）
    private lazy var yearMonthPicker: UIPickerView = {
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
    }

    // MARK: - Public API

    public func setTitle(_ text: String) {
        titleText = text
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

        super.show()
        setupPickerView()
    }

    // MARK: - Private

    private func setupPickerView() {
        if mode == .yearMonth {
            setupYearMonthPicker()
        } else {
            setupDatePicker()
        }
    }

    private func setupDatePicker() {
        containerView.addSubview(datePicker)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            datePicker.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            datePicker.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
        ])

        switch mode {
        case .date:         datePicker.datePickerMode = .date
        case .time:         datePicker.datePickerMode = .time
        case .dateTime:     datePicker.datePickerMode = .dateAndTime
        case .countDown:    datePicker.datePickerMode = .countDownTimer
        default: break
        }

        datePicker.date = defaultDate
        if let min = minimumDate { datePicker.minimumDate = min }
        if let max = maximumDate { datePicker.maximumDate = max }
    }

    private func setupYearMonthPicker() {
        // 初始化选中年月
        selectedYear = Calendar.current.component(.year, from: defaultDate)
        selectedMonth = Calendar.current.component(.month, from: defaultDate)

        containerView.addSubview(yearMonthPicker)
        yearMonthPicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            yearMonthPicker.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            yearMonthPicker.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            yearMonthPicker.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            yearMonthPicker.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
            yearMonthPicker.heightAnchor.constraint(equalToConstant: 216),
        ])

        // 滚动到默认年月
        let yearIndex = selectedYear - yearRange.lowerBound

        yearMonthPicker.selectRow(yearIndex, inComponent: 0, animated: false)
        yearMonthPicker.selectRow(selectedMonth - 1, inComponent: 1, animated: false)

        applyYearMonthLimit()
    }

    /// 应用年月范围限制
    private func applyYearMonthLimit() {
        guard mode == .yearMonth else { return }

        if let min = minimumDate {
            let minYear = Calendar.current.component(.year, from: min)
            let minMonth = Calendar.current.component(.month, from: min)
            if selectedYear < minYear || (selectedYear == minYear && selectedMonth < minMonth) {
                selectedYear = minYear
                selectedMonth = minMonth
            }
        }

        if let max = maximumDate {
            let maxYear = Calendar.current.component(.year, from: max)
            let maxMonth = Calendar.current.component(.month, from: max)
            if selectedYear > maxYear || (selectedYear == maxYear && selectedMonth > maxMonth) {
                selectedYear = maxYear
                selectedMonth = maxMonth
            }
        }
    }

    /// 把 yearMonth 的选中值转换为 Date
    private func yearMonthToDate() -> Date {
        var components = DateComponents()
        components.year = selectedYear
        components.month = selectedMonth
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - Actions

    @objc private func onLeftTapped() {
        dismiss()
    }

    @objc private func onRightTapped() {
        switch mode {
        case .yearMonth:
            onConfirm?(yearMonthToDate())
        default:
            onConfirm?(datePicker.date)
        }
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

// MARK: - UIPickerViewDataSource & Delegate（yearMonth）

extension HLDatePickerController: UIPickerViewDataSource, UIPickerViewDelegate {

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2  // 年 | 月
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return component == 0 ? yearRange.count : 12
    }

    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return "\(yearRange.lowerBound + row)年"
        } else {
            return "\(row + 1)月"
        }
    }

    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            selectedYear = yearRange.lowerBound + row
        } else {
            selectedMonth = row + 1
        }
        applyYearMonthLimit()

        // 如果限制了范围，需要同步 UI
        let yearIndex = selectedYear - yearRange.lowerBound

        pickerView.selectRow(yearIndex, inComponent: 0, animated: true)
        pickerView.selectRow(selectedMonth - 1, inComponent: 1, animated: true)
    }
}
