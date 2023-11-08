//
//  S3AssetService.swift
//  CloudPhotos
//
//  Created by Leon Li on 2023/10/19.
//

import Foundation
import SotoS3

class S3AssetService: AssetService {

    let account: Account

    let accessKeyId: String
    let secretAccessKey: String
    let endpoint: String
    let bucket: String

    private let s3: S3

    init(account: Account) {
        self.account = account

        accessKeyId = account.field1 ?? ""
        secretAccessKey = account.field2 ?? ""
        endpoint = account.field3 ?? ""
        bucket = account.field4 ?? ""

        let client = AWSClient(
            credentialProvider: .static(accessKeyId: accessKeyId, secretAccessKey: secretAccessKey),
            httpClientProvider: .createNew
        )
        s3 = S3(client: client, endpoint: endpoint)
    }

    func assetList(for parentIdentifier: String) async throws -> AssetList {
        let prefix = parentIdentifier
        let request = S3.ListObjectsV2Request(bucket: bucket, delimiter: "/", prefix: prefix)
        let response = try await s3.listObjectsV2(request)

        var objects = [S3.Object]()

        if let commonPrefixes = response.commonPrefixes {
            for commonPrefix in commonPrefixes {
                let object = S3.Object(key: commonPrefix.prefix)
                objects.append(object)
            }
        }

        if let contents = response.contents {
            for content in contents where content.key != prefix {
                objects.append(content)
            }
        }

        return AssetList(objects: objects, prefix: prefix)
    }

    func urlForAsset(identifier: String) async throws -> URL {
        let url = URL(string: endpoint)!.appending(path: bucket).appending(path: identifier)
        let signedURL = try await s3.signURL(url: url, httpMethod: .GET, expires: .hours(1))
        return signedURL
    }

    func dataForAsset(identifier: String) async throws -> Data {
        let request = S3.GetObjectRequest(bucket: bucket, key: identifier)
        let response = try await s3.getObject(request)

        let data = response.body?.asData() ?? Data()
        return data
    }
}
