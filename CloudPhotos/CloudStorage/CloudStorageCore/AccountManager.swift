//
//  AccountManager.swift
//  CloudPhotos
//
//  Created by Leon Li on 2023/10/18.
//

import CoreData

class AccountManager {

    static let shared = AccountManager()

    var activeAccount: Account? {
        let fetchRequest = Account.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isActive == YES")
        let activeAccount = try? PersistenceController.shared.context.fetch(fetchRequest).first
        return activeAccount
    }
}
