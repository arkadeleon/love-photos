//
//  Asset+Type.swift
//  CloudPhotos
//
//  Created by Leon Li on 2023/10/16.
//

enum AssetType: String {
    case folder = "0.folder"
    case file = "1.file"
}

enum AssetMediaType: String {
    case image
    case video
    case unknown
}

extension Asset {

    var type: AssetType? {
        switch rawType {
        case AssetType.folder.rawValue: .folder
        case AssetType.file.rawValue: .file
        default: nil
        }
    }

    var mediaType: AssetMediaType? {
        switch rawMediaType {
        case AssetMediaType.image.rawValue: .image
        case AssetMediaType.video.rawValue: .video
        case AssetMediaType.unknown.rawValue: .unknown
        default: nil
        }
    }
}
