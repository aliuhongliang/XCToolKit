Pod::Spec.new do |s|
  s.name             = 'XCToolkit'
  s.version          = '0.1.0'
  s.summary          = 'A lightweight Swift toolkit for iOS development'
  s.description      = <<-DESC
XCToolkit is a modular, lightweight Swift toolkit designed to simplify iOS development.
Includes foundation extensions, logging, and storage utilities.
                       DESC

  s.homepage         = 'https://github.com/yourname/MyToolkit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'XiChuan' => '617745514@qq.com' }

  s.platform         = :ios, '13.0'
  s.swift_version    = '5.9'

  s.source           = { :git => 'https://github.com/yourname/XCToolkit.git', :tag => s.version }

  # MARK: - Subspecs

  s.subspec 'Foundation' do |ss|
    ss.source_files = 'Sources/XCFoundation/**/*'
  end

  s.subspec 'Logger' do |ss|
    ss.dependency 'XCToolkit/Foundation'
    ss.source_files = 'Sources/XCLogger/**/*'
  end

  s.subspec 'Storage' do |ss|
    ss.dependency 'XCToolkit/Foundation'
    ss.source_files = 'Sources/XCStorage/**/*'
  end

end