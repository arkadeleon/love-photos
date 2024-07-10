//
//  ImageAssetCollectionViewCell.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/9/26.
//

import UIKit

class ImageAssetCollectionViewCell: UICollectionViewCell {

    var thumbnailView: UIImageView!

    private var thumbnailTask: Task<UIImage?, Error>?
    private var metadataTask: Task<AssetMetadata, Error>?

    override init(frame: CGRect) {
        super.init(frame: frame)

        thumbnailView = UIImageView(frame: contentView.bounds)
        thumbnailView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        thumbnailView.backgroundColor = .secondarySystemBackground
        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        contentView.addSubview(thumbnailView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        thumbnailTask?.cancel()
        thumbnailTask = nil

        metadataTask?.cancel()
        metadataTask = nil
    }

    func configure(withManager manager: AssetManager, asset: Asset) {
        thumbnailView.image = nil

        thumbnailTask = manager.thumbnailTask(for: asset)
        metadataTask = manager.metadataTask(for: asset)

        Task {
            thumbnailView.image = try await thumbnailTask?.value
        }
    }
}
