//
//  PhotoObjectPreviewViewController.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/16.
//

import UIKit

class PhotoObjectPreviewViewController: UIViewController {

    let manager: S3ObjectManager
    let object: S3Object

    var imageView: UIImageView!

    init(manager: S3ObjectManager, object: S3Object) {
        self.manager = manager
        self.object = object
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)

        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        Task {
            for try await thumbnail in manager.thumbnailStreamForObject(object) {
                imageView.image = thumbnail
            }

            let preview = try await manager.previewForObject(object)
            imageView.image = preview
        }
    }
}
