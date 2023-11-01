//
//  AssetManager.swift
//  CloudPhotos
//
//  Created by Leon Li on 2023/9/26.
//

import AVFoundation
import CoreData
import UIKit

class AssetManager {

    let account: Account

    private let cache: AssetCache
    private let service: S3AssetService

    init(account: Account) {
        self.account = account

        cache = AssetCache(account: account)
        service = S3AssetService(account: account)
    }

    func listAssets(parentIdentifier: String) async throws {
        let assets = try await service.listAssets(parentIdentifier: parentIdentifier)
        try await PersistenceController.shared.insertAssets(assets, parentIdentifier: parentIdentifier)
    }

    func urlForAsset(_ asset: Asset) async throws -> URL? {
        guard let identifier = asset.identifier else {
            return nil
        }

        let url = try await service.urlForAsset(identifier: identifier)
        return url
    }

    func thumbnailStreamForAsset(_ asset: Asset, count: Int = 1) -> AsyncThrowingStream<UIImage, Error> {
        AsyncThrowingStream { continuation in
            Task {
                switch asset.type {
                case .folder:
                    var assets = try await PersistenceController.shared.fetchAssets(for: account, parentIdentifier: asset.identifier!)
                    if assets.isEmpty {
                        try await listAssets(parentIdentifier: asset.identifier!)
                        assets = try await PersistenceController.shared.fetchAssets(for: account, parentIdentifier: asset.identifier!)
                    }
                    for asset in assets.prefix(count) {
                        for try await thumbnail in thumbnailStreamForAsset(asset) {
                            continuation.yield(thumbnail)
                        }
                    }
                    continuation.finish()
                case .file:
                    if let thumbnail = try await thumbnailTask(for: asset).value {
                        continuation.yield(thumbnail)
                    }
                    continuation.finish()
                default:
                    continuation.finish()
                }
            }
        }
    }

    func thumbnailTask(for asset: Asset) -> Task<UIImage?, Error> {
        Task {
            switch asset.mediaType {
            case .image:
                try Task.checkCancellation()

                if let thumbnail = cache.thumbnail(for: asset) {
                    return thumbnail
                }

                try Task.checkCancellation()

                let url = try await service.urlForAsset(identifier: asset.identifier!)

                try Task.checkCancellation()

                let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
                guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else {
                    return nil
                }

                try Task.checkCancellation()

                let downsampleOptions: [CFString : Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceShouldCacheImmediately: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 200
                ]
                let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions as CFDictionary)
                let thumbnail = downsampledImage.map(UIImage.init)

                try Task.checkCancellation()

                if let thumbnail {
                    cache.setThumbnail(thumbnail, forAsset: asset)
                }

                try Task.checkCancellation()

                return thumbnail
            case .video:
                try Task.checkCancellation()

                if let thumbnail = cache.thumbnail(for: asset) {
                    return thumbnail
                }

                try Task.checkCancellation()

                let url = try await service.urlForAsset(identifier: asset.identifier!)

                try Task.checkCancellation()

                let avAsset = AVAsset(url: url)
                let avAssetImageGenerator = AVAssetImageGenerator(asset: avAsset)
                avAssetImageGenerator.maximumSize = CGSize(width: 200, height: 200)
                avAssetImageGenerator.appliesPreferredTrackTransform = true
                let thumbnail = await withCheckedContinuation { continuation in
                    avAssetImageGenerator.generateCGImageAsynchronously(for: CMTime(value: 0, timescale: 60)) { image, time, error in
                        continuation.resume(returning: image.flatMap(UIImage.init))
                    }
                }

                try Task.checkCancellation()

                if let thumbnail {
                    cache.setThumbnail(thumbnail, forAsset: asset)
                }

                try Task.checkCancellation()

                return thumbnail
            default:
                return nil
            }
        }
    }

    func previewTask(for asset: Asset) -> Task<UIImage?, Error> {
        Task {
            guard asset.mediaType == .image else {
                return nil
            }

            try Task.checkCancellation()

            if let data = cache.data(for: asset) {
                return UIImage(data: data)
            }

            try Task.checkCancellation()

            let data = try await service.dataForAsset(identifier: asset.identifier!)

            try Task.checkCancellation()

            cache.setData(data, forAsset: asset)

            try Task.checkCancellation()

            return UIImage(data: data)
        }
    }
}