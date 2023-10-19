//
//  S3ObjectCache.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/16.
//

import Foundation

class S3ObjectCache {

    let account: S3Account

    private let diskCacheURL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

    init(account: S3Account) {
        self.account = account
    }

    func data(for object: S3Object) -> Data? {
        guard let eTag = object.eTag?.trimmingCharacters(in: CharacterSet(["\""])) else {
            return nil
        }

        let url = diskCacheURL.appending(path: "\(eTag).s3obj")
        let data = try? Data(contentsOf: url)

        return data
    }

    func setData(_ data: Data, forObject object: S3Object) {
        guard let eTag = object.eTag?.trimmingCharacters(in: CharacterSet(["\""])) else {
            return
        }

        let url = diskCacheURL.appending(path: "\(eTag).s3obj")
        try? data.write(to: url, options: .atomic)
    }
}
