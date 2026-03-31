// ScreenAdapter.swift
// 屏幕适配工具
//
// 模块：
//   1. DeviceScreen   — 屏幕尺寸 / SafeArea / 状态栏 / 导航栏 / TabBar 常量
//   2. rpx            — 基于 375pt 设计稿的比例缩放，支持 Int / Double / Float / CGFloat

import UIKit

// MARK: - 1. DeviceScreen

public enum DeviceScreen {
    
    // MARK: 屏幕
    
    /// 物理短边（竖屏时的宽，横屏时的高）
    public static let shortSide: CGFloat = min(
        UIScreen.main.bounds.width,
        UIScreen.main.bounds.height
    )
    
    /// 物理长边（竖屏时的高，横屏时的宽）
    public static let longSide: CGFloat = max(
        UIScreen.main.bounds.width,
        UIScreen.main.bounds.height
    )
    
    /// 当前屏幕宽度（随旋转变化）
    public static var width: CGFloat {
        UIScreen.main.bounds.width
    }
    
    /// 当前屏幕高度（随旋转变化）
    public static var height: CGFloat {
        UIScreen.main.bounds.height
    }
    
    /// 屏幕 scale（@2x / @3x）
    public static let scale: CGFloat = UIScreen.main.scale
    
    
    // MARK: 方向
    
    /// 当前是否横屏
    public static var isLandscape: Bool {
        if #available(iOS 16.0, *) {
            return keyWindow?.windowScene?.interfaceOrientation.isLandscape ?? false
        } else {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
    }
    
    /// 当前是否竖屏
    public static var isPortrait: Bool { !isLandscape }
    
    
    
    // MARK: SafeArea
    
    /// SafeArea 顶部（含状态栏，刘海屏 = 44/47/59，普通屏 = 20）
    public static var safeAreaTop: CGFloat {
        keyWindow?.safeAreaInsets.top ?? 0
    }
    
    /// SafeArea 底部（Home Indicator 高度，有实体 Home 键 = 0）
    public static var safeAreaBottom: CGFloat {
        keyWindow?.safeAreaInsets.bottom ?? 0
    }
    
    /// SafeArea 左侧（横屏 iPhone 有值，竖屏通常为 0）
    public static var safeAreaLeft: CGFloat {
        keyWindow?.safeAreaInsets.left ?? 0
    }
    
    /// SafeArea 右侧
    public static var safeAreaRight: CGFloat {
        keyWindow?.safeAreaInsets.right ?? 0
    }
    
    // MARK: 状态栏
    
    /// 状态栏高度（刘海屏 = 44/47/59，普通屏 = 20）
    public static var statusBarHeight: CGFloat {
        if #available(iOS 13.0, *) {
            return keyWindow?.windowScene?.statusBarManager?.statusBarFrame.height ?? 20
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
    }
    
    // MARK: 导航栏
    
    /// 导航栏内容区高度（固定 44pt）
    public static let navigationBarContentHeight: CGFloat = 44
    
    /// 导航栏总高度 = 状态栏 + 44（适合计算顶部布局偏移）
    public static var navigationBarHeight: CGFloat {
        statusBarHeight + navigationBarContentHeight
    }
    
    // MARK: TabBar
    
    /// TabBar 内容区高度（固定 49pt）
    public static let tabBarContentHeight: CGFloat = 49
    
    /// TabBar 总高度 = 49 + SafeArea 底部（有 Home Indicator 时更高）
    public static var tabBarHeight: CGFloat {
        tabBarContentHeight + safeAreaBottom
    }
    
    // MARK: 常用布局区域
    
    /// 可用内容区高度 = 屏幕高度 - 导航栏 - TabBar
    public static var contentHeight: CGFloat {
        height - navigationBarHeight - tabBarHeight
    }
    
    /// 横屏时的可用内容宽度（去掉左右 SafeArea，直播间布局常用）
    public static var landscapeContentWidth: CGFloat {
        width - safeAreaLeft - safeAreaRight
    }
    
    /// 是否是刘海屏（有 Home Indicator）
    public static var isNotchedScreen: Bool {
        safeAreaBottom > 0
    }
    
    // MARK: 私有
    
    private static var keyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}

// MARK: - 2. rpx 适配比例

/// 设计稿基准宽度（375pt，对应 iPhone 6/7/8/SE2/SE3）
/// 修改此值即可切换全局基准
private let kDesignWidth: CGFloat = 375.0

/// 实际缩放比 = 当前屏幕宽 / 设计稿宽
private let kRpxRatio: CGFloat = DeviceScreen.width / kDesignWidth

// MARK: Int

extension Int {
    
    /// 按设计稿比例换算为当前屏幕的 CGFloat（pt）
    /// 用法：16.rpx
    var rpx: CGFloat {
        CGFloat(self) * kRpxRatio
    }
    
    /// rpx 取整（需要整像素对齐时使用）
    var rpxFloor: CGFloat {
        floor(CGFloat(self) * kRpxRatio)
    }
    
    var rpxCeil: CGFloat {
        ceil(CGFloat(self) * kRpxRatio)
    }
}

// MARK: Double

extension Double {
    
    var rpx: CGFloat {
        CGFloat(self) * kRpxRatio
    }
    
    var rpxFloor: CGFloat {
        floor(CGFloat(self) * kRpxRatio)
    }
    
    var rpxCeil: CGFloat {
        ceil(CGFloat(self) * kRpxRatio)
    }
}

// MARK: Float

extension Float {
    
    var rpx: CGFloat {
        CGFloat(self) * kRpxRatio
    }
    
    var rpxFloor: CGFloat {
        floor(CGFloat(self) * kRpxRatio)
    }
    
    var rpxCeil: CGFloat {
        ceil(CGFloat(self) * kRpxRatio)
    }
}

// MARK: CGFloat

extension CGFloat {
    
    var rpx: CGFloat {
        self * kRpxRatio
    }
    
    var rpxFloor: CGFloat {
        floor(self * kRpxRatio)
    }
    
    var rpxCeil: CGFloat {
        ceil(self * kRpxRatio)
    }
}
