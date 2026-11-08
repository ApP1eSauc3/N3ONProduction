// swiftlint:disable all
import Amplify
import Foundation

extension TicketAllowance {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case eventID
    case userID
    case issued
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let ticketAllowance = TicketAllowance.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "userID", identityClaim: "cognito:username", provider: .userPools, operations: [.read]),
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["AdminUser"], provider: .userPools, operations: [.read])
    ]
    
    model.listPluralName = "TicketAllowances"
    model.syncPluralName = "TicketAllowances"
    
    model.attributes(
      .index(fields: ["userID"], name: "byUser"),
      .primaryKey(fields: [ticketAllowance.id])
    )
    
    model.fields(
      .field(ticketAllowance.id, is: .required, ofType: .string),
      .field(ticketAllowance.eventID, is: .required, ofType: .string),
      .field(ticketAllowance.userID, is: .required, ofType: .string),
      .field(ticketAllowance.issued, is: .required, ofType: .int),
      .field(ticketAllowance.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(ticketAllowance.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension TicketAllowance: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}