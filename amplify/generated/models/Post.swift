// swiftlint:disable all
import Amplify
import Foundation

public struct Post: Model {
  public let id: String
  public var urls: [String]
  public var types: [String]
  public var timestamp: Temporal.DateTime
  public var caption: String?
  public var ownerID: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      urls: [String] = [],
      types: [String] = [],
      timestamp: Temporal.DateTime,
      caption: String? = nil,
      ownerID: String? = nil) {
    self.init(id: id,
      urls: urls,
      types: types,
      timestamp: timestamp,
      caption: caption,
      ownerID: ownerID,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      urls: [String] = [],
      types: [String] = [],
      timestamp: Temporal.DateTime,
      caption: String? = nil,
      ownerID: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.urls = urls
      self.types = types
      self.timestamp = timestamp
      self.caption = caption
      self.ownerID = ownerID
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}