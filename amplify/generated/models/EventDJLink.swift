// swiftlint:disable all
import Amplify
import Foundation

public struct EventDJLink: Model {
  public let id: String
  public var event: Event?
  public var djID: String
  public var rankAtJoining: Int
  public var coinContribution: Int
  public var createdAt: Temporal.DateTime
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      event: Event? = nil,
      djID: String,
      rankAtJoining: Int,
      coinContribution: Int,
      createdAt: Temporal.DateTime) {
    self.init(id: id,
      event: event,
      djID: djID,
      rankAtJoining: rankAtJoining,
      coinContribution: coinContribution,
      createdAt: createdAt,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      event: Event? = nil,
      djID: String,
      rankAtJoining: Int,
      coinContribution: Int,
      createdAt: Temporal.DateTime,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.event = event
      self.djID = djID
      self.rankAtJoining = rankAtJoining
      self.coinContribution = coinContribution
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}