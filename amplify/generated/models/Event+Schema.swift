// swiftlint:disable all
import Amplify
import Foundation

extension Event {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case venueID
    case hostDJID
    case djUsernames
    case vjUsername
    case package
    case requestNote
    case eventDate
    case posterKey
    case eventName
    case description
    case attendances
    case attendees
    case ticketPrice
    case availableTickets
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let event = Event.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Events"
    model.syncPluralName = "Events"
    
    model.attributes(
      .primaryKey(fields: [event.id])
    )
    
    model.fields(
      .field(event.id, is: .required, ofType: .string),
      .field(event.venueID, is: .required, ofType: .string),
      .field(event.hostDJID, is: .required, ofType: .string),
      .field(event.djUsernames, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(event.vjUsername, is: .optional, ofType: .string),
      .field(event.package, is: .required, ofType: .string),
      .field(event.requestNote, is: .optional, ofType: .string),
      .field(event.eventDate, is: .required, ofType: .dateTime),
      .field(event.posterKey, is: .optional, ofType: .string),
      .field(event.eventName, is: .required, ofType: .string),
      .field(event.description, is: .required, ofType: .string),
      .hasMany(event.attendances, is: .optional, ofType: Attendance.self, associatedWith: Attendance.keys.event),
      .field(event.attendees, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(event.ticketPrice, is: .required, ofType: .double),
      .field(event.availableTickets, is: .required, ofType: .int),
      .field(event.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(event.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Event: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}