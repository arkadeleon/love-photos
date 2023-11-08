//
//  AssetList+S3Object.swift
//  CloudPhotos
//
//  Created by Leon Li on 2023/11/1.
//

import Foundation
import SotoS3

extension AssetList {
    init(objects: [S3.Object], prefix: String) {
        let items = objects.map({ Item(object: $0, prefix: prefix) })
        self.init(items: items)
    }
}

extension AssetList.Item {
    init(object: S3.Object, prefix: String) {
        let type: AssetType
        let mediaType: AssetMediaType?
        if object.key?.hasSuffix("/") == true {
            type = .folder
            mediaType = nil
        } else {
            type = .file

            let pathExtension = (object.key as NSString?)?.pathExtension.lowercased()
            switch pathExtension {
            case "heic",
                 "jpg",
                 "png":
                mediaType = .image
            case "avi",
                 "mov",
                 "mp4":
                mediaType = .video
            default:
                mediaType = .unknown
            }
        }

        self.init(
            type: type,
            mediaType: mediaType,
            parentIdentifier: prefix,
            identifier: object.key ?? "",
            cacheIdentifier: object.eTag?.trimmingCharacters(in: CharacterSet(["\""])),
            name: object.key?.split(separator: "/").last.map(String.init),
            size: object.size,
            modificationDate: object.lastModified
        )
    }
}
