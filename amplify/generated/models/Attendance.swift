// swiftlint:disable all
import Amplify
import Foundation

public struct Attendance: Model {
  public let id: String
  public var userID: String
  public var attendedAt: Temporal.DateTime
  public var event: Event?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      userID: String,
      attendedAt: Temporal.DateTime,
      event: Event? = nil) {
    self.init(id: id,
      userID: userID,
      attendedAt: attendedAt,
      event: event,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      userID: String,
      attendedAt: Temporal.DateTime,
      event: Event? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.userID = userID
      self.attendedAt = attendedAt
      self.event = event
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}