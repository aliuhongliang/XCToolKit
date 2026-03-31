// UIImage+Extension.swift
// UIImage 工具扩展
//
// 模块：
//   1. 缩放 / 裁剪 / 圆角
//   2. 压缩（质量 / 目标字节数）
//   3. 颜色处理（染色 / 透明度）
//   4. 生成图片（纯色 / 渐变 / 视图截图）
//   5. Base64 / Data 互转
//   6. 方向修正（EXIF）
//   7. 拉伸保护（resizableImage）

import UIKit

// MARK: - 1. 缩放 / 裁剪 / 圆角

public extension UIImage {

    /// 缩放到指定尺寸（不保持比例）
    func scaled(to size: CGSize) -> UIImage {
        guard size.width > 0, size.height > 0 else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// 按宽等比缩放
    func scaled(toWidth width: CGFloat) -> UIImage {
        guard self.size.width > 0 else { return self }
        let ratio = width / self.size.width
        let height = self.size.height * ratio
        return scaled(to: CGSize(width: width, height: height))
    }

    /// 按高等比缩放
    func scaled(toHeight height: CGFloat) -> UIImage {
        guard self.size.height > 0 else { return self }
        let ratio = height / self.size.height
        let width = self.size.width * ratio
        return scaled(to: CGSize(width: width, height: height))
    }

    /// 限制最长边缩放（超出才缩，不放大）
    func scaled(toMaxSide maxSide: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxSide else { return self }
        return size.width >= size.height
            ? scaled(toWidth: maxSide)
            : scaled(toHeight: maxSide)
    }

    /// 裁剪到指定 CGRect（基于点坐标，自动适配 scale）
    func cropped(to rect: CGRect) -> UIImage {
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
        guard let cgImage = cgImage?.cropping(to: scaledRect) else { return self }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }

    /// 居中裁剪到目标尺寸（直播封面 / 缩略图常用）
    func centerCropped(to targetSize: CGSize) -> UIImage {
        let srcRatio  = size.width / size.height
        let dstRatio  = targetSize.width / targetSize.height
        var drawSize: CGSize
        if srcRatio > dstRatio {
            // 原图更宽 → 按高适配
            drawSize = CGSize(width: size.width * targetSize.height / size.height,
                              height: targetSize.height)
        } else {
            // 原图更高 → 按宽适配
            drawSize = CGSize(width: targetSize.width,
                              height: size.height * targetSize.width / size.width)
        }
        let origin = CGPoint(x: (targetSize.width  - drawSize.width)  / 2,
                             y: (targetSize.height - drawSize.height) / 2)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: origin, size: drawSize))
        }
    }

    /// 添加圆角
    func rounded(radius: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
            draw(in: rect)
        }
    }

    /// 裁剪为正圆（头像常用）
    func circled() -> UIImage {
        let side = min(size.width, size.height)
        let origin = CGPoint(x: (size.width - side) / 2,
                             y: (size.height - side) / 2)
        let square = centerCropped(to: CGSize(width: side, height: side))
        return square.rounded(radius: side / 2)
    }
}

// MARK: - 2. 压缩

public extension UIImage {

    /// 按 JPEG 质量压缩，quality: 0.0 ~ 1.0
    func jpegData(quality: CGFloat) -> Data? {
        jpegData(compressionQuality: quality.clamped(to: 0...1))
    }

    /// 二分法压缩到目标字节数以内，返回 Data
    /// - Parameters:
    ///   - maxBytes: 目标最大字节数，例如 200_000 = 200KB
    ///   - minimumQuality: 最低质量下限，默认 0.1（防止过度压缩）
    func compressed(toBytes maxBytes: Int,
                    minimumQuality: CGFloat = 0.1) -> Data? {
        // 先试最高质量
        guard var data = jpegData(compressionQuality: 1.0) else { return nil }
        guard data.count > maxBytes else { return data }

        var low: CGFloat  = minimumQuality
        var high: CGFloat = 1.0
        var best: Data    = data

        for _ in 0..<20 {           // 最多迭代 20 次，精度足够
            let mid = (low + high) / 2
            guard let candidate = jpegData(compressionQuality: mid) else { break }
            if candidate.count <= maxBytes {
                best = candidate
                low  = mid
            } else {
                high = mid
            }
            if high - low < 0.01 { break }
        }
        return best
    }

    /// 先缩放再压缩，同时限制尺寸和体积
    /// - Parameters:
    ///   - maxSide: 最长边限制（点）
    ///   - maxBytes: 目标最大字节数
    func compressed(toMaxSide maxSide: CGFloat,
                    maxBytes: Int) -> Data? {
        scaled(toMaxSide: maxSide).compressed(toBytes: maxBytes)
    }
}

// MARK: - 3. 颜色处理

public extension UIImage {

    /// 模板染色（适用于 .alwaysTemplate 渲染模式的图标，如礼物、箭头）
    func tinted(with color: UIColor) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            draw(at: .zero, blendMode: .destinationIn, alpha: 1)
        }
    }

    /// 调整整体透明度
    func withAlpha(_ alpha: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(at: .zero, blendMode: .normal, alpha: alpha.clamped(to: 0...1))
        }
    }

    /// 转为灰度图
    var grayscaled: UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            // 用 CIFilter 保证灰度效果准确
            guard let ciImage = CIImage(image: self),
                  let filter  = CIFilter(name: "CIPhotoEffectMono") else {
                draw(in: rect); return
            }
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            let context = CIContext()
            if let output = filter.outputImage,
               let cgImg  = context.createCGImage(output, from: output.extent) {
                UIImage(cgImage: cgImg, scale: scale, orientation: imageOrientation)
                    .draw(in: rect)
            } else {
                draw(in: rect)
            }
        }
    }
}

// MARK: - 4. 生成图片

public extension UIImage {

    /// 从纯色生成图片
    convenience init(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        guard let cgImage = image.cgImage else {
            self.init(); return
        }
        self.init(cgImage: cgImage)
    }

    /// 从线性渐变生成图片
    /// - Parameters:
    ///   - colors: 渐变颜色数组
    ///   - size: 图片尺寸
    ///   - startPoint: 起点（归一化，默认左 (0,0.5)）
    ///   - endPoint: 终点（归一化，默认右 (1,0.5)）
    convenience init(gradientColors colors: [UIColor],
                     size: CGSize,
                     startPoint: CGPoint = CGPoint(x: 0, y: 0.5),
                     endPoint:   CGPoint = CGPoint(x: 1, y: 0.5)) {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cgCtx   = ctx.cgContext
            let cgColors = colors.map(\.cgColor) as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: cgColors,
                                            locations: nil) else { return }
            let start = CGPoint(x: startPoint.x * size.width,  y: startPoint.y * size.height)
            let end   = CGPoint(x: endPoint.x   * size.width,  y: endPoint.y   * size.height)
            cgCtx.drawLinearGradient(gradient, start: start, end: end, options: [])
        }
        guard let cgImage = image.cgImage else {
            self.init(); return
        }
        self.init(cgImage: cgImage)
    }

    /// 对 UIView 截图（需在主线程调用）
    convenience init?(view: UIView) {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let image = UIGraphicsImageRenderer(size: view.bounds.size, format: format).image { _ in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        guard let cgImage = image.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

// MARK: - 5. Base64 / Data 互转

public extension UIImage {

    /// 转为 JPEG Base64 字符串
    func base64String(quality: CGFloat = 0.8) -> String? {
        jpegData(compressionQuality: quality.clamped(to: 0...1))?.base64EncodedString()
    }

    /// 从 Base64 字符串加载（支持带 Data URI 前缀，如 "data:image/jpeg;base64,..."）
    convenience init?(base64 string: String) {
        var raw = string
        // 去掉 Data URI 前缀
        if let range = raw.range(of: "base64,") {
            raw = String(raw[range.upperBound...])
        }
        guard let data = Data(base64Encoded: raw,
                              options: .ignoreUnknownCharacters) else { return nil }
        self.init(data: data)
    }
}

// MARK: - 6. 方向修正（EXIF）

public extension UIImage {

    /// 修正拍照方向为 .up（上传前必调）
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}

// MARK: - 7. 拉伸保护（九宫格）

public extension UIImage {

    /// 九宫格拉伸保护，capInsets 默认取图片中心 1pt
    /// - Parameter insets: 保护区域，nil 时自动取中心点
    func resizable(insets: UIEdgeInsets? = nil) -> UIImage {
        let i = insets ?? UIEdgeInsets(
            top:    (size.height / 2).rounded(.down),
            left:   (size.width  / 2).rounded(.down),
            bottom: (size.height / 2).rounded(.down),
            right:  (size.width  / 2).rounded(.down)
        )
        return resizableImage(withCapInsets: i, resizingMode: .stretch)
    }

    /// 水平拉伸保护（适用于气泡、按钮背景等横向拉伸场景）
    func resizableHorizontal() -> UIImage {
        let insets = UIEdgeInsets(
            top:    0,
            left:   (size.width / 2).rounded(.down),
            bottom: 0,
            right:  (size.width / 2).rounded(.down)
        )
        return resizableImage(withCapInsets: insets, resizingMode: .stretch)
    }
}

// MARK: - 私有辅助

private extension CGFloat {
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.max(range.lowerBound, Swift.min(self, range.upperBound))
    }
}
