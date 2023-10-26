//
//  OtherObjectCollectionViewCell.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/24.
//

import UIKit

class OtherObjectCollectionViewCell: UICollectionViewCell {

    var nameLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)

        nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.numberOfLines = 2
        contentView.addSubview(nameLabel)

        nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(withManager manager: S3ObjectManager, object: S3Object) {
        nameLabel.text = object.name
    }
}
