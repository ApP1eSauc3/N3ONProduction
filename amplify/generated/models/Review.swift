// swiftlint:disable all
import Amplify
import Foundation

public struct Review: Model {
  public let id: String
  public var venue: Venue?
  public var user: User?
  public var rating: Double
  public var comment: String
  public var createdAt: Temporal.DateTime
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      venue: Venue? = nil,
      user: User? = nil,
      rating: Double,
      comment: String,
      createdAt: Temporal.DateTime) {
    self.init(id: id,
      venue: venue,
      user: user,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      venue: Venue? = nil,
      user: User? = nil,
      rating: Double,
      comment: String,
      createdAt: Temporal.DateTime,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.venue = venue
      self.user = user
      self.rating = rating
      self.comment = comment
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}