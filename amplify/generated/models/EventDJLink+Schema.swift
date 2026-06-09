// swiftlint:disable all
import Amplify
import Foundation

extension EventDJLink {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case event
    case djID
    case rankAtJoining
    case coinContribution
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let eventDJLink = EventDJLink.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .read, .delete]),
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["DJUser", "VenueOwnerUser", "UserGroup"], provider: .userPools, operations: [.read]),
      rule(allow: .private, provider: .iam, operations: [.create, .read, .update, .delete]),
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["AdminUser"], provider: .userPools, operations: [.create, .read, .update, .delete])
    ]
    
    model.listPluralName = "EventDJLinks"
    model.syncPluralName = "EventDJLinks"
    
    model.attributes(
      .index(fields: ["eventID", "createdAt"], name: "byEvent"),
      .index(fields: ["djID", "createdAt"], name: "byDJ"),
      .primaryKey(fields: [eventDJLink.id])
    )
    
    model.fields(
      .field(eventDJLink.id, is: .required, ofType: .string),
      .belongsTo(eventDJLink.event, is: .optional, ofType: Event.self, targetNames: ["eventID"]),
      .field(eventDJLink.djID, is: .required, ofType: .string),
      .field(eventDJLink.rankAtJoining, is: .required, ofType: .int),
      .field(eventDJLink.coinContribution, is: .required, ofType: .int),
      .field(eventDJLink.createdAt, is: .required, ofType: .dateTime),
      .field(eventDJLink.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension EventDJLink: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}