//
//  AssetCache.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/16.
//

import Foundation
import UIKit

class AssetCache {

    let account: Account

    private let thumbnailCache = NSCache<NSString, UIImage>()

    private let diskCacheURL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

    init(account: Account) {
        self.account = account
    }

    func data(for asset: Asset) -> Data? {
        guard let eTag = asset.eTag?.trimmingCharacters(in: CharacterSet(["\""])) else {
            return nil
        }

        let url = diskCacheURL.appending(path: "\(eTag).asset")
        let data = try? Data(contentsOf: url)

        return data
    }

    func setData(_ data: Data, forAsset asset: Asset) {
        guard let eTag = asset.eTag?.trimmingCharacters(in: CharacterSet(["\""])) else {
            return
        }

        let url = diskCacheURL.appending(path: "\(eTag).asset")
        try? data.write(to: url, options: .atomic)
    }

    func thumbnail(for asset: Asset) -> UIImage? {
        guard let eTag = asset.eTag?.trimmingCharacters(in: CharacterSet(["\""])) else {
            return nil
        }

        var thumbnail: UIImage? = nil

        thumbnail = thumbnailCache.object(forKey: eTag as NSString)

        if thumbnail == nil {
            let url = diskCacheURL.appending(path: "\(eTag).asset.thumbnail")
            let data = try? Data(contentsOf: url)
            thumbnail = data.flatMap(UIImage.init)
        }

        return thumbnail
    }

    func setThumbnail(_ thumbnail: UIImage, forAsset asset: Asset) {
        guard let eTag = asset.eTag?.trimmingCharacters(in: CharacterSet(["\""])) else {
            return
        }

        thumbnailCache.setObject(thumbnail, forKey: eTag as NSString)

        let url = diskCacheURL.appending(path: "\(eTag).asset.thumbnail")
        let data = thumbnail.jpegData(compressionQuality: 1)
        try? data?.write(to: url, options: .atomic)
    }
}
