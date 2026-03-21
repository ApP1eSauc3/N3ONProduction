// swiftlint:disable all
import Amplify
import Foundation

public struct UserFollows: Model {
  public let id: String
  public var followerID: String
  public var followeeID: String
  public var createdAt: Temporal.DateTime
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      followerID: String,
      followeeID: String,
      createdAt: Temporal.DateTime) {
    self.init(id: id,
      followerID: followerID,
      followeeID: followeeID,
      createdAt: createdAt,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      followerID: String,
      followeeID: String,
      createdAt: Temporal.DateTime,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.followerID = followerID
      self.followeeID = followeeID
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}