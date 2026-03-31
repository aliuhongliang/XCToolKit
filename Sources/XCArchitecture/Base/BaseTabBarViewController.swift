//
//  BaseTabBarViewController.swift
//  XCToolkit
//
//  Created by wintop on 2026/3/31.
//

import UIKit
#if canImport(XCExtensions)
import XCExtensions
#endif


open class BaseTabBarViewController: UITabBarController {
    
    var navigationBarHidden: Bool {
        get {
            true
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithTransparentBackground()
            
            appearance.backgroundColor = UIColor(hex: "#ffff00")
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
        
//        self.tabBar.tintColor = UIColor(hex: "#D1FF00");
//        self.tabBar.unselectedItemTintColor = UIColor(hex: "#A8A8A8");
        self.tabBar.isTranslucent = false
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    open override var shouldAutorotate: Bool {
        return selectedViewController?.shouldAutorotate ?? false
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return selectedViewController?.supportedInterfaceOrientations ?? .portrait
    }
}

public extension UITabBar {
    /*
     图片设置 alwaysTemplate 的时候，会使用xc_setupColors设置的颜色
     图片设置 alwaysOriginal 的时候，会使用自己的颜色
     */
     
    func xc_setupColors(normal: UIColor, selected: UIColor) {
        if #available(iOS 13.0, *) {
            let appearance = UITabBarAppearance()
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normal]
            appearance.stackedLayoutAppearance.normal.iconColor = normal
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selected]
            appearance.stackedLayoutAppearance.selected.iconColor = selected
            
            self.standardAppearance = appearance
            if #available(iOS 15.0, *) {
                self.scrollEdgeAppearance = appearance
            }
        } else {
            self.tintColor = selected
            self.unselectedItemTintColor = normal
        }
    }
}
