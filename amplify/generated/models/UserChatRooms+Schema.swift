// swiftlint:disable all
import Amplify
import Foundation

extension UserChatRooms {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case user
    case chatRoom
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let userChatRooms = UserChatRooms.keys
    
    model.authRules = [
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["venueOwnerGroup", "djGroup", "userGroup"], provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["Users"], provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "UserChatRooms"
    model.syncPluralName = "UserChatRooms"
    
    model.attributes(
      .index(fields: ["userId"], name: "byUser"),
      .index(fields: ["chatRoomId"], name: "byChatRoom"),
      .primaryKey(fields: [userChatRooms.id])
    )
    
    model.fields(
      .field(userChatRooms.id, is: .required, ofType: .string),
      .belongsTo(userChatRooms.user, is: .required, ofType: User.self, targetNames: ["userId"]),
      .belongsTo(userChatRooms.chatRoom, is: .required, ofType: ChatRoom.self, targetNames: ["chatRoomId"]),
      .field(userChatRooms.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(userChatRooms.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension UserChatRooms: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}