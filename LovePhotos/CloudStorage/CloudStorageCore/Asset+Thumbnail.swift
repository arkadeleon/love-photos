//
//  Asset+Thumbnail.swift
//  LovePhotos
//
//  Created by Leon Li on 2024/7/9.
//

import UIKit

let AssetThumbnailPixelSize = 256

extension Asset {
    var thumbnail: UIImage? {
        get {
            thumbnailData.flatMap(UIImage.init)
        }
        set {
            thumbnailData = newValue?.jpegData(compressionQuality: 0.85)
        }
    }
}
