//
//  S3ObjectManager.swift
//  S3Photos
//
//  Created by Leon Li on 2023/9/26.
//

import AVFoundation
import CoreData
import SotoS3
import UIKit

class S3ObjectManager {

    let account: S3Account

    private let cache: S3ObjectCache
    private let service: S3ObjectService

    init(account: S3Account) {
        self.account = account

        cache = S3ObjectCache(account: account)
        service = S3ObjectService(account: account)
    }

    func listObjects(prefix: String) async throws {
        let objects = try await service.listObjects(prefix: prefix)
        try await PersistenceController.shared.insertObjects(objects, prefix: prefix)
    }

    func urlForObject(_ object: S3Object) async throws -> URL? {
        guard let key = object.key else {
            return nil
        }

        let url = try await service.signObject(key: key)
        return url
    }

    func thumbnailStreamForObject(_ object: S3Object, count: Int = 1) -> AsyncThrowingStream<UIImage, Error> {
        AsyncThrowingStream { continuation in
            Task {
                switch object.type {
                case .group:
                    var objects = try await PersistenceController.shared.fetchObjects(for: account, prefix: object.key!)
                    if objects.isEmpty {
                        try await listObjects(prefix: object.key!)
                        objects = try await PersistenceController.shared.fetchObjects(for: account, prefix: object.key!)
                    }
                    for object in objects.prefix(count) {
                        for try await thumbnail in thumbnailStreamForObject(object) {
                            continuation.yield(thumbnail)
                        }
                    }
                    continuation.finish()
                default:
                    if let thumbnail = try await thumbnailForObject(object) {
                        continuation.yield(thumbnail)
                    }
                    continuation.finish()
                }
            }
        }
    }

    func previewForObject(_ object: S3Object) async throws -> UIImage? {
        guard object.type == .photo else {
            return nil
        }

        if let data = cache.data(for: object) {
            return UIImage(data: data)
        }

        let data = try await service.getObject(key: object.key!)

        cache.setData(data, forObject: object)

        return UIImage(data: data)
    }
}

extension S3ObjectManager {
    private func thumbnailForObject(_ object: S3Object) async throws -> UIImage? {
        switch object.type {
        case .photo:
            if let thumbnail = cache.thumbnail(for: object) {
                return thumbnail
            }

            let url = try await service.signObject(key: object.key!)
            let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
            guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else {
                return nil
            }

            let downsampleOptions: [CFString : Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceShouldCacheImmediately: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 200
            ]
            let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions as CFDictionary)
            let thumbnail = downsampledImage.map(UIImage.init)

            if let thumbnail {
                cache.setThumbnail(thumbnail, forObject: object)
            }

            return thumbnail
        case .video:
            if let thumbnail = cache.thumbnail(for: object) {
                return thumbnail
            }

            let url = try await service.signObject(key: object.key!)
            let asset = AVAsset(url: url)
            let assetImageGenerator = AVAssetImageGenerator(asset: asset)
            assetImageGenerator.maximumSize = CGSize(width: 200, height: 200)
            assetImageGenerator.appliesPreferredTrackTransform = true

            let thumbnail = await withCheckedContinuation { continuation in
                assetImageGenerator.generateCGImageAsynchronously(for: CMTime(value: 0, timescale: 60)) { image, time, error in
                    continuation.resume(returning: image.flatMap(UIImage.init))
                }
            }

            if let thumbnail {
                cache.setThumbnail(thumbnail, forObject: object)
            }

            return thumbnail
        default:
            return nil
        }
    }
}
