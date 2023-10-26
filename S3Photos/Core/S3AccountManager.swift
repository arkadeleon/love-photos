//
//  S3AccountManager.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/18.
//

import CoreData

class S3AccountManager {

    static let shared = S3AccountManager()

    var activeAccount: S3Account? {
        let fetchRequest = NSFetchRequest<S3Account>(entityName: "S3Account")
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        let activeAccount = try? PersistenceController.shared.context.fetch(fetchRequest).first
        return activeAccount
    }
}
