//
//  FolderObjectCollectionViewCell.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/20.
//

import UIKit

class FolderObjectCollectionViewCell: UICollectionViewCell {
    
    var thumbnailViews: [UIImageView]!
    var nameLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.cornerRadius = 4
        contentView.layer.masksToBounds = true

        let thumbnailView0 = {
            let thumbnailView = UIImageView()
            thumbnailView.translatesAutoresizingMaskIntoConstraints = false
            thumbnailView.backgroundColor = .secondarySystemBackground
            thumbnailView.contentMode = .scaleAspectFill
            thumbnailView.clipsToBounds = true
            contentView.addSubview(thumbnailView)

            thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            thumbnailView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            thumbnailView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -1).isActive = true
            thumbnailView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5, constant: -1).isActive = true

            return thumbnailView
        }()

        let thumbnailView1 = {
            let thumbnailView = UIImageView()
            thumbnailView.translatesAutoresizingMaskIntoConstraints = false
            thumbnailView.backgroundColor = .secondarySystemBackground
            thumbnailView.contentMode = .scaleAspectFill
            thumbnailView.clipsToBounds = true
            contentView.addSubview(thumbnailView)

            thumbnailView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            thumbnailView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            thumbnailView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -1).isActive = true
            thumbnailView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5, constant: -1).isActive = true

            return thumbnailView
        }()

        let thumbnailView2 = {
            let thumbnailView = UIImageView()
            thumbnailView.translatesAutoresizingMaskIntoConstraints = false
            thumbnailView.backgroundColor = .secondarySystemBackground
            thumbnailView.contentMode = .scaleAspectFill
            thumbnailView.clipsToBounds = true
            contentView.addSubview(thumbnailView)

            thumbnailView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            thumbnailView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
            thumbnailView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -1).isActive = true
            thumbnailView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5, constant: -1).isActive = true

            return thumbnailView
        }()

        let thumbnailView3 = {
            let thumbnailView = UIImageView()
            thumbnailView.translatesAutoresizingMaskIntoConstraints = false
            thumbnailView.backgroundColor = .secondarySystemBackground
            thumbnailView.contentMode = .scaleAspectFill
            thumbnailView.clipsToBounds = true
            contentView.addSubview(thumbnailView)

            thumbnailView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            thumbnailView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
            thumbnailView.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5, constant: -1).isActive = true
            thumbnailView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5, constant: -1).isActive = true

            return thumbnailView
        }()

        thumbnailViews = [thumbnailView0, thumbnailView1, thumbnailView2, thumbnailView3]

        nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
        nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(withManager manager: S3ObjectManager, object: S3Object) {
        for thumbnailView in thumbnailViews {
            thumbnailView.image = nil
        }

        Task {
            var index = 0
            for try await thumbnail in manager.thumbnailStreamForObject(object, count: 4) {
                thumbnailViews[index].image = thumbnail
                index += 1
            }
        }

        nameLabel.text = object.key?.split(separator: "/").last.map(String.init)
    }
}
