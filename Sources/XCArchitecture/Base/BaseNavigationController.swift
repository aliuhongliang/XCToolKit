//
//  BaseNavigationController.swift
//  XCToolkit
//
//  Created by wintop on 2026/3/31.
//

import UIKit

open class BaseNavigationController: UINavigationController, UINavigationControllerDelegate {

    open override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isTranslucent = true  // 导航栏和底部融为一体，导航栏颜色设置透明会漏出底部控制器的背景色
//        navigationBar.isTranslucent = false // 导航栏独立一块，设置透明，会显示未黑色
    }

    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {

        if self.viewControllers.count >= 1 {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }
    open override var shouldAutorotate: Bool {
        return topViewController?.shouldAutorotate ?? true
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations ?? .portrait
    }
}
