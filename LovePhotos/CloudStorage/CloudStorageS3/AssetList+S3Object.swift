//
//  AssetList+S3Object.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/11/1.
//

import Foundation
import SotoS3

extension AssetList {
    init(objects: [S3.Object], prefix: String) {
        let items = objects.compactMap(AssetList.Item.init)
        self.init(items: items)
    }
}

extension AssetList.Item {
    init?(object: S3.Object) {
        guard let key = object.key else {
            return nil
        }

        let type: AssetType
        let mediaType: AssetMediaType?
        if key.hasSuffix("/") {
            type = .folder
            mediaType = nil
        } else {
            type = .file

            let pathExtension = (key as NSString).pathExtension.lowercased()
            switch pathExtension {
            case "heic", "jpg", "png":
                mediaType = .image
            case "avi", "mov", "mp4":
                mediaType = .video
            default:
                mediaType = .unknown
            }
        }

        let parentKey = (key as NSString).deletingLastPathComponent.appending("/")
        let name = (key as NSString).lastPathComponent

        self.init(
            type: type,
            mediaType: mediaType,
            parentIdentifier: parentKey,
            identifier: key,
            cacheIdentifier: object.eTag?.trimmingCharacters(in: CharacterSet(["\""])),
            name: name,
            size: object.size,
            modificationDate: object.lastModified
        )
    }
}
