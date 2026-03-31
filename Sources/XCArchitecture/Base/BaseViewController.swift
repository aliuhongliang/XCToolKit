//
//  BaseViewController.swift
//  XCToolkit
//
//  Created by wintop on 2026/3/31.
//

import UIKit
#if canImport(XCExtensions)
import XCExtensions
#endif

open class BaseViewController: UIViewController {
    
    var firstLoad: Bool = true
    
    var popGestureEnable: Bool {
        false
    }
    
    var navigationBarHidden: Bool {
        get { true }
    }
    
    var navigationBarColor: UIColor {
        get { UIColor.clear }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        if #available(iOS 15.0, *) {
        } else {
            navigationController?.navigationBar.shadowImage = UIImage()
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(navigationBarHidden, animated: animated)
        if !navigationBarHidden {
            if #available(iOS 15.0, *) {
                let appBar = UINavigationBarAppearance()
                appBar.backgroundColor = navigationBarColor
                appBar.shadowColor = .clear
                appBar.backgroundEffect = nil;
                appBar.shadowColor = nil;
                navigationController?.navigationBar.standardAppearance = appBar
                navigationController?.navigationBar.scrollEdgeAppearance = appBar
            } else {
                let image = UIImage(color: navigationBarColor)
                navigationController?.navigationBar.setBackgroundImage(image, for: .default)
                navigationController?.navigationBar.shadowImage = image
            }
            
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if navigationController?.viewControllers.count == 1 {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        } else {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = self.popGestureEnable
        }
    
        if firstLoad {
            firstLoad = false
            viewDidAppearFirstLoad()
        }
    }
    
    func viewDidAppearFirstLoad() {
        
    }

    // MARK: 屏幕旋转
    open override var shouldAutorotate: Bool {
        return false
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
}
