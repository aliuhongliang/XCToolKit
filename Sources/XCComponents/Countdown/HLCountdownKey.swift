//
//  HLCountdownKey.swift
//  XCToolkit
//
//  Created by wintop on 2026/4/14.
//

// 框架内只定义类型别名
public typealias HLCountdownKey = String

// 调用方在自己项目里扩展
extension HLCountdownKey {
    static let register = "register"
    static let forget   = "forget"
}
