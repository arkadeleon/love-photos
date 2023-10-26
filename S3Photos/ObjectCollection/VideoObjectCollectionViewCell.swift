//
//  VideoObjectCollectionViewCell.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/24.
//

import UIKit

class VideoObjectCollectionViewCell: UICollectionViewCell {

    var thumbnailView: UIImageView!

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

    func configure(withManager manager: S3ObjectManager, object: S3Object) {
        thumbnailView.image = nil
        Task {
            for try await thumbnail in manager.thumbnailStreamForObject(object) {
                thumbnailView.image = thumbnail
            }
        }
    }
}
