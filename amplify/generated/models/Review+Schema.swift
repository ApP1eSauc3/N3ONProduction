// swiftlint:disable all
import Amplify
import Foundation

extension Review {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case venue
    case user
    case rating
    case comment
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let review = Review.keys
    
    model.authRules = [
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["UserGroup"], provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Reviews"
    model.syncPluralName = "Reviews"
    
    model.attributes(
      .index(fields: ["venueID", "createdAt"], name: "byVenue"),
      .index(fields: ["userID", "createdAt"], name: "byUser"),
      .primaryKey(fields: [review.id])
    )
    
    model.fields(
      .field(review.id, is: .required, ofType: .string),
      .belongsTo(review.venue, is: .optional, ofType: Venue.self, targetNames: ["venueID"]),
      .belongsTo(review.user, is: .optional, ofType: User.self, targetNames: ["userID"]),
      .field(review.rating, is: .required, ofType: .double),
      .field(review.comment, is: .required, ofType: .string),
      .field(review.createdAt, is: .required, ofType: .dateTime),
      .field(review.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Review: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}