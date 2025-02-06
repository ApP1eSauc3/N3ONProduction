// swiftlint:disable all
import Amplify
import Foundation

extension DailyUserCount {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case venue
    case date
    case userCount
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let dailyUserCount = DailyUserCount.keys
    
    model.authRules = [
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["venueOwnerGroup"], provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "DailyUserCounts"
    model.syncPluralName = "DailyUserCounts"
    
    model.attributes(
      .index(fields: ["venueID", "date"], name: "byVenue"),
      .primaryKey(fields: [dailyUserCount.id])
    )
    
    model.fields(
      .field(dailyUserCount.id, is: .required, ofType: .string),
      .belongsTo(dailyUserCount.venue, is: .optional, ofType: Venue.self, targetNames: ["venueID"]),
      .field(dailyUserCount.date, is: .required, ofType: .date),
      .field(dailyUserCount.userCount, is: .optional, ofType: .int),
      .field(dailyUserCount.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(dailyUserCount.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension DailyUserCount: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}