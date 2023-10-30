//
//  PhotoObjectCollectionViewCell.swift
//  S3Photos
//
//  Created by Leon Li on 2023/9/26.
//

import UIKit

class PhotoObjectCollectionViewCell: UICollectionViewCell {

    var thumbnailView: UIImageView!

    private var thumbnailTask: Task<UIImage?, Error>?

    override init(frame: CGRect) {
        super.init(frame: frame)

        thumbnailView = UIImageView()
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.backgroundColor = .secondarySystemBackground
        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        contentView.addSubview(thumbnailView)

        thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        thumbnailView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        thumbnailView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        thumbnailView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        thumbnailTask?.cancel()
        thumbnailTask = nil
    }

    func configure(withManager manager: S3ObjectManager, object: S3Object) {
        thumbnailView.image = nil

        thumbnailTask = manager.thumbnailTask(for: object)

        Task {
            thumbnailView.image = try await thumbnailTask?.value
        }
    }
}
