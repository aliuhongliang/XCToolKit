import UIKit
import XCCore

open class BaseViewController: UIViewController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        Logger.log("Loaded \(String(describing: type(of: self)))")
    }
}
