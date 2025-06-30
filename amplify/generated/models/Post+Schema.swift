// swiftlint:disable all
import Amplify
import Foundation

extension Post {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case urls
    case types
    case timestamp
    case caption
    case ownerID
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let post = Post.keys
    
    model.authRules = [
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["djGroup", "userGroup", "venueOwnerGroup"], provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Posts"
    model.syncPluralName = "Posts"
    
    model.attributes(
      .primaryKey(fields: [post.id])
    )
    
    model.fields(
      .field(post.id, is: .required, ofType: .string),
      .field(post.urls, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(post.types, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(post.timestamp, is: .required, ofType: .dateTime),
      .field(post.caption, is: .optional, ofType: .string),
      .field(post.ownerID, is: .optional, ofType: .string),
      .field(post.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(post.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Post: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}