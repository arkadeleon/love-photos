//
//  S3AssetService.swift
//  LovePhotos
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

    deinit {
        do {
            try s3.client.syncShutdown()
        } catch {
        }
    }

    func assetListStream(for prefix: String) -> AsyncStream<AssetList> {
        AsyncStream { continuation in
            Task {
                var startAfter: String? = nil

                repeat {
                    let request = S3.ListObjectsV2Request(bucket: bucket, prefix: prefix, startAfter: startAfter)
                    let response = try await s3.listObjectsV2(request)

                    guard let contents = response.contents else {
                        break
                    }

                    var objects: [S3.Object] = []

                    for content in contents {
                        guard let key = content.key, key != prefix else {
                            continue
                        }

                        print(key)
                        objects.append(content)
                    }

                    startAfter = objects.last?.key

                    let assetList = AssetList(objects: objects, prefix: prefix)
                    continuation.yield(assetList)

                } while startAfter != nil

                continuation.finish()
            }
        }
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
