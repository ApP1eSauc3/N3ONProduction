// swiftlint:disable all
import Amplify
import Foundation

public struct EndorsementRequest: Model {
  public let id: String
  public var fromUser: User?
  public var toUser: User?
  public var message: String
  public var status: String
  public var timestamp: Temporal.DateTime
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      fromUser: User? = nil,
      toUser: User? = nil,
      message: String,
      status: String,
      timestamp: Temporal.DateTime) {
    self.init(id: id,
      fromUser: fromUser,
      toUser: toUser,
      message: message,
      status: status,
      timestamp: timestamp,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      fromUser: User? = nil,
      toUser: User? = nil,
      message: String,
      status: String,
      timestamp: Temporal.DateTime,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.fromUser = fromUser
      self.toUser = toUser
      self.message = message
      self.status = status
      self.timestamp = timestamp
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}