//
//  HLImagePickerConfig.swift
//  XCToolkit
//
//  ImagePicker 配置项

import UIKit

// MARK: - Source Type

public enum HLImagePickerSourceType {
    /// 仅相册
    case album
    /// 仅相机
    case camera
    /// 相册 + 顶部拍照入口
    case both
}

// MARK: - Media Type

public enum HLImagePickerMediaType {
    /// 仅图片
    case image
    /// 仅视频
    case video
    /// 图片和视频
    case all
}

// MARK: - Selection Mode

public enum HLImagePickerSelectionMode {
    /// 单选
    case single
    /// 多选，max 为最大选择数量
    case multiple(max: Int)
}

// MARK: - Crop Shape

public enum HLImagePickerCropShape {
    /// 方形（可调整大小）
    case square
    /// 圆形（固定大小）
    case circle
}

// MARK: - HLImagePickerConfig

public final class HLImagePickerConfig {

    public init() {}

    /// 来源类型，默认相册
    public var sourceType: HLImagePickerSourceType = .album

    /// 媒体类型，默认图片
    public var mediaType: HLImagePickerMediaType = .image

    /// 选择模式，默认单选
    public var selectionMode: HLImagePickerSelectionMode = .single

    /// 是否开启裁剪（仅单选图片时生效），默认 false
    public var cropEnabled: Bool = false

    /// 裁剪形状，默认方形
    public var cropShape: HLImagePickerCropShape = .square

    /// 多选时是否允许图片和视频混选，默认 false
    public var allowMixedMedia: Bool = false

    /// 相册列数，默认 3
    public var columnCount: Int = 3

    /// 网格间距，默认 2
    public var gridSpacing: CGFloat = 2

    // MARK: - Computed

    var isMultiple: Bool {
        if case .multiple = selectionMode { return true }
        return false
    }

    var maxCount: Int {
        if case .multiple(let max) = selectionMode { return max }
        return 1
    }

    var shouldCrop: Bool {
        guard cropEnabled, !isMultiple else { return false }
        guard case .image = mediaType else { return false }
        return true
    }
}
