// swiftlint:disable all
import Amplify
import Foundation

extension Attendance {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case userID
    case attendedAt
    case event
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let attendance = Attendance.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Attendances"
    model.syncPluralName = "Attendances"
    
    model.attributes(
      .index(fields: ["userID"], name: "byUser"),
      .index(fields: ["eventID"], name: "byEvent"),
      .primaryKey(fields: [attendance.id])
    )
    
    model.fields(
      .field(attendance.id, is: .required, ofType: .string),
      .field(attendance.userID, is: .required, ofType: .string),
      .field(attendance.attendedAt, is: .required, ofType: .dateTime),
      .belongsTo(attendance.event, is: .optional, ofType: Event.self, targetNames: ["eventID"]),
      .field(attendance.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(attendance.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Attendance: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}