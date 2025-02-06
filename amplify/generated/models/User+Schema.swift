// swiftlint:disable all
import Amplify
import Foundation

extension User {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case username
    case messages
    case chatRoom
    case venues
    case review
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let user = User.keys
    
    model.authRules = [
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["venueOwnerGroup", "djGroup", "userGroup"], provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Users"
    model.syncPluralName = "Users"
    
    model.attributes(
      .primaryKey(fields: [user.id])
    )
    
    model.fields(
      .field(user.id, is: .required, ofType: .string),
      .field(user.username, is: .required, ofType: .string),
      .hasMany(user.messages, is: .optional, ofType: Message.self, associatedWith: Message.keys.sender),
      .hasMany(user.chatRoom, is: .optional, ofType: UserChatRooms.self, associatedWith: UserChatRooms.keys.user),
      .hasMany(user.venues, is: .optional, ofType: Venue.self, associatedWith: Venue.keys.owner),
      .hasMany(user.review, is: .optional, ofType: Review.self, associatedWith: Review.keys.user),
      .field(user.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(user.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension User: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}