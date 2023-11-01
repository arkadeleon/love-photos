//
//  VideoAssetPreviewViewController.swift
//  CloudPhotos
//
//  Created by Leon Li on 2023/10/17.
//

import AVFoundation
import Combine
import UIKit

class VideoAssetPreviewViewController: UIViewController {

    let manager: AssetManager
    let asset: Asset

    private var subscriptions = Set<AnyCancellable>()

    init(manager: AssetManager, asset: Asset) {
        self.manager = manager
        self.asset = asset

        super.init(nibName: nil, bundle: nil)

        title = asset.name
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let thumbnailView = UIImageView()
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.contentMode = .scaleAspectFit
        view.addSubview(thumbnailView)

        thumbnailView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        thumbnailView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        thumbnailView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        thumbnailView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.layer.zPosition = 1
        view.addSubview(progressView)

        progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        progressView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true

        Task {
            for try await thumbnail in manager.thumbnailStreamForAsset(asset) {
                thumbnailView.image = thumbnail
            }

            guard let url = try await manager.urlForAsset(asset) else {
                return
            }

            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)

            let layer = AVPlayerLayer(player: player)
            layer.backgroundColor = UIColor.systemBackground.cgColor
            layer.frame = view.bounds
            layer.videoGravity = .resizeAspect

            let interval = CMTime(seconds: 1, preferredTimescale: 1)
            player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { currentTime in
                let progress = Float(currentTime.seconds) / Float(item.duration.seconds)
                if !progress.isNaN {
                    progressView.progress = progress
                }
            }

            KeyValueObservingPublisher(object: layer, keyPath: \.isReadyForDisplay, options: [])
                .sink(receiveValue: { isReadyForDisplay in
                    if isReadyForDisplay {
                        thumbnailView.image = nil
                        self.view.layer.addSublayer(layer)
                    }
                })
                .store(in: &subscriptions)

            player.play()
        }
    }
}
