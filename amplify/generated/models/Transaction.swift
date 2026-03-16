// swiftlint:disable all
import Amplify
import Foundation

public struct Transaction: Model {
  public let id: String
  public var fromUserID: String
  public var toUserID: String
  public var amount: Int
  public var eventID: String?
  public var type: String
  public var note: String?
  public var createdAt: Temporal.DateTime
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      fromUserID: String,
      toUserID: String,
      amount: Int,
      eventID: String? = nil,
      type: String,
      note: String? = nil,
      createdAt: Temporal.DateTime) {
    self.init(id: id,
      fromUserID: fromUserID,
      toUserID: toUserID,
      amount: amount,
      eventID: eventID,
      type: type,
      note: note,
      createdAt: createdAt,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      fromUserID: String,
      toUserID: String,
      amount: Int,
      eventID: String? = nil,
      type: String,
      note: String? = nil,
      createdAt: Temporal.DateTime,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.fromUserID = fromUserID
      self.toUserID = toUserID
      self.amount = amount
      self.eventID = eventID
      self.type = type
      self.note = note
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}