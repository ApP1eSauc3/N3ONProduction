// swiftlint:disable all
import Amplify
import Foundation

public struct DailyUserCount: Model {
  public let id: String
  public var venue: Venue?
  public var date: Temporal.Date
  public var userCount: Int?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      venue: Venue? = nil,
      date: Temporal.Date,
      userCount: Int? = nil) {
    self.init(id: id,
      venue: venue,
      date: date,
      userCount: userCount,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      venue: Venue? = nil,
      date: Temporal.Date,
      userCount: Int? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.venue = venue
      self.date = date
      self.userCount = userCount
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}