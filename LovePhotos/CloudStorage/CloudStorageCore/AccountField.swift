//
//  AccountField.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/11/2.
//

protocol AccountField {
    associatedtype AllFields: Collection = [Self]

    static var allFields: AllFields { get }

    var title: String { get }
    var isSecure: Bool { get }
}

extension Account {
    func setValue(_ field: String?, forFieldAt index: Int) {
        switch index {
        case 0:
            field1 = field
        case 1:
            field2 = field
        case 2:
            field3 = field
        case 3:
            field4 = field
        default:
            break
        }
    }

    func value(forFieldAt index: Int) -> String? {
        switch index {
        case 0: field1
        case 1: field2
        case 2: field3
        case 3: field4
        default: nil
        }
    }
}
