import UIKit

public enum VisibleViewController {
    public static func top(from root: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap(\.windows)
        .first(where: \.isKeyWindow)?
        .rootViewController) -> UIViewController? {
        guard let root else { return nil }
        if let nav = root as? UINavigationController {
            return top(from: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return top(from: tab.selectedViewController)
        }
        if let presented = root.presentedViewController {
            return top(from: presented)
        }
        return root
    }
}
