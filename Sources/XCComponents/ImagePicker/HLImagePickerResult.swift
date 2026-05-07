//
//  HLImagePickerResult.swift
//  XCToolkit
//
//  ImagePicker 返回结果模型

import UIKit
import Photos

public struct HLImagePickerResult {

    /// 图片（单选裁剪后为裁剪结果，多选为原图）
    public let image: UIImage?

    /// 视频本地 URL
    public let videoURL: URL?

    /// 原始 PHAsset
    public let asset: PHAsset?

    /// 本地文件路径（视频为临时路径，图片为 nil）
    public let filePath: String?

    /// 是否是视频
    public var isVideo: Bool { videoURL != nil }

    /// 是否是图片
    public var isImage: Bool { image != nil }

    public init(image: UIImage? = nil,
                videoURL: URL? = nil,
                asset: PHAsset? = nil,
                filePath: String? = nil) {
        self.image = image
        self.videoURL = videoURL
        self.asset = asset
        self.filePath = filePath
    }
}
