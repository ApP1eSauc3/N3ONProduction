// swiftlint:disable all
import Amplify
import Foundation

extension User {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case username
    case avatarKey
    case profileAudioKey
    case beatBPM
    case isDJ
    case messages
    case chatRoom
    case venues
    case review
    case sentEndorsements
    case receivedEndorsements
    case currentLatitude
    case currentLongitude
    case isSharingLocation
    case sharingForEvent
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let user = User.keys
    
    model.authRules = [
      rule(allow: .groups, groupClaim: "cognito:groups", groups: ["VenueOwnerUser", "DJUser", "UserGroup"], provider: .userPools, operations: [.create, .update, .delete, .read])
    ]
    
    model.listPluralName = "Users"
    model.syncPluralName = "Users"
    
    model.attributes(
      .primaryKey(fields: [user.id])
    )
    
    model.fields(
      .field(user.id, is: .required, ofType: .string),
      .field(user.username, is: .required, ofType: .string),
      .field(user.avatarKey, is: .optional, ofType: .string),
      .field(user.profileAudioKey, is: .optional, ofType: .string),
      .field(user.beatBPM, is: .optional, ofType: .int),
      .field(user.isDJ, is: .required, ofType: .bool),
      .hasMany(user.messages, is: .optional, ofType: Message.self, associatedWith: Message.keys.sender),
      .hasMany(user.chatRoom, is: .optional, ofType: UserChatRooms.self, associatedWith: UserChatRooms.keys.user),
      .hasMany(user.venues, is: .optional, ofType: Venue.self, associatedWith: Venue.keys.owner),
      .hasMany(user.review, is: .optional, ofType: Review.self, associatedWith: Review.keys.user),
      .hasMany(user.sentEndorsements, is: .optional, ofType: EndorsementRequest.self, associatedWith: EndorsementRequest.keys.fromUser),
      .hasMany(user.receivedEndorsements, is: .optional, ofType: EndorsementRequest.self, associatedWith: EndorsementRequest.keys.toUser),
      .field(user.currentLatitude, is: .optional, ofType: .double),
      .field(user.currentLongitude, is: .optional, ofType: .double),
      .field(user.isSharingLocation, is: .required, ofType: .bool),
      .field(user.sharingForEvent, is: .optional, ofType: .string),
      .field(user.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(user.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension User: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}