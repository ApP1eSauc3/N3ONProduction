// swiftlint:disable all
import Amplify
import Foundation

public struct Message: Model {
  public let id: String
  public var sender: User?
  public var chatRoomID: String
  public var content: String
  public var timestamp: Temporal.DateTime
  public var isRead: Bool
  public var readBy: [String?]?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      sender: User? = nil,
      chatRoomID: String,
      content: String,
      timestamp: Temporal.DateTime,
      isRead: Bool,
      readBy: [String?]? = nil) {
    self.init(id: id,
      sender: sender,
      chatRoomID: chatRoomID,
      content: content,
      timestamp: timestamp,
      isRead: isRead,
      readBy: readBy,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      sender: User? = nil,
      chatRoomID: String,
      content: String,
      timestamp: Temporal.DateTime,
      isRead: Bool,
      readBy: [String?]? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.sender = sender
      self.chatRoomID = chatRoomID
      self.content = content
      self.timestamp = timestamp
      self.isRead = isRead
      self.readBy = readBy
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}