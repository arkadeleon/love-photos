//
//  S3AccountField.swift
//  LovePhotos
//
//  Created by Leon Li on 2023/11/2.
//

enum S3AccountField: AccountField {
    case accessKeyID
    case secretAccessKey
    case endpoint
    case bucket
    case prefix

    static let allFields: [S3AccountField] = [
        .accessKeyID,
        .secretAccessKey,
        .endpoint,
        .bucket,
        .prefix,
    ]

    var title: String {
        switch self {
        case .accessKeyID: "Access Key ID"
        case .secretAccessKey: "Secret Access Key"
        case .endpoint: "Endpoint"
        case .bucket: "Bucket"
        case .prefix: "Prefix"
        }
    }

    var isSecure: Bool {
        switch self {
        case .accessKeyID: false
        case .secretAccessKey: true
        case .endpoint: false
        case .bucket: false
        case .prefix: false
        }
    }
}
