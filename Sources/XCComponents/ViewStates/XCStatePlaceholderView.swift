import UIKit

public final class StatePlaceholderView: UIView {
    public enum State {
        case loading
        case empty(message: String)
        case error(message: String)
    }

    private let stack = UIStackView()
    private let indicator = UIActivityIndicatorView(style: .medium)
    private let label = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    public func render(_ state: State) {
        switch state {
        case .loading:
            indicator.startAnimating()
            label.text = "Loading..."
        case let .empty(message):
            indicator.stopAnimating()
            label.text = message
        case let .error(message):
            indicator.stopAnimating()
            label.text = message
        }
    }

    private func setup() {
        backgroundColor = .clear

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8

        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0

        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        stack.addArrangedSubview(indicator)
        stack.addArrangedSubview(label)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16)
        ])
    }
}
