//
//  S3AssetService.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/19.
//

import Foundation
import SotoS3

class S3AssetService: AssetService {

    let account: Account

    private let s3: S3

    init(account: Account) {
        self.account = account

        let client = AWSClient(
            credentialProvider: .static(accessKeyId: account.accessKeyId!, secretAccessKey: account.secretAccessKey!),
            httpClientProvider: .createNew
        )
        s3 = S3(client: client, endpoint: account.endpoint!)
    }

    func listAssets(parentIdentifier: String) async throws -> [S3.Object] {
        let request = S3.ListObjectsV2Request(bucket: account.bucket!, delimiter: "/", prefix: parentIdentifier)
        let response = try await s3.listObjectsV2(request)

        var objects = [S3.Object]()

        if let commonPrefixes = response.commonPrefixes {
            for commonPrefix in commonPrefixes {
                let object = S3.Object(key: commonPrefix.prefix)
                objects.append(object)
            }
        }

        if let contents = response.contents {
            for content in contents where content.key != parentIdentifier {
                objects.append(content)
            }
        }

        return objects
    }

    func urlForAsset(identifier: String) async throws -> URL {
        let url = URL(string: account.endpoint!)!.appending(path: account.bucket!).appending(path: identifier)
        let signedURL = try await s3.signURL(url: url, httpMethod: .GET, expires: .hours(1))
        return signedURL
    }

    func dataForAsset(identifier: String) async throws -> Data {
        let request = S3.GetObjectRequest(bucket: account.bucket!, key: identifier)
        let response = try await s3.getObject(request)

        let data = response.body?.asData() ?? Data()
        return data
    }
}
