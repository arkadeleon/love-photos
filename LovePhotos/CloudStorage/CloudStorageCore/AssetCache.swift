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
}
