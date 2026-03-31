import CoreGraphics
import Foundation
import UIKit
import XCCore

public extension String {
    var xc_isPhoneNumber: Bool { RegexValidator.isPhoneNumber(self) }
    var xc_isEmail: Bool { RegexValidator.isEmail(self) }
    var xc_isDigitsOnly: Bool { RegexValidator.isDigitsOnly(self) }

    func xc_textSize(
        font: UIFont,
        constrainedTo size: CGSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    ) -> CGSize {
        let rect = (self as NSString).boundingRect(
            with: size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return CGSize(width: ceil(rect.width), height: ceil(rect.height))
    }
}
