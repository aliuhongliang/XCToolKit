import CoreGraphics
import UIKit

public enum ScreenAdapter {
    private static let baseWidth: CGFloat = 375
    private static let baseHeight: CGFloat = 812

    public static var widthScale: CGFloat {
        UIScreen.main.bounds.width / baseWidth
    }

    public static var heightScale: CGFloat {
        UIScreen.main.bounds.height / baseHeight
    }

    public static func scaleWidth(_ value: CGFloat) -> CGFloat {
        value * widthScale
    }

    public static func scaleHeight(_ value: CGFloat) -> CGFloat {
        value * heightScale
    }
}
