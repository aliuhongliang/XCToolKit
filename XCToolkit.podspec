Pod::Spec.new do |s|
  s.name             = 'XCToolkit'
  s.version          = '1.0.0'
  s.summary          = 'iOS 开发综合工具库，包含扩展、UI组件、网络封装及底层工具。'
  s.description      = <<-DESC
                       XCToolkit 是一个功能全面的 iOS 库，涵盖了：
                       - 基础 Foundation/UIKit 扩展
                       - 进制转换、蓝牙数据处理工具
                       - 基于 Moya/MQTT/WebSocket 的网络封装
                       - 常用 UI 组件（弹窗、选择器、空页面等）
                       - 基础业务框架封装（BaseVC, Theme, Permission）
                       DESC

  s.homepage         = 'https://github.com/aliuhongliang/XCToolkit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'XiChuan' => '617745514@qq.com' }

  s.platform         = :ios, '13.0'
  s.swift_version    = '5.9'

  s.source           = { :git => 'https://github.com/aliuhongliang/XCToolkit.git', :tag => s.version }

  # 👇 👇 👇 【关键修复 1】必须加这个！解决模块找不到！
  s.user_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-Xfrontend -no-abi-long-term-stability-version-5-5' }
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  # MARK: - Subspecs
  # 1. Core
  s.subspec 'Core' do |ss|
    ss.source_files = 'Sources/XCCore/**/*.swift'
  end

  # 2. Extensions → 依赖 Core
  s.subspec 'Extensions' do |ss|
    ss.source_files = 'Sources/XCExtensions/**/*.swift'
    ss.dependency 'XCToolkit/Core'
  end

  # 3. Architecture → 依赖 Extensions（自动包含Core）
  s.subspec 'Architecture' do |ss|
    ss.source_files = 'Sources/XCArchitecture/**/*.swift'
    ss.dependency 'XCToolkit/Extensions'
  end

  # 4. Components → 依赖 Extensions
  s.subspec 'Components' do |ss|
    ss.source_files = 'Sources/XCComponents/**/*.swift'
    ss.dependency 'XCToolkit/Extensions'
  end

  # 5. Network
  s.subspec 'Network' do |ss|
    ss.source_files = 'Sources/XCNetwork/**/*.swift'
    ss.dependency 'XCToolkit/Core'
    ss.dependency 'Moya'
    ss.dependency 'Starscream'
    ss.dependency 'CocoaMQTT'
  end

  # 6. Crypto
  s.subspec 'Crypto' do |ss|
    ss.source_files = 'Sources/XCCrypto/**/*.swift'
    ss.dependency 'CryptoSwift'
  end

  s.default_subspecs = 'Core', 'Extensions', 'Architecture', 'Components'
end