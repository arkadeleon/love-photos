//
//  VideoObjectPreviewViewController.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/17.
//

import AVFoundation
import Combine
import UIKit

class VideoObjectPreviewViewController: UIViewController {

    let manager: S3ObjectManager
    let object: S3Object

    private var subscriptions = Set<AnyCancellable>()

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

        view.backgroundColor = .black

        let thumbnailView = UIImageView()
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.contentMode = .scaleAspectFit
        view.addSubview(thumbnailView)

        thumbnailView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        thumbnailView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        thumbnailView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        thumbnailView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        Task {
            let thumbnail = try await manager.thumbnailForObject(object)
            thumbnailView.image = thumbnail

            guard let url = try await manager.urlForObject(object) else {
                return
            }

            let player = AVPlayer(url: url)
            player.play()

            KeyValueObservingPublisher(object: player, keyPath: \.status, options: [])
                .sink(receiveValue: { status in
                    if status == .readyToPlay {
                        thumbnailView.image = nil

                        let layer = AVPlayerLayer(player: player)
                        layer.backgroundColor = UIColor.black.cgColor
                        layer.frame = self.view.bounds
                        layer.videoGravity = .resizeAspect
                        self.view.layer.addSublayer(layer)
                    }
                })
                .store(in: &subscriptions)
        }
    }
}
