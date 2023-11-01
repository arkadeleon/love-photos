//
//  Asset+S3Object.swift
//  CloudPhotos
//
//  Created by Leon Li on 2023/11/1.
//

import CoreData
import SotoS3

extension Asset {
    convenience init(context: NSManagedObjectContext, object: S3.Object, prefix: String) {
        self.init(context: context)

        self.parentIdentifier = prefix
        self.identifier = object.key
        self.name = object.key?.split(separator: "/").last.map(String.init)
        self.eTag = object.eTag
        self.modificationDate = object.lastModified
        self.size = object.size ?? 0

        if object.key?.hasSuffix("/") == true {
            self.rawType = AssetType.folder.rawValue

            self.rawMediaType = nil
        } else {
            self.rawType = AssetType.file.rawValue

            let pathExtension = (identifier as NSString?)?.pathExtension.lowercased()
            switch pathExtension {
            case "heic",
                 "jpg",
                 "png":
                self.rawMediaType = AssetMediaType.image.rawValue
            case "avi",
                 "mov",
                 "mp4":
                self.rawMediaType = AssetMediaType.video.rawValue
            default:
                self.rawMediaType = AssetMediaType.unknown.rawValue
            }
        }
    }
}
