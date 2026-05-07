//
//  HLAlbumViewController.swift
//  XCToolkit
//
//  自定义相册网格选择页面

import UIKit
import Photos

final class HLAlbumViewController: UIViewController {

    // MARK: - Config

    var config: HLImagePickerConfig = HLImagePickerConfig()
    var onComplete: (([HLImagePickerResult]) -> Void)?
    var onCamera: (() -> Void)?

    // MARK: - Private

    private var assets: [PHAsset] = []
    private var selectedAssets: [PHAsset] = []  // 按选择顺序排列
    private var firstSelectedMediaType: HLImagePickerMediaType?

    // MARK: - UI

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = config.gridSpacing
        layout.minimumInteritemSpacing = config.gridSpacing
        let totalSpacing = config.gridSpacing * CGFloat(config.columnCount - 1)
        let itemWidth = (UIScreen.main.bounds.width - totalSpacing) / CGFloat(config.columnCount)
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.delegate = self
        cv.dataSource = self
        cv.register(HLAlbumCell.self, forCellWithReuseIdentifier: HLAlbumCell.reuseID)
        return cv
    }()

    private lazy var cameraBar: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.97, alpha: 1)
        v.isHidden = config.sourceType != .both
        return v
    }()

    private lazy var cameraButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "camera.fill"), for: .normal)
        b.setTitle("  拍摄", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15)
        b.tintColor = .black
        b.setTitleColor(.black, for: .normal)
        b.addTarget(self, action: #selector(onCameraTapped), for: .touchUpInside)
        return b
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupNav()
        setupUI()
        loadAssets()
    }

    // MARK: - Setup

    private func setupNav() {
        navigationItem.title = "照片"

        let cancelBtn = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(onCancelTapped))
        cancelBtn.tintColor = UIColor(white: 0.4, alpha: 1)
        navigationItem.leftBarButtonItem = cancelBtn

        let confirmBtn = UIBarButtonItem(title: "确认", style: .done, target: self, action: #selector(onConfirmTapped))
        confirmBtn.tintColor = .systemBlue
        navigationItem.rightBarButtonItem = confirmBtn
        updateConfirmButton()
    }

    private func setupUI() {
        // 拍照入口
        if config.sourceType == .both {
            view.addSubview(cameraBar)
            cameraBar.addSubview(cameraButton)
            cameraBar.translatesAutoresizingMaskIntoConstraints = false
            cameraButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                cameraBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                cameraBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                cameraBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                cameraBar.heightAnchor.constraint(equalToConstant: 48),

                cameraButton.centerXAnchor.constraint(equalTo: cameraBar.centerXAnchor),
                cameraButton.centerYAnchor.constraint(equalTo: cameraBar.centerYAnchor),
            ])
        }

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        let topAnchor = config.sourceType == .both ?
            cameraBar.bottomAnchor : view.safeAreaLayoutGuide.topAnchor

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Load Assets

    private func loadAssets() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        switch config.mediaType {
        case .image:
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        case .video:
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
        case .all:
            break
        }

        let result = PHAsset.fetchAssets(with: options)
        assets = (0..<result.count).map { result.object(at: $0) }
        collectionView.reloadData()
    }

    // MARK: - Helpers

    private func updateConfirmButton() {
        let count = selectedAssets.count
        let title = count > 0 ? "确认(\(count))" : "确认"
        navigationItem.rightBarButtonItem?.title = title
        navigationItem.rightBarButtonItem?.isEnabled = count > 0
        navigationItem.title = count > 0 ? "已选 \(count)/\(config.maxCount)" : "照片"
    }

    private func isAssetEnabled(_ asset: PHAsset) -> Bool {
        guard config.isMultiple else { return true }
        guard !config.allowMixedMedia, let firstType = firstSelectedMediaType else { return true }
        let assetType: HLImagePickerMediaType = asset.mediaType == .video ? .video : .image
        return assetType == firstType
    }

    private func fetchResults(for assets: [PHAsset], completion: @escaping ([HLImagePickerResult]) -> Void) {
        var results: [HLImagePickerResult] = []
        let group = DispatchGroup()

        for asset in assets {
            group.enter()
            if asset.mediaType == .video {
                let options = PHVideoRequestOptions()
                options.version = .original
                PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                    if let urlAsset = avAsset as? AVURLAsset {
                        let result = HLImagePickerResult(
                            videoURL: urlAsset.url,
                            asset: asset,
                            filePath: urlAsset.url.path
                        )
                        results.append(result)
                    }
                    group.leave()
                }
            } else {
                let options = PHImageRequestOptions()
                options.version = .original
                options.deliveryMode = .highQualityFormat
                options.isSynchronous = false
                PHImageManager.default().requestImage(
                    for: asset,
                    targetSize: PHImageManagerMaximumSize,
                    contentMode: .aspectFit,
                    options: options
                ) { image, _ in
                    if let image = image {
                        let result = HLImagePickerResult(image: image, asset: asset)
                        results.append(result)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(results)
        }
    }

    // MARK: - Actions

    @objc private func onCancelTapped() {
        dismiss(animated: true)
    }

    @objc private func onConfirmTapped() {
        fetchResults(for: selectedAssets) { [weak self] results in
            self?.dismiss(animated: true) {
                self?.onComplete?(results)
            }
        }
    }

    @objc private func onCameraTapped() {
        onCamera?()
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension HLAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HLAlbumCell.reuseID, for: indexPath) as! HLAlbumCell
        let asset = assets[indexPath.item]
        let selectedIndex = selectedAssets.firstIndex(of: asset).map { $0 + 1 }
        let isEnabled = isAssetEnabled(asset)
        cell.configure(asset: asset, selectedIndex: selectedIndex, isEnabled: isEnabled)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = assets[indexPath.item]

        if config.isMultiple {
            // 多选逻辑
            if let idx = selectedAssets.firstIndex(of: asset) {
                selectedAssets.remove(at: idx)
                if selectedAssets.isEmpty { firstSelectedMediaType = nil }
            } else {
                guard selectedAssets.count < config.maxCount else { return }
                guard isAssetEnabled(asset) else { return }

                if firstSelectedMediaType == nil && !config.allowMixedMedia {
                    firstSelectedMediaType = asset.mediaType == .video ? .video : .image
                }
                selectedAssets.append(asset)
            }
            updateConfirmButton()
            collectionView.reloadData()
        } else {
            // 单选：直接返回
            fetchResults(for: [asset]) { [weak self] results in
                guard let self = self, let result = results.first else { return }
                if self.config.shouldCrop, let image = result.image {
                    let cropVC = HLCropViewController(image: image, shape: self.config.cropShape)
                    cropVC.onCrop = { cropped in
                        let cropResult = HLImagePickerResult(image: cropped, asset: asset)
                        self.dismiss(animated: true) {
                            self.onComplete?([cropResult])
                        }
                    }
                    cropVC.onCancel = {}
                    self.present(cropVC, animated: true)
                } else {
                    self.dismiss(animated: true) {
                        self.onComplete?(results)
                    }
                }
            }
        }
    }
}

// MARK: - HLAlbumCell

private final class HLAlbumCell: UICollectionViewCell {

    static let reuseID = "HLAlbumCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()

    private let hlMaskView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        v.isHidden = true
        return v
    }()

    private let badgeView: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBlue
        v.layer.cornerRadius = 12
        v.isHidden = true
        return v
    }()

    private let badgeLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()

    private let videoIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "video.fill"))
        iv.tintColor = .white
        iv.isHidden = true
        return iv
    }()

    private var requestID: PHImageRequestID?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(imageView)
        contentView.addSubview(hlMaskView)
        contentView.addSubview(badgeView)
        contentView.addSubview(videoIcon)
        badgeView.addSubview(badgeLabel)

        imageView.frame = contentView.bounds
        hlMaskView.frame = contentView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hlMaskView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        videoIcon.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            badgeView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            badgeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            badgeView.widthAnchor.constraint(equalToConstant: 24),
            badgeView.heightAnchor.constraint(equalToConstant: 24),

            badgeLabel.centerXAnchor.constraint(equalTo: badgeView.centerXAnchor),
            badgeLabel.centerYAnchor.constraint(equalTo: badgeView.centerYAnchor),

            videoIcon.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            videoIcon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            videoIcon.widthAnchor.constraint(equalToConstant: 18),
            videoIcon.heightAnchor.constraint(equalToConstant: 14),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        if let id = requestID {
            PHImageManager.default().cancelImageRequest(id)
        }
        imageView.image = nil
        badgeView.isHidden = true
        hlMaskView.isHidden = true
        videoIcon.isHidden = true
    }

    func configure(asset: PHAsset, selectedIndex: Int?, isEnabled: Bool) {
        let size = CGSize(width: bounds.width * UIScreen.main.scale, height: bounds.height * UIScreen.main.scale)
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic

        requestID = PHImageManager.default().requestImage(
            for: asset, targetSize: size, contentMode: .aspectFill, options: options
        ) { [weak self] image, _ in
            DispatchQueue.main.async { self?.imageView.image = image }
        }

        if let index = selectedIndex {
            badgeView.isHidden = false
            badgeLabel.text = "\(index)"
            hlMaskView.isHidden = false
        } else {
            badgeView.isHidden = true
            hlMaskView.isHidden = !(!isEnabled)
        }

        videoIcon.isHidden = asset.mediaType != .video
    }
}
