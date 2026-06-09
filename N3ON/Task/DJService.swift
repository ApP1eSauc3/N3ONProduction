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
            // The GraphQL response has no isFollowedByCurrentUser field.
            // Every DJ returned by this query is followed by definition, so set
            // it true here — otherwise DJPinView would render every followed DJ
            // with the unfollowed styling.
            return (response.getFollowedDJs?.items ?? []).map {
                var dj = $0
                dj.isFollowedByCurrentUser = true
                return dj
            }
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
