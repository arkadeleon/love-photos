//
//  UnknownAssetCollectionViewCell.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/10/24.
//

import UIKit

class UnknownAssetCollectionViewCell: UICollectionViewCell {

    var nameLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = .secondarySystemBackground

        nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2
        contentView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(withManager manager: AssetManager, asset: Asset) {
        nameLabel.text = asset.name
    }
}
