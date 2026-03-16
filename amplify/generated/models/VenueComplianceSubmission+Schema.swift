// swiftlint:disable all
import Amplify
import Foundation

extension VenueComplianceSubmission {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case venueID
    case licenseType
    case contractorName
    case submittedAt
    case status
    case reviewNote
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let venueComplianceSubmission = VenueComplianceSubmission.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .read]),
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["VenueOwnerUser"], provider: .userPools, operations: [.read, .update])
    ]
    
    model.listPluralName = "VenueComplianceSubmissions"
    model.syncPluralName = "VenueComplianceSubmissions"
    
    model.attributes(
      .index(fields: ["venueID", "submittedAt"], name: "byVenue"),
      .primaryKey(fields: [venueComplianceSubmission.id])
    )
    
    model.fields(
      .field(venueComplianceSubmission.id, is: .required, ofType: .string),
      .field(venueComplianceSubmission.venueID, is: .required, ofType: .string),
      .field(venueComplianceSubmission.licenseType, is: .required, ofType: .string),
      .field(venueComplianceSubmission.contractorName, is: .required, ofType: .string),
      .field(venueComplianceSubmission.submittedAt, is: .required, ofType: .dateTime),
      .field(venueComplianceSubmission.status, is: .required, ofType: .string),
      .field(venueComplianceSubmission.reviewNote, is: .optional, ofType: .string),
      .field(venueComplianceSubmission.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(venueComplianceSubmission.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension VenueComplianceSubmission: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}