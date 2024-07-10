//
//  FolderAssetCollectionViewCell.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/10/20.
//

import UIKit

class FolderAssetCollectionViewCell: UICollectionViewCell {

    var thumbnailViews: [UIImageView]!
    var nameLabel: UILabel!

    private var thumbnailTask: Task<Void, Error>?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let thumbnailGridView = UIView()
        thumbnailGridView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(thumbnailGridView)

        let thumbnailView1 = UIImageView()
        thumbnailView1.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView1.backgroundColor = .secondarySystemBackground
        thumbnailView1.contentMode = .scaleAspectFill
        thumbnailView1.clipsToBounds = true
        thumbnailView1.layer.cornerRadius = 4
        thumbnailView1.layer.masksToBounds = true
        thumbnailGridView.addSubview(thumbnailView1)

        let thumbnailView2 = UIImageView()
        thumbnailView2.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView2.backgroundColor = .secondarySystemBackground
        thumbnailView2.contentMode = .scaleAspectFill
        thumbnailView2.clipsToBounds = true
        thumbnailView2.layer.cornerRadius = 4
        thumbnailView2.layer.masksToBounds = true
        thumbnailGridView.addSubview(thumbnailView2)

        let thumbnailView3 = UIImageView()
        thumbnailView3.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView3.backgroundColor = .secondarySystemBackground
        thumbnailView3.contentMode = .scaleAspectFill
        thumbnailView3.clipsToBounds = true
        thumbnailView3.layer.cornerRadius = 4
        thumbnailView3.layer.masksToBounds = true
        thumbnailGridView.addSubview(thumbnailView3)

        let thumbnailView4 = UIImageView()
        thumbnailView4.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView4.backgroundColor = .secondarySystemBackground
        thumbnailView4.contentMode = .scaleAspectFill
        thumbnailView4.clipsToBounds = true
        thumbnailView4.layer.cornerRadius = 4
        thumbnailView4.layer.masksToBounds = true
        thumbnailGridView.addSubview(thumbnailView4)

        thumbnailViews = [thumbnailView1, thumbnailView2, thumbnailView3, thumbnailView4]

        nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .preferredFont(forTextStyle: .body)
        nameLabel.numberOfLines = 2
        contentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            thumbnailGridView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailGridView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            thumbnailGridView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailGridView.heightAnchor.constraint(equalTo: thumbnailGridView.widthAnchor),

            thumbnailView1.leadingAnchor.constraint(equalTo: thumbnailGridView.leadingAnchor),
            thumbnailView1.topAnchor.constraint(equalTo: thumbnailGridView.topAnchor),
            thumbnailView1.widthAnchor.constraint(equalTo: thumbnailGridView.widthAnchor, multiplier: 0.5, constant: -1),
            thumbnailView1.heightAnchor.constraint(equalTo: thumbnailGridView.heightAnchor, multiplier: 0.5, constant: -1),

            thumbnailView2.trailingAnchor.constraint(equalTo: thumbnailGridView.trailingAnchor),
            thumbnailView2.topAnchor.constraint(equalTo: thumbnailGridView.topAnchor),
            thumbnailView2.widthAnchor.constraint(equalTo: thumbnailGridView.widthAnchor, multiplier: 0.5, constant: -1),
            thumbnailView2.heightAnchor.constraint(equalTo: thumbnailGridView.heightAnchor, multiplier: 0.5, constant: -1),

            thumbnailView3.leadingAnchor.constraint(equalTo: thumbnailGridView.leadingAnchor),
            thumbnailView3.bottomAnchor.constraint(equalTo: thumbnailGridView.bottomAnchor),
            thumbnailView3.widthAnchor.constraint(equalTo: thumbnailGridView.widthAnchor, multiplier: 0.5, constant: -1),
            thumbnailView3.heightAnchor.constraint(equalTo: thumbnailGridView.heightAnchor, multiplier: 0.5, constant: -1),

            thumbnailView4.trailingAnchor.constraint(equalTo: thumbnailGridView.trailingAnchor),
            thumbnailView4.bottomAnchor.constraint(equalTo: thumbnailGridView.bottomAnchor),
            thumbnailView4.widthAnchor.constraint(equalTo: thumbnailGridView.widthAnchor, multiplier: 0.5, constant: -1),
            thumbnailView4.heightAnchor.constraint(equalTo: thumbnailGridView.heightAnchor, multiplier: 0.5, constant: -1),

            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nameLabel.topAnchor.constraint(equalTo: thumbnailGridView.bottomAnchor, constant: 4),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        thumbnailTask?.cancel()
        thumbnailTask = nil
    }

    func configure(withManager manager: AssetManager, asset: Asset) {
        for thumbnailView in thumbnailViews {
            thumbnailView.image = nil
        }

        thumbnailTask = Task.detached {
            var index = 0
            for try await thumbnail in manager.thumbnailStream(for: asset, count: 4) {
                let thumbnailView = await self.thumbnailViews[index]
                await MainActor.run {
                    thumbnailView.image = thumbnail
                }
                index += 1
            }
        }

        nameLabel.text = asset.name
    }
}
