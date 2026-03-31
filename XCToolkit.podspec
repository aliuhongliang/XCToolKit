Pod::Spec.new do |s|
  s.name             = 'XCToolkit'
  s.version          = '0.1.1'
  s.summary          = 'iOS 开发综合工具库，包含扩展、UI组件、网络封装及底层工具。'
  s.description      = <<-DESC
                       XCToolkit 是一个功能全面的 iOS 库，涵盖了：
                       - 基础 Foundation/UIKit 扩展
                       - 进制转换、蓝牙数据处理工具
                       - 基于 Moya/MQTT/WebSocket 的网络封装
                       - 常用 UI 组件（弹窗、选择器、空页面等）
                       - 基础业务框架封装（BaseVC, Theme, Permission）
                       DESC

  s.homepage         = 'https://github.com/aliuhongliang/XCToolkit'  # 改成真实仓库
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'XiChuan' => '617745514@qq.com' }

  s.platform         = :ios, '13.0'
  s.swift_version    = '5.9'

  s.source           = { :git => 'https://github.com/aliuhongliang/XCToolkit.git', :tag => s.version }

  # MARK: - Subspecs
  # 1. Core: 基础工具，不依赖任何库
  s.subspec 'Core' do |ss|
    ss.source_files = 'XCToolkit/XCCore/**/*'
  end

  # 2. Extensions: 系统类扩展，依赖 Core
  s.subspec 'Extensions' do |ss|
    ss.source_files = 'XCToolkit/XCExtensions/**/*'
    ss.dependency 'XCToolkit/Core'
  end

  # 3. Architecture: 业务基类、权限、主题
  s.subspec 'Architecture' do |ss|
    ss.source_files = 'XCToolkit/XCArchitecture/**/*'
    ss.dependency 'XCToolkit/Extensions'
  end

  # 4. Components: UI 组件
  s.subspec 'Components' do |ss|
    ss.source_files = 'XCToolkit/XCComponents/**/*'
    ss.dependency 'XCToolkit/Extensions'
    # 如果涉及到图片资源，记得添加 resource_bundles
    # ss.resource_bundles = { 'XCToolkit' => ['XCToolkit/Assets/*.xcassets'] }
  end

  # 5. Network: 网络二次封装 (按需引入三方依赖)
  s.subspec 'Network' do |ss|
    ss.source_files = 'XCToolkit/XCNetwork/**/*'
    ss.dependency 'XCToolkit/Core'
    ss.dependency 'Moya'
    ss.dependency 'Starscream'
    ss.dependency 'CocoaMQTT'
  end

  # 6. Crypto: 加密模块
  s.subspec 'Crypto' do |ss|
    ss.source_files = 'XCToolkit/XCCrypto/**/*'
    ss.dependency 'CryptoSwift'
  end

  # 默认集成
  s.default_subspecs = 'Core', 'Extensions', 'Architecture', 'Components'
end