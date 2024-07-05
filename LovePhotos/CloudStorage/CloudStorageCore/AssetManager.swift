//
//  AssetManager.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/9/26.
//

import AVFoundation
import CoreData
import UIKit

enum AssetManagerError: Error {
    case unknownMediaType
    case failedToCreateImageSource
    case failedToCopyPropertiesFromImageSource
    case failedToLoadCreationDateFromAVAsset
}

class AssetManager {

    let account: Account

    private let cache: AssetCache
    private let service: S3AssetService

    init(account: Account) {
        self.account = account

        cache = AssetCache(account: account)
        service = S3AssetService(account: account)
    }

    func assetList(for parentIdentifier: String) async throws {
        let assetList = try await service.assetList(for: parentIdentifier)
        try await PersistenceController.shared.insertAssetList(assetList)
    }

    func url(for asset: Asset) async throws -> URL? {
        guard let identifier = asset.identifier else {
            return nil
        }

        let url = try await service.urlForAsset(identifier: identifier)
        return url
    }

    func thumbnailStream(for asset: Asset, count: Int = 1) -> AsyncThrowingStream<UIImage, Error> {
        AsyncThrowingStream { continuation in
            Task {
                switch asset.type {
                case .folder:
                    var assets = try await PersistenceController.shared.fetchAssets(for: account, parentIdentifier: asset.identifier!)
                    if assets.isEmpty {
                        try await assetList(for: asset.identifier!)
                        assets = try await PersistenceController.shared.fetchAssets(for: account, parentIdentifier: asset.identifier!)
                    }
                    for asset in assets.prefix(count) {
                        for try await thumbnail in thumbnailStream(for: asset) {
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

    func metadataTask(for asset: Asset) -> Task<AssetMetadata, Error> {
        Task {
            try Task.checkCancellation()

            if let creationDate = asset.creationDate {
                let metadata = AssetMetadata(creationDate: creationDate, duration: asset.duration)
                return metadata
            }

            try Task.checkCancellation()

            switch asset.mediaType {
            case .image:
                let url = try await service.urlForAsset(identifier: asset.identifier!)

                try Task.checkCancellation()

                let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
                guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else {
                    throw AssetManagerError.failedToCreateImageSource
                }

                try Task.checkCancellation()

                guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as NSDictionary?,
                      let exif = properties[kCGImagePropertyExifDictionary] as? NSDictionary,
                      let dateTimeOriginal = exif[kCGImagePropertyExifDateTimeOriginal] as? NSString
                else {
                    throw AssetManagerError.failedToCopyPropertiesFromImageSource
                }

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                let creationDate = dateFormatter.date(from: dateTimeOriginal as String)

                let metadata = AssetMetadata(creationDate: creationDate)

                try await PersistenceController.shared.saveMetadata(metadata, for: asset)

                return metadata
            case .video:
                let url = try await service.urlForAsset(identifier: asset.identifier!)

                try Task.checkCancellation()

                let avAsset = AVAsset(url: url)
                let (creationDate, duration) = try await avAsset.load(.creationDate, .duration)
                let creationDateValue = try await creationDate?.load(.dateValue)
                let durationValue = Int32(duration.seconds)

                let metadata = AssetMetadata(creationDate: creationDateValue, duration: durationValue)

                try await PersistenceController.shared.saveMetadata(metadata, for: asset)

                return metadata
            default:
                throw AssetManagerError.unknownMediaType
            }
        }
    }
}
