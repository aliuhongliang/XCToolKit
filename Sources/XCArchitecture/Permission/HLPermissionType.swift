//
//  HLPermissionType.swift
//  XCToolkit
//
//  权限类型枚举

import Foundation

/// 权限类型
public enum HLPermissionType {
    /// 相机
    case camera
    /// 麦克风
    case microphone
    /// 相册
    case photoLibrary
    /// 定位（使用期间）
    case locationWhenInUse
    /// 定位（始终）
    case locationAlways
    /// 推送通知
    case notification
    /// 联系人
    case contacts
    /// 日历
    case calendar
    /// 提醒事项
    case reminder
    /// 蓝牙
    case bluetooth
    /// 运动与健身
    case motion
    /// 面容 ID / 生物识别
    case faceID
    /// 语音识别
    case speechRecognition
    /// Siri
    case siri
    /// 媒体资料库（Apple Music）
    case mediaLibrary
    /// 广告追踪（IDFA，iOS 14+）
    case tracking
}
