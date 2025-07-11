//
//  DJService.swift
//  N3ON
//
//  Created by liam howe on 11/7/2025.
//

import Foundation

struct DJService {
    static func fetchFollowedDJs(userID: String) -> AnyPublisher<[DJ], Error> {
        Future { promise in
            let query = """
            query GetFollowedDJs($userID: ID!) {
              getFollowedDJs(userID: $userID) {
                items {
                  id name genre profileImageKey
                  currentLocation { latitude longitude }
                }
              }
            }
            """
            
            Amplify.API.query(
                request: .init(
                    document: query,
                    variables: ["userID": userID],
                    responseType: DJResponse.self
                )
            ) { result in
                switch result {
                case .success(let response):
                    promise(.success(response.djs))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

private struct DJResponse: Decodable {
    let djs: [DJ]
}
