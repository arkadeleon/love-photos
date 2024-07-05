//
//  AssetCache.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/10/16.
//

import Foundation
import UIKit

class AssetCache {

    let account: Account
    let diskCacheURL: URL

    private let thumbnailCache = NSCache<NSString, UIImage>()

    init(account: Account) {
        self.account = account

        diskCacheURL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appending(path: account.identifier!)

        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }

    func data(for asset: Asset) -> Data? {
        guard let cacheIdentifier = asset.cacheIdentifier else {
            return nil
        }

        let url = diskCacheURL.appending(path: "\(cacheIdentifier).asset")
        let data = try? Data(contentsOf: url)

        return data
    }

    func setData(_ data: Data, forAsset asset: Asset) {
        guard let cacheIdentifier = asset.cacheIdentifier else {
            return
        }

        let url = diskCacheURL.appending(path: "\(cacheIdentifier).asset")
        try? data.write(to: url, options: .atomic)
    }

    func thumbnail(for asset: Asset) -> UIImage? {
        guard let cacheIdentifier = asset.cacheIdentifier else {
            return nil
        }

        var thumbnail: UIImage? = nil

        thumbnail = thumbnailCache.object(forKey: cacheIdentifier as NSString)

        if thumbnail == nil {
            let url = diskCacheURL.appending(path: "\(cacheIdentifier).asset.thumbnail")
            let data = try? Data(contentsOf: url)
            thumbnail = data.flatMap(UIImage.init)
        }

        return thumbnail
    }

    func setThumbnail(_ thumbnail: UIImage, forAsset asset: Asset) {
        guard let cacheIdentifier = asset.cacheIdentifier else {
            return
        }

        thumbnailCache.setObject(thumbnail, forKey: cacheIdentifier as NSString)

        let url = diskCacheURL.appending(path: "\(cacheIdentifier).asset.thumbnail")
        let data = thumbnail.jpegData(compressionQuality: 1)
        try? data?.write(to: url, options: .atomic)
    }
}
