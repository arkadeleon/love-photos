//
//  VideoAssetCollectionViewCell.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/10/24.
//

import UIKit

class VideoAssetCollectionViewCell: UICollectionViewCell {

    var thumbnailView: UIImageView!
    var durationLabel: UILabel!

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

        durationLabel = UILabel()
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        durationLabel.font = .preferredFont(forTextStyle: .caption1)
        durationLabel.textColor = .white
        contentView.addSubview(durationLabel)

        NSLayoutConstraint.activate([
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            durationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
        ])
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

            durationLabel.text = try await metadataTask?.value.duration.map { duration in
                let minutes = duration / 60
                let seconds = duration % 60
                return String(format: "%d:%02d", minutes, seconds)
            }
        }
    }
}
