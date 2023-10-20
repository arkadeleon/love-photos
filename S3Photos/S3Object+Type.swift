//
//  S3Object+Type.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/16.
//

import Foundation

enum S3ObjectType {
    case folder
    case photo
    case video
    case other
}

extension S3Object {
    var type: S3ObjectType {
        if key!.hasSuffix("/") {
            return .folder
        }

        let ext = (key! as NSString).pathExtension.lowercased()
        switch ext {
        case "heic", 
             "jpg":
            return .photo
        case "mov", 
             "mp4":
            return .video
        default:
            return .other
        }
    }
}
