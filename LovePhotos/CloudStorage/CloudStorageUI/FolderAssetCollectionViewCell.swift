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

        let thumbnailContainerView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)

            view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            view.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            view.heightAnchor.constraint(equalTo: view.widthAnchor).isActive = true

            return view
        }()

        let thumbnailView1 = {
            let thumbnailView = UIImageView()
            thumbnailView.translatesAutoresizingMaskIntoConstraints = false
            thumbnailView.backgroundColor = .secondarySystemBackground
            thumbnailView.contentMode = .scaleAspectFill
            thumbnailView.clipsToBounds = true
            thumbnailView.layer.cornerRadius = 4
            thumbnailView.layer.masksToBounds = true
            thumbnailContainerView.addSubview(thumbnailView)

            thumbnailView.leadingAnchor.constraint(equalTo: thumbnailContainerView.leadingAnchor).isActive = true
            thumbnailView.topAnchor.constraint(equalTo: thumbnailContainerView.topAnchor).isActive = true
            thumbnailView.widthAnchor.constraint(equalTo: thumbnailContainerView.widthAnchor, multiplier: 0.5, constant: -1).isActive = true
            thumbnailView.heightAnchor.constraint(equalTo: thumbnailContainerView.heightAnchor, multiplier: 0.5, constant: -1).isActive = true

            return thumbnailView
        }()

        let thumbnailView2 = {
            let thumbnailView = UIImageView()
            thumbnailView.translatesAutoresizingMaskIntoConstraints = false
            thumbnailView.backgroundColor = .secondarySystemBackground
            thumbnailView.contentMode = .scaleAspectFill
            thumbnailView.clipsToBounds = true
            thumbnailView.layer.cornerRadius = 4
            thumbnailView.layer.masksToBounds = true
            thumbnailContainerView.addSubview(thumbnailView)

            thumbnailView.trailingAnchor.constraint(equalTo: thumbnailContainerView.trailingAnchor).isActive = true
            thumbnailView.topAnchor.constraint(equalTo: thumbnailContainerView.topAnchor).isActive = true
            thumbnailView.widthAnchor.constraint(equalTo: thumbnailContainerView.widthAnchor, multiplier: 0.5, constant: -1).isActive = true
            thumbnailView.heightAnchor.constraint(equalTo: thumbnailContainerView.heightAnchor, multiplier: 0.5, constant: -1).isActive = true

            return thumbnailView
        }()

        let thumbnailView3 = {
            let thumbnailView = UIImageView()
            thumbnailView.translatesAutoresizingMaskIntoConstraints = false
            thumbnailView.backgroundColor = .secondarySystemBackground
            thumbnailView.contentMode = .scaleAspectFill
            thumbnailView.clipsToBounds = true
            thumbnailView.layer.cornerRadius = 4
            thumbnailView.layer.masksToBounds = true
            thumbnailContainerView.addSubview(thumbnailView)

            thumbnailView.leadingAnchor.constraint(equalTo: thumbnailContainerView.leadingAnchor).isActive = true
            thumbnailView.bottomAnchor.constraint(equalTo: thumbnailContainerView.bottomAnchor).isActive = true
            thumbnailView.widthAnchor.constraint(equalTo: thumbnailContainerView.widthAnchor, multiplier: 0.5, constant: -1).isActive = true
            thumbnailView.heightAnchor.constraint(equalTo: thumbnailContainerView.heightAnchor, multiplier: 0.5, constant: -1).isActive = true

            return thumbnailView
        }()

        let thumbnailView4 = {
            let thumbnailView = UIImageView()
            thumbnailView.translatesAutoresizingMaskIntoConstraints = false
            thumbnailView.backgroundColor = .secondarySystemBackground
            thumbnailView.contentMode = .scaleAspectFill
            thumbnailView.clipsToBounds = true
            thumbnailView.layer.cornerRadius = 4
            thumbnailView.layer.masksToBounds = true
            thumbnailContainerView.addSubview(thumbnailView)

            thumbnailView.trailingAnchor.constraint(equalTo: thumbnailContainerView.trailingAnchor).isActive = true
            thumbnailView.bottomAnchor.constraint(equalTo: thumbnailContainerView.bottomAnchor).isActive = true
            thumbnailView.widthAnchor.constraint(equalTo: thumbnailContainerView.widthAnchor, multiplier: 0.5, constant: -1).isActive = true
            thumbnailView.heightAnchor.constraint(equalTo: thumbnailContainerView.heightAnchor, multiplier: 0.5, constant: -1).isActive = true

            return thumbnailView
        }()

        thumbnailViews = [thumbnailView1, thumbnailView2, thumbnailView3, thumbnailView4]

        nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)

        nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        nameLabel.topAnchor.constraint(equalTo: thumbnailContainerView.bottomAnchor).isActive = true
        nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
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
