// swiftlint:disable all
import Amplify
import Foundation

extension Message {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case sender
    case chatRoomID
    case content
    case timestamp
    case isRead
    case readBy
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let message = Message.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete]),
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["Users"], provider: .userPools, operations: [.read])
    ]
    
    model.listPluralName = "Messages"
    model.syncPluralName = "Messages"
    
    model.attributes(
      .index(fields: ["chatRoomID", "timestamp"], name: "byChatRoom"),
      .primaryKey(fields: [message.id])
    )
    
    model.fields(
      .field(message.id, is: .required, ofType: .string),
      .belongsTo(message.sender, is: .optional, ofType: User.self, targetNames: ["senderID"]),
      .field(message.chatRoomID, is: .required, ofType: .string),
      .field(message.content, is: .required, ofType: .string),
      .field(message.timestamp, is: .required, ofType: .dateTime),
      .field(message.isRead, is: .required, ofType: .bool),
      .field(message.readBy, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(message.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(message.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Message: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}