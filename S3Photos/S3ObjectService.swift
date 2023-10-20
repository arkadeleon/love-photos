//
//  S3ObjectService.swift
//  S3Photos
//
//  Created by Leon Li on 2023/10/19.
//

import Foundation
import SotoS3

class S3ObjectService {

    let account: S3Account

    private let s3: S3

    init(account: S3Account) {
        self.account = account

        let client = AWSClient(
            credentialProvider: .static(accessKeyId: account.accessKeyId!, secretAccessKey: account.secretAccessKey!),
            httpClientProvider: .createNew
        )
        s3 = S3(client: client, endpoint: account.endpoint!)
    }

    func listObjects(prefix: String, maxKeys: Int?) async throws -> [S3.Object] {
        let request = S3.ListObjectsV2Request(bucket: account.bucket!, delimiter: "/", maxKeys: maxKeys, prefix: prefix)
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

        return objects
    }

    func signObject(key: String) async throws -> URL {
        let url = URL(string: account.endpoint!)!.appending(path: account.bucket!).appending(path: key)
        let signedURL = try await s3.signURL(url: url, httpMethod: .GET, expires: .hours(1))
        return signedURL
    }

    func getObject(key: String) async throws -> Data {
        let request = S3.GetObjectRequest(bucket: account.bucket!, key: key)
        let response = try await s3.getObject(request)

        let data = response.body?.asData() ?? Data()
        return data
    }
}
