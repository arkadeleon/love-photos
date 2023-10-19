//
//  S3ObjectLibrary.swift
//  S3Photos
//
//  Created by Leon Li on 2023/9/26.
//

import SotoS3

class S3ObjectLibrary {
    static let shared = S3ObjectLibrary()

    private let accessKeyId = "M88Y71VA5JGKJ3XGQ2K1"
    private let secretAccessKey = "b6cLf72tiwxXvLeP7icW2UQmmWTY8BpEXl2pFYUA"
    private let endpoint = "https://sgp1.vultrobjects.com"
    private let bucket = "arkadeleon"

    private let s3: S3

    init() {
        let client = AWSClient(
            credentialProvider: .static(accessKeyId: accessKeyId, secretAccessKey: secretAccessKey),
            httpClientProvider: .createNew
        )
        s3 = S3(client: client, endpoint: endpoint)
    }

    func fetchObjects(prefix: String = "") async throws {
        let input = S3.ListObjectsV2Request(bucket: bucket, delimiter: "/", prefix: prefix)
        let output = try await s3.listObjectsV2(input)

        guard let contents = output.contents else {
            return
        }

        for object in contents {
            let o = S3Object(context: PersistenceController.shared.container.viewContext)
            o.key = object.key
            o.prefix = prefix
        }

        PersistenceController.shared.saveContext()
    }
}
