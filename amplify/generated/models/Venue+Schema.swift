// swiftlint:disable all
import Amplify
import Foundation

extension Venue {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case name
    case description
    case address
    case latitude
    case longitude
    case rating
    case imageKey
    case owner
    case maxCapacity
    case currentUsers
    case revenue
    case dailyUserCounts
    case reviews
    case approvalStatus
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let venue = Venue.keys
    
    model.authRules = [
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["VenueOwnerUser"], provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Venues"
    model.syncPluralName = "Venues"
    
    model.attributes(
      .primaryKey(fields: [venue.id])
    )
    
    model.fields(
      .field(venue.id, is: .required, ofType: .string),
      .field(venue.name, is: .required, ofType: .string),
      .field(venue.description, is: .required, ofType: .string),
      .field(venue.address, is: .required, ofType: .string),
      .field(venue.latitude, is: .required, ofType: .double),
      .field(venue.longitude, is: .required, ofType: .double),
      .field(venue.rating, is: .optional, ofType: .double),
      .field(venue.imageKey, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .belongsTo(venue.owner, is: .optional, ofType: User.self, targetNames: ["ownerID"]),
      .field(venue.maxCapacity, is: .optional, ofType: .int),
      .field(venue.currentUsers, is: .optional, ofType: .int),
      .field(venue.revenue, is: .optional, ofType: .double),
      .hasMany(venue.dailyUserCounts, is: .optional, ofType: DailyUserCount.self, associatedWith: DailyUserCount.keys.venue),
      .hasMany(venue.reviews, is: .optional, ofType: Review.self, associatedWith: Review.keys.venue),
      .field(venue.approvalStatus, is: .required, ofType: .string),
      .field(venue.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(venue.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Venue: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}