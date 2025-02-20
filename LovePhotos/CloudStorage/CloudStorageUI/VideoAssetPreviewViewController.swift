//
//  VideoAssetPreviewViewController.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/10/17.
//

import AVFoundation
import Combine
import UIKit

class VideoAssetPreviewViewController: UIViewController {

    let manager: AssetManager
    let asset: Asset

    private var thumbnailTask: Task<UIImage?, Error>?
    private var player: AVPlayer?

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

    deinit {
        thumbnailTask?.cancel()
        player?.pause()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let thumbnailView = UIImageView(frame: view.bounds)
        thumbnailView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        thumbnailView.contentMode = .scaleAspectFit
        view.addSubview(thumbnailView)

        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.layer.zPosition = 1
        view.addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        Task {
            thumbnailTask = manager.thumbnailTask(for: asset)
            thumbnailView.image = try await thumbnailTask?.value

            guard let url = try await manager.url(for: asset) else {
                return
            }

            let item = AVPlayerItem(url: url)
            player = AVPlayer(playerItem: item)

            let layer = AVPlayerLayer(player: player)
            layer.backgroundColor = UIColor.systemBackground.cgColor
            layer.frame = view.bounds
            layer.videoGravity = .resizeAspect

            let interval = CMTime(seconds: 1, preferredTimescale: 1)
            player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { currentTime in
                let progress = Float(currentTime.seconds) / Float(item.duration.seconds)
                if !progress.isNaN {
                    Task { @MainActor in
                        progressView.progress = progress
                    }
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

            player?.play()
        }
    }
}
