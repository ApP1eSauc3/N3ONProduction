// swiftlint:disable all
import Amplify
import Foundation

extension Ticket {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case eventID
    case userID
    case quantity
    case purchaseTime
    case pricePaid
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let ticket = Ticket.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["VenueOwnerUser"], provider: .userPools, operations: [.read])
    ]
    
    model.listPluralName = "Tickets"
    model.syncPluralName = "Tickets"
    
    model.attributes(
      .index(fields: ["eventID", "purchaseTime"], name: "byEvent"),
      .index(fields: ["userID", "purchaseTime"], name: "byUser"),
      .primaryKey(fields: [ticket.id])
    )
    
    model.fields(
      .field(ticket.id, is: .required, ofType: .string),
      .field(ticket.eventID, is: .required, ofType: .string),
      .field(ticket.userID, is: .required, ofType: .string),
      .field(ticket.quantity, is: .required, ofType: .int),
      .field(ticket.purchaseTime, is: .required, ofType: .dateTime),
      .field(ticket.pricePaid, is: .optional, ofType: .double),
      .field(ticket.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(ticket.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Ticket: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}