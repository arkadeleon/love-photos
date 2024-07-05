//
//  AssetList.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/11/7.
//

import CoreData
import Foundation

struct AssetList {
    struct Item {
        var type: AssetType
        var mediaType: AssetMediaType?
        var parentIdentifier: String
        var identifier: String
        var cacheIdentifier: String?
        var name: String?
        var size: Int64?
        var modificationDate: Date?
    }

    var items: [Item]
}

extension Asset {
    convenience init(context: NSManagedObjectContext, item: AssetList.Item) {
        self.init(context: context)

        self.rawType = item.type.rawValue
        self.rawMediaType = item.mediaType?.rawValue
        self.parentIdentifier = item.parentIdentifier
        self.identifier = item.identifier
        self.cacheIdentifier = item.cacheIdentifier
        self.name = item.name
        self.size = item.size ?? 0
        self.modificationDate = item.modificationDate
    }
}
