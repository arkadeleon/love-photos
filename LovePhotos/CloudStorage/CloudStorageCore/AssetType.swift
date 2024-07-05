//
//  AssetType.swift
//  LovePhotos
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
        AssetType(rawValue: rawType ?? "")
    }

    var mediaType: AssetMediaType? {
        AssetMediaType(rawValue: rawMediaType ?? "")
    }
}
