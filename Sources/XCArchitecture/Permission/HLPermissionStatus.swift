//
//  HLPermissionStatus.swift
//  XCToolkit
//
//  权限状态枚举

import Foundation

/// 权限状态
public enum HLPermissionStatus {
    /// 已授权
    case authorized
    /// 已拒绝（用户手动拒绝）
    case denied
    /// 系统限制（家长控制等，用户无法更改）
    case restricted
    /// 尚未请求过
    case notDetermined
    /// 有限访问（相册 iOS 14+）
    case limited
}
