import Foundation
import UIKit

public extension String {
    var isBlank: Bool {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var toInt: Int? {
        Int(self)
    }
}

public extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
