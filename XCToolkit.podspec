Pod::Spec.new do |s|
  s.name             = 'XCToolkit'
  s.version          = '0.1.1'
  s.summary          = 'A lightweight Swift toolkit for iOS development'
  s.description      = <<-DESC
XCToolkit is a modular, lightweight Swift toolkit designed to simplify iOS development.
Includes foundation extensions, logging, and storage utilities.
                       DESC

  s.homepage         = 'https://github.com/aliuhongliang/XCToolkit'  # 改成真实仓库
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'XiChuan' => '617745514@qq.com' }

  s.platform         = :ios, '13.0'
  s.swift_version    = '5.9'

  s.source           = { :git => 'https://github.com/aliuhongliang/XCToolkit.git', :tag => s.version }

  # MARK: - Subspecs

  s.subspec 'XCFoundation' do |ss|
    ss.source_files = 'Sources/XCFoundation/**/*.{swift,h,m}'
  end

  s.subspec 'XCLogger' do |ss|
    ss.dependency 'XCToolkit/XCFoundation'
    ss.source_files = 'Sources/XCLogger/**/*.{swift,h,m}'
  end

  s.subspec 'XCStorage' do |ss|
    ss.dependency 'XCToolkit/XCFoundation'
    ss.source_files = 'Sources/XCStorage/**/*.{swift,h,m}'
  end
end