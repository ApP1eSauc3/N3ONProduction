// swiftlint:disable all
import Amplify
import Foundation

extension EndorsementRequest {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case fromUser
    case toUser
    case message
    case status
    case timestamp
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let endorsementRequest = EndorsementRequest.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .read, .update, .delete]),
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["DJUser"], provider: .userPools, operations: [.read])
    ]
    
    model.listPluralName = "EndorsementRequests"
    model.syncPluralName = "EndorsementRequests"
    
    model.attributes(
      .index(fields: ["fromUserID", "timestamp"], name: "byFromUser"),
      .index(fields: ["toUserID", "timestamp"], name: "byToUser"),
      .primaryKey(fields: [endorsementRequest.id])
    )
    
    model.fields(
      .field(endorsementRequest.id, is: .required, ofType: .string),
      .belongsTo(endorsementRequest.fromUser, is: .optional, ofType: User.self, targetNames: ["fromUserID"]),
      .belongsTo(endorsementRequest.toUser, is: .optional, ofType: User.self, targetNames: ["toUserID"]),
      .field(endorsementRequest.message, is: .required, ofType: .string),
      .field(endorsementRequest.status, is: .required, ofType: .string),
      .field(endorsementRequest.timestamp, is: .required, ofType: .dateTime),
      .field(endorsementRequest.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(endorsementRequest.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension EndorsementRequest: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}