//
//  HLImagePicker.swift
//  XCToolkit
//
//  ImagePicker 统一入口
//
//  使用示例：
//  // 单选图片 + 方形裁剪
//  let config = HLImagePickerConfig()
//  config.sourceType = .album
//  config.mediaType = .image
//  config.selectionMode = .single
//  config.cropEnabled = true
//  config.cropShape = .square
//  HLImagePicker.present(from: self, config: config) { results in
//      print(results.first?.image)
//  }
//
//  // 多选图片（最多9张）
//  let config = HLImagePickerConfig()
//  config.selectionMode = .multiple(max: 9)
//  HLImagePicker.present(from: self, config: config) { results in
//      print(results.count)
//  }
//
//  注意：使用前需在 Info.plist 添加：
//  NSPhotoLibraryUsageDescription
//  NSCameraUsageDescription（使用相机时）
//  NSMicrophoneUsageDescription（录视频时）

import UIKit
import Photos

public final class HLImagePicker: NSObject {

    private override init() {}

    // MARK: - Public

    /// 弹出 ImagePicker
    public static func present(
        from viewController: UIViewController,
        config: HLImagePickerConfig = HLImagePickerConfig(),
        completion: @escaping ([HLImagePickerResult]) -> Void
    ) {
        switch config.sourceType {
        case .camera:
            presentCamera(from: viewController, config: config, completion: completion)
        case .album, .both:
            checkPhotoPermission {
                presentAlbum(from: viewController, config: config, completion: completion)
            } denied: {
                // 权限被拒，业务层通过 HLPermission 自行处理
            }
        }
    }

    // MARK: - Private: Album

    private static func presentAlbum(
        from viewController: UIViewController,
        config: HLImagePickerConfig,
        completion: @escaping ([HLImagePickerResult]) -> Void
    ) {
        let albumVC = HLAlbumViewController()
        albumVC.config = config

        albumVC.onComplete = completion

        albumVC.onCamera = {
            albumVC.dismiss(animated: true) {
                presentCamera(from: viewController, config: config, isSingleFromAlbum: true, completion: completion)
            }
        }

        let nav = UINavigationController(rootViewController: albumVC)
        nav.modalPresentationStyle = .fullScreen
        viewController.present(nav, animated: true)
    }

    // MARK: - Private: Camera

    private static func presentCamera(
        from viewController: UIViewController,
        config: HLImagePickerConfig,
        isSingleFromAlbum: Bool = false,
        completion: @escaping ([HLImagePickerResult]) -> Void
    ) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }

        checkCameraPermission {
            let picker = UIImagePickerController()
            picker.sourceType = .camera

            switch config.mediaType {
            case .image:
                picker.mediaTypes = ["public.image"]
            case .video:
                picker.mediaTypes = ["public.movie"]
            case .all:
                picker.mediaTypes = ["public.image", "public.movie"]
            }

            let delegate = HLCameraDelegate(config: config, completion: completion)
            picker.delegate = delegate

            // 持有 delegate 防止释放
            objc_setAssociatedObject(picker, &AssociatedKeys.cameraDelegate, delegate, .OBJC_ASSOCIATION_RETAIN)

            viewController.present(picker, animated: true)
        } denied: {
            // 权限被拒，业务层自行处理
        }
    }

    // MARK: - Permission

    private static func checkPhotoPermission(granted: @escaping () -> Void, denied: @escaping () -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            DispatchQueue.main.async { granted() }
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if #available(iOS 14, *) {
                        if newStatus == .authorized || newStatus == .limited {
                            granted()
                        } else {
                            denied()
                        }
                    } else {
                        if newStatus == .authorized {
                            granted()
                        } else {
                            denied()
                        }
                    }
                }
            }
        default:
            denied()
        }
    }

    private static func checkCameraPermission(granted: @escaping () -> Void, denied: @escaping () -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            DispatchQueue.main.async { granted() }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { result in
                DispatchQueue.main.async { result ? granted() : denied() }
            }
        default:
            denied()
        }
    }
}

// MARK: - Associated Keys

private enum AssociatedKeys {
    static var cameraDelegate = "cameraDelegate"
}

// MARK: - HLCameraDelegate

private final class HLCameraDelegate: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    let config: HLImagePickerConfig
    let completion: ([HLImagePickerResult]) -> Void

    init(config: HLImagePickerConfig, completion: @escaping ([HLImagePickerResult]) -> Void) {
        self.config = config
        self.completion = completion
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        if let image = info[.originalImage] as? UIImage {
            // 单选 + 裁剪开启 → 进裁剪页
            if config.shouldCrop {
                let cropVC = HLCropViewController(image: image, shape: config.cropShape)
                cropVC.onCrop = { [weak self] cropped in
                    guard let self = self else { return }
                    picker.dismiss(animated: true) {
                        self.completion([HLImagePickerResult(image: cropped)])
                    }
                }
                cropVC.onCancel = {
                    picker.dismiss(animated: true)
                }
                picker.present(cropVC, animated: true)
            } else {
                picker.dismiss(animated: true) {
                    self.completion([HLImagePickerResult(image: image)])
                }
            }
        } else if let videoURL = info[.mediaURL] as? URL {
            picker.dismiss(animated: true) {
                self.completion([HLImagePickerResult(videoURL: videoURL, filePath: videoURL.path)])
            }
        } else {
            picker.dismiss(animated: true)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// AVFoundation import
import AVFoundation
