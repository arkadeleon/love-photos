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

    private let s3: S3

    private let cache: S3ObjectCache

    init(account: S3Account) {
        self.account = account

        let client = AWSClient(
            credentialProvider: .static(accessKeyId: account.accessKeyId!, secretAccessKey: account.secretAccessKey!),
            httpClientProvider: .createNew
        )
        s3 = S3(client: client, endpoint: account.endpoint!)

        cache = S3ObjectCache(account: account)
    }

    func listObjects(prefix: String) async throws {
        let input = S3.ListObjectsV2Request(bucket: account.bucket!, delimiter: "/", prefix: prefix)
        let output = try await s3.listObjectsV2(input)

        let context = PersistenceController.shared.container.viewContext

        if let commonPrefixes = output.commonPrefixes {
            for commonPrefix in commonPrefixes {
                let fetchRequest = NSFetchRequest<S3Object>(entityName: "S3Object")
                fetchRequest.predicate = NSPredicate(format: "key == %@", commonPrefix.prefix!)
                let objects = try context.fetch(fetchRequest)

                if objects.isEmpty {
                    let object = S3Object(context: PersistenceController.shared.container.viewContext)
                    object.prefix = prefix
                    object.key = commonPrefix.prefix
                    try context.save()
                }
            }
        }

        if let contents = output.contents {
            for content in contents {
                let fetchRequest = NSFetchRequest<S3Object>(entityName: "S3Object")
                fetchRequest.predicate = NSPredicate(format: "key == %@", content.key!)
                let objects = try context.fetch(fetchRequest)

                if objects.isEmpty {
                    let object = S3Object(context: PersistenceController.shared.container.viewContext)
                    object.prefix = prefix
                    object.eTag = content.eTag
                    object.key = content.key
                    object.lastModified = content.lastModified
                    object.size = content.size ?? 0
                    try context.save()
                }
            }
        }
    }

    func urlForObject(_ object: S3Object) async throws -> URL? {
        guard let key = object.key else {
            return nil
        }

        let url = URL(string: account.endpoint!)!.appending(path: account.bucket!).appending(path: key)
        let signedURL = try await s3.signURL(url: url, httpMethod: .GET, expires: .hours(1))
        return signedURL
    }

    func thumbnailForObject(_ object: S3Object) async throws -> UIImage? {
        guard let key = object.key else {
            return nil
        }

        let context = PersistenceController.shared.container.viewContext

        let fetchRequest = NSFetchRequest<S3Object>(entityName: "S3Object")
        fetchRequest.predicate = NSPredicate(format: "key == %@", key)
        let objects = try context.fetch(fetchRequest)

        guard let object = objects.first else {
            return nil
        }

        switch object.type {
        case .folder:
            return nil
        case .photo:
            if let thumbnail = cache.thumbnail(for: object) {
                return thumbnail
            }

            let request = S3.GetObjectRequest(bucket: account.bucket!, key: key)
            let response = try await s3.getObject(request)

            guard let data = response.body?.asData(),
                  let thumbnail = downsampledImage(data: data, to: CGSize(width: 200, height: 200), scale: 1) else {
                return nil
            }

            cache.setData(data, forObject: object)
            cache.setThumbnail(thumbnail, forObject: object)

            return thumbnail
        case .video:
            if let thumbnail = cache.thumbnail(for: object) {
                return thumbnail
            }

            let url = URL(string: account.endpoint!)!.appending(path: account.bucket!).appending(path: key)
            let signedURL = try await s3.signURL(url: url, httpMethod: .GET, expires: .minutes(1))

            let asset = AVAsset(url: signedURL)
            let assetImageGenerator = AVAssetImageGenerator(asset: asset)
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
        case .other:
            return nil
        }
    }

    func previewForObject(_ object: S3Object) async throws -> UIImage? {
        guard let key = object.key else {
            return nil
        }

        let context = PersistenceController.shared.container.viewContext

        let fetchRequest = NSFetchRequest<S3Object>(entityName: "S3Object")
        fetchRequest.predicate = NSPredicate(format: "key == %@", key)
        let objects = try context.fetch(fetchRequest)

        guard let object = objects.first else {
            return nil
        }

        guard object.type == .photo else {
            return nil
        }

        if let data = cache.data(for: object) {
            return UIImage(data: data)
        }

        let request = S3.GetObjectRequest(bucket: account.bucket!, key: key)
        let response = try await s3.getObject(request)

        guard let data = response.body?.asData() else {
            return nil
        }

        cache.setData(data, forObject: object)

        return UIImage(data: data)
    }

    private func downsampledImage(data: Data, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }

        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions: [CFString : Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ]
        let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions as CFDictionary)
        return downsampledImage.map(UIImage.init)
    }
}
