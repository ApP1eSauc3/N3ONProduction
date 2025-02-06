// swiftlint:disable all
import Amplify
import Foundation

public struct Venue: Model {
  public let id: String
  public var name: String
  public var description: String
  public var address: String
  public var latitude: Double
  public var longitude: Double
  public var rating: Double?
  public var imageKey: [String]?
  public var owner: User?
  public var maxCapacity: Int?
  public var currentUsers: Int?
  public var revenue: Double?
  public var dailyUserCounts: List<DailyUserCount>?
  public var reviews: List<Review>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      name: String,
      description: String,
      address: String,
      latitude: Double,
      longitude: Double,
      rating: Double? = nil,
      imageKey: [String]? = nil,
      owner: User? = nil,
      maxCapacity: Int? = nil,
      currentUsers: Int? = nil,
      revenue: Double? = nil,
      dailyUserCounts: List<DailyUserCount>? = [],
      reviews: List<Review>? = []) {
    self.init(id: id,
      name: name,
      description: description,
      address: address,
      latitude: latitude,
      longitude: longitude,
      rating: rating,
      imageKey: imageKey,
      owner: owner,
      maxCapacity: maxCapacity,
      currentUsers: currentUsers,
      revenue: revenue,
      dailyUserCounts: dailyUserCounts,
      reviews: reviews,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      name: String,
      description: String,
      address: String,
      latitude: Double,
      longitude: Double,
      rating: Double? = nil,
      imageKey: [String]? = nil,
      owner: User? = nil,
      maxCapacity: Int? = nil,
      currentUsers: Int? = nil,
      revenue: Double? = nil,
      dailyUserCounts: List<DailyUserCount>? = [],
      reviews: List<Review>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.name = name
      self.description = description
      self.address = address
      self.latitude = latitude
      self.longitude = longitude
      self.rating = rating
      self.imageKey = imageKey
      self.owner = owner
      self.maxCapacity = maxCapacity
      self.currentUsers = currentUsers
      self.revenue = revenue
      self.dailyUserCounts = dailyUserCounts
      self.reviews = reviews
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}