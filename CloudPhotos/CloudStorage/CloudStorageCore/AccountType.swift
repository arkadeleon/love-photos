//
//  AccountType.swift
//  CloudPhotos
//
//  Created by Leon Li on 2023/11/2.
//

enum AccountType: String {
    case s3
}

extension Account {
    var type: AccountType? {
        AccountType(rawValue: rawType ?? "")
    }
}
