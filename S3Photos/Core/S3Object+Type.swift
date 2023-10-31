//
//  S3Object+Type.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/16.
//

import CoreData
import Foundation
import SotoS3

enum S3ObjectType: String {
    case folder = "0.folder"
    case file = "1.file"
}

enum S3ObjectFileMediaType: String {
    case image
    case video
    case unknown
}

extension S3Object {
    var name: String? {
        key?.split(separator: "/").last.map(String.init)
    }

    var type: S3ObjectType? {
        switch rawType {
        case S3ObjectType.folder.rawValue: .folder
        case S3ObjectType.file.rawValue: .file
        default: nil
        }
    }

    var fileMediaType: S3ObjectFileMediaType? {
        switch rawFileMediaType {
        case S3ObjectFileMediaType.image.rawValue: .image
        case S3ObjectFileMediaType.video.rawValue: .video
        case S3ObjectFileMediaType.unknown.rawValue: .unknown
        default: nil
        }
    }

    convenience init(context: NSManagedObjectContext, object: S3.Object, prefix: String) {
        self.init(context: context)

        self.prefix = prefix

        self.eTag = object.eTag
        self.key = object.key
        self.lastModified = object.lastModified
        self.size = object.size ?? 0

        if object.key?.hasSuffix("/") == true {
            self.rawType = S3ObjectType.folder.rawValue

            self.rawFileMediaType = nil
        } else {
            self.rawType = S3ObjectType.file.rawValue

            let pathExtension = (key as NSString?)?.pathExtension.lowercased()
            switch pathExtension {
            case "heic",
                 "jpg",
                 "png":
                self.rawFileMediaType = S3ObjectFileMediaType.image.rawValue
            case "avi",
                 "mov",
                 "mp4":
                self.rawFileMediaType = S3ObjectFileMediaType.video.rawValue
            default:
                self.rawFileMediaType = S3ObjectFileMediaType.unknown.rawValue
            }
        }
    }
}
