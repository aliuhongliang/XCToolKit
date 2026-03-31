import UIKit

public enum Toast {
    public static func show(
        _ message: String,
        in view: UIView? = nil,
        duration: TimeInterval = 1.5
    ) {
        guard !message.isEmpty else { return }
        guard let container = view ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        else { return }

        let label = PaddingLabel()
        label.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = message
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.alpha = 0

        let maxWidth = container.bounds.width * 0.7
        let expected = label.sizeThatFits(CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        label.frame = CGRect(
            x: (container.bounds.width - min(expected.width, maxWidth)) / 2,
            y: container.bounds.height * 0.75,
            width: min(expected.width, maxWidth),
            height: expected.height
        )

        container.addSubview(label)
        UIView.animate(withDuration: 0.2, animations: {
            label.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: duration, options: [.curveEaseInOut], animations: {
                label.alpha = 0
            }) { _ in
                label.removeFromSuperview()
            }
        }
    }
}

private final class PaddingLabel: UILabel {
    private let insets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let fit = super.sizeThatFits(
            CGSize(width: size.width - insets.left - insets.right, height: size.height - insets.top - insets.bottom)
        )
        return CGSize(width: fit.width + insets.left + insets.right, height: fit.height + insets.top + insets.bottom)
    }
}
