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
    case participantIDs
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let chatRoom = ChatRoom.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete]),
      rule(allow: .owner, ownerField: "participantIDs", identityClaim: "cognito:username", provider: .userPools, operations: [.read, .update]),
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["AdminUser"], provider: .userPools, operations: [.read])
    ]
    
    model.listPluralName = "ChatRooms"
    model.syncPluralName = "ChatRooms"
    
    model.attributes(
      .index(fields: ["associatedEvent"], name: "byEvent"),
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
      .field(chatRoom.associatedEvent, is: .optional, ofType: .string),
      .field(chatRoom.participantIDs, is: .optional, ofType: .embeddedCollection(of: String.self))
    )
    }
}

extension ChatRoom: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}