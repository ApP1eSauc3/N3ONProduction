// swiftlint:disable all
import Amplify
import Foundation

public struct TicketAllowance: Model {
  public let id: String
  public var eventID: String
  public var userID: String
  public var issued: Int
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      eventID: String,
      userID: String,
      issued: Int) {
    self.init(id: id,
      eventID: eventID,
      userID: userID,
      issued: issued,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      eventID: String,
      userID: String,
      issued: Int,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.eventID = eventID
      self.userID = userID
      self.issued = issued
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}