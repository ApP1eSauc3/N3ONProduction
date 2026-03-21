// swiftlint:disable all
import Amplify
import Foundation

extension UserFollows {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case followerID
    case followeeID
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let userFollows = UserFollows.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .delete, .read]),
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["DJUser", "UserGroup", "VenueOwnerUser"], provider: .userPools, operations: [.read])
    ]
    
    model.listPluralName = "UserFollows"
    model.syncPluralName = "UserFollows"
    
    model.attributes(
      .index(fields: ["followerID", "createdAt"], name: "byFollower"),
      .index(fields: ["followeeID", "createdAt"], name: "byFollowee"),
      .primaryKey(fields: [userFollows.id])
    )
    
    model.fields(
      .field(userFollows.id, is: .required, ofType: .string),
      .field(userFollows.followerID, is: .required, ofType: .string),
      .field(userFollows.followeeID, is: .required, ofType: .string),
      .field(userFollows.createdAt, is: .required, ofType: .dateTime),
      .field(userFollows.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension UserFollows: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}