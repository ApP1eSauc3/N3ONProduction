// swiftlint:disable all
import Amplify
import Foundation

extension ChatRoom {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case createdAt
    case updatedAt
    case participants
    case messages
    case lastMessage
    case lastMessageTimestamp
    case associatedEvent
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let chatRoom = ChatRoom.keys
    
    model.authRules = [
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["VenueOwnerUser", "DJUser", "UserGroup"], provider: .userPools, operations: [.read]),
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete])
    ]
    
    model.listPluralName = "ChatRooms"
    model.syncPluralName = "ChatRooms"
    
    model.attributes(
      .primaryKey(fields: [chatRoom.id])
    )
    
    model.fields(
      .field(chatRoom.id, is: .required, ofType: .string),
      .field(chatRoom.name, is: .required, ofType: .string),
      .field(chatRoom.createdAt, is: .required, ofType: .dateTime),
      .field(chatRoom.updatedAt, is: .required, ofType: .dateTime),
      .hasMany(chatRoom.participants, is: .optional, ofType: UserChatRooms.self, associatedWith: UserChatRooms.keys.chatRoom),
      .hasMany(chatRoom.messages, is: .optional, ofType: Message.self, associatedWith: Message.keys.chatRoomID),
      .field(chatRoom.lastMessage, is: .optional, ofType: .string),
      .field(chatRoom.lastMessageTimestamp, is: .optional, ofType: .dateTime),
      .field(chatRoom.associatedEvent, is: .optional, ofType: .string)
    )
    }
}

extension ChatRoom: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}