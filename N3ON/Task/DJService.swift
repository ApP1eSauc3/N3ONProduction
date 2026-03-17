//
//  DJService.swift
//  N3ON
//
//  Created by liam howe on 11/7/2025.
//

import Foundation
import Amplify

struct DJService {
    static func fetchFollowedDJs(userID: String) async throws -> [DJ] {
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

        let request = GraphQLRequest<DJResponse>(
            document: query,
            variables: ["userID": userID],
            responseType: DJResponse.self
        )

        let result = try await Amplify.API.query(request: request)
        switch result {
        case .success(let response):
            return response.getFollowedDJs?.items ?? []
        case .failure(let error):
            throw error
        }
    }
}

private struct DJResponse: Decodable {
    let getFollowedDJs: Payload?
    struct Payload: Decodable {
        let items: [DJ]
    }
}
