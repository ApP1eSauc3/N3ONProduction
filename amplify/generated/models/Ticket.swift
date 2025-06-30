// swiftlint:disable all
import Amplify
import Foundation

public struct Ticket: Model {
  public let id: String
  public var eventID: String
  public var userID: String
  public var quantity: Int
  public var purchaseTime: Temporal.DateTime
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      eventID: String,
      userID: String,
      quantity: Int,
      purchaseTime: Temporal.DateTime) {
    self.init(id: id,
      eventID: eventID,
      userID: userID,
      quantity: quantity,
      purchaseTime: purchaseTime,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      eventID: String,
      userID: String,
      quantity: Int,
      purchaseTime: Temporal.DateTime,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.eventID = eventID
      self.userID = userID
      self.quantity = quantity
      self.purchaseTime = purchaseTime
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}