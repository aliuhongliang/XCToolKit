//
//  HLCropViewController.swift
//  XCToolkit
//
//  自定义裁剪页面
//  - 方形：可拖动四角调整裁剪框大小，图片可移动/缩放
//  - 圆形：固定圆形遮罩，只能移动/缩放图片

import UIKit

public final class HLCropViewController: UIViewController {

    // MARK: - Public

    public var onCrop: ((UIImage) -> Void)?
    public var onCancel: (() -> Void)?

    // MARK: - Private

    private let image: UIImage
    private let shape: HLImagePickerCropShape

    private let minCropSize: CGFloat = 80
    private let handleSize: CGFloat = 24

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        sv.bouncesZoom = true
        sv.clipsToBounds = false
        return sv
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.isUserInteractionEnabled = true
        return iv
    }()

    private let overlayView = HLCropOverlayView()

    private lazy var cancelButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("取消", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16)
        b.setTitleColor(.white, for: .normal)
        b.addTarget(self, action: #selector(onCancelTapped), for: .touchUpInside)
        return b
    }()

    private lazy var confirmButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("使用", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.addTarget(self, action: #selector(onConfirmTapped), for: .touchUpInside)
        return b
    }()

    // 裁剪框（方形用）
    private var cropRect: CGRect = .zero
    private var activeHandle: HLCropHandle = .none

    // MARK: - Init

    public init(image: UIImage, shape: HLImagePickerCropShape) {
        self.image = image
        self.shape = shape
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupInitialLayout()
    }

    public override var prefersStatusBarHidden: Bool { true }

    // MARK: - Setup

    private func setupUI() {
        // ScrollView
        view.addSubview(scrollView)
        scrollView.delegate = self
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        imageView.image = image
        scrollView.addSubview(imageView)

        // Overlay
        overlayView.shape = shape
        overlayView.isUserInteractionEnabled = false
        view.addSubview(overlayView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // 方形：添加拖动手势
        if case .square = shape {
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCropPan(_:)))
            view.addGestureRecognizer(panGesture)
        }

        // 底部按钮
        view.addSubview(cancelButton)
        view.addSubview(confirmButton)

        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    private var didSetupLayout = false

    private func setupInitialLayout() {
        guard !didSetupLayout else { return }
        didSetupLayout = true

        let viewSize = view.bounds.size
        let cropSize = min(viewSize.width, viewSize.height) * 0.8

        // 初始裁剪框居中
        cropRect = CGRect(
            x: (viewSize.width - cropSize) / 2,
            y: (viewSize.height - cropSize) / 2,
            width: cropSize,
            height: cropSize
        )

        overlayView.cropRect = cropRect
        overlayView.setNeedsDisplay()

        // 设置 scrollView 内容
        let imgSize = image.size
        let scale = max(cropSize / imgSize.width, cropSize / imgSize.height)
        let scaledSize = CGSize(width: imgSize.width * scale, height: imgSize.height * scale)

        imageView.frame = CGRect(origin: .zero, size: scaledSize)
        scrollView.contentSize = scaledSize

        let minScale = cropSize / min(imgSize.width, imgSize.height)
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = minScale * 5
        scrollView.zoomScale = 1

        // 图片居中
        let offsetX = (scaledSize.width - viewSize.width) / 2
        let offsetY = (scaledSize.height - viewSize.height) / 2
        scrollView.contentOffset = CGPoint(x: max(0, offsetX), y: max(0, offsetY))
    }

    // MARK: - Crop Handle（方形拖动）

    private enum HLCropHandle {
        case none
        case topLeft, topRight, bottomLeft, bottomRight
    }

    @objc private func handleCropPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: view)

        if gesture.state == .began {
            activeHandle = detectHandle(at: location)
        }

        guard activeHandle != .none else { return }

        let translation = gesture.translation(in: view)
        gesture.setTranslation(.zero, in: view)

        var newRect = cropRect

        switch activeHandle {
        case .topLeft:
            newRect.origin.x += translation.x
            newRect.origin.y += translation.y
            newRect.size.width -= translation.x
            newRect.size.height -= translation.y
        case .topRight:
            newRect.origin.y += translation.y
            newRect.size.width += translation.x
            newRect.size.height -= translation.y
        case .bottomLeft:
            newRect.origin.x += translation.x
            newRect.size.width -= translation.x
            newRect.size.height += translation.y
        case .bottomRight:
            newRect.size.width += translation.x
            newRect.size.height += translation.y
        case .none:
            break
        }

        // 限制最小尺寸
        guard newRect.width >= minCropSize, newRect.height >= minCropSize else { return }
        // 限制在屏幕内
        guard newRect.minX >= 0, newRect.minY >= 0,
              newRect.maxX <= view.bounds.width,
              newRect.maxY <= view.bounds.height else { return }

        cropRect = newRect
        overlayView.cropRect = cropRect
        overlayView.setNeedsDisplay()
    }

    private func detectHandle(at point: CGPoint) -> HLCropHandle {
        let hitArea = handleSize * 2
        let corners: [(CGPoint, HLCropHandle)] = [
            (CGPoint(x: cropRect.minX, y: cropRect.minY), .topLeft),
            (CGPoint(x: cropRect.maxX, y: cropRect.minY), .topRight),
            (CGPoint(x: cropRect.minX, y: cropRect.maxY), .bottomLeft),
            (CGPoint(x: cropRect.maxX, y: cropRect.maxY), .bottomRight),
        ]
        for (corner, handle) in corners {
            let area = CGRect(x: corner.x - hitArea / 2, y: corner.y - hitArea / 2,
                              width: hitArea, height: hitArea)
            if area.contains(point) { return handle }
        }
        return .none
    }

    // MARK: - Actions

    @objc private func onCancelTapped() {
        onCancel?()
        dismiss(animated: true)
    }

    @objc private func onConfirmTapped() {
        let cropped = cropImage()
        onCrop?(cropped)
        dismiss(animated: true)
    }

    // MARK: - Crop

    private func cropImage() -> UIImage {
        // 将裁剪框转换到图片坐标系
        let scrollOffset = scrollView.contentOffset
        let zoomScale = scrollView.zoomScale
        let imageSize = imageView.frame.size

        // 裁剪框在 scrollView 内容坐标系中的位置
        let cropInContent = CGRect(
            x: (cropRect.origin.x + scrollOffset.x) / zoomScale,
            y: (cropRect.origin.y + scrollOffset.y) / zoomScale,
            width: cropRect.width / zoomScale,
            height: cropRect.height / zoomScale
        )

        // 转换到图片像素坐标系
        let scaleX = image.size.width / imageSize.width * zoomScale
        let scaleY = image.size.height / imageSize.height * zoomScale

        let pixelRect = CGRect(
            x: cropInContent.origin.x * scaleX,
            y: cropInContent.origin.y * scaleY,
            width: cropRect.width / zoomScale * scaleX,
            height: cropRect.height / zoomScale * scaleY
        ).intersection(CGRect(origin: .zero, size: image.size))

        guard let cgImage = image.cgImage?.cropping(to: pixelRect) else { return image }
        let cropped = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)

        // 圆形：裁剪后生成圆形图片
        if case .circle = shape {
            return makeCircleImage(cropped)
        }
        return cropped
    }

    private func makeCircleImage(_ source: UIImage) -> UIImage {
        let size = min(source.size.width, source.size.height)
        let rect = CGRect(origin: .zero, size: CGSize(width: size, height: size))
        UIGraphicsBeginImageContextWithOptions(rect.size, false, source.scale)
        defer { UIGraphicsEndImageContext() }
        UIBezierPath(ovalIn: rect).addClip()
        source.draw(in: rect)
        return UIGraphicsGetImageFromCurrentImageContext() ?? source
    }
}

// MARK: - UIScrollViewDelegate

extension HLCropViewController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
}

// MARK: - HLCropOverlayView

private final class HLCropOverlayView: UIView {

    var shape: HLImagePickerCropShape = .square
    var cropRect: CGRect = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        // 暗色遮罩
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.55).cgColor)
        ctx.fill(rect)

        // 镂空裁剪区域
        ctx.setBlendMode(.clear)
        switch shape {
        case .square:
            ctx.fill(cropRect)
        case .circle:
            ctx.fillEllipse(in: cropRect)
        }
        ctx.setBlendMode(.normal)

        // 边框
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineWidth(1.5)
        switch shape {
        case .square:
            ctx.stroke(cropRect)
            drawGrid(ctx: ctx)
            drawHandles(ctx: ctx)
        case .circle:
            ctx.strokeEllipse(in: cropRect)
        }
    }

    private func drawGrid(ctx: CGContext) {
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.4).cgColor)
        ctx.setLineWidth(0.5)

        // 三等分线
        let thirdW = cropRect.width / 3
        let thirdH = cropRect.height / 3

        for i in 1...2 {
            let x = cropRect.minX + thirdW * CGFloat(i)
            ctx.move(to: CGPoint(x: x, y: cropRect.minY))
            ctx.addLine(to: CGPoint(x: x, y: cropRect.maxY))

            let y = cropRect.minY + thirdH * CGFloat(i)
            ctx.move(to: CGPoint(x: cropRect.minX, y: y))
            ctx.addLine(to: CGPoint(x: cropRect.maxX, y: y))
        }
        ctx.strokePath()
    }

    private func drawHandles(ctx: CGContext) {
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineWidth(3)
        let len: CGFloat = 20

        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            // topLeft
            (CGPoint(x: cropRect.minX, y: cropRect.minY + len),
             CGPoint(x: cropRect.minX, y: cropRect.minY),
             CGPoint(x: cropRect.minX + len, y: cropRect.minY)),
            // topRight
            (CGPoint(x: cropRect.maxX - len, y: cropRect.minY),
             CGPoint(x: cropRect.maxX, y: cropRect.minY),
             CGPoint(x: cropRect.maxX, y: cropRect.minY + len)),
            // bottomLeft
            (CGPoint(x: cropRect.minX, y: cropRect.maxY - len),
             CGPoint(x: cropRect.minX, y: cropRect.maxY),
             CGPoint(x: cropRect.minX + len, y: cropRect.maxY)),
            // bottomRight
            (CGPoint(x: cropRect.maxX - len, y: cropRect.maxY),
             CGPoint(x: cropRect.maxX, y: cropRect.maxY),
             CGPoint(x: cropRect.maxX, y: cropRect.maxY - len)),
        ]

        for (start, corner, end) in corners {
            ctx.move(to: start)
            ctx.addLine(to: corner)
            ctx.addLine(to: end)
        }
        ctx.strokePath()
    }
}
