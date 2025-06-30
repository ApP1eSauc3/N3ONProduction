// swiftlint:disable all
import Amplify
import Foundation

public struct ChatRoom: Model {
  public let id: String
  public var name: String
  public var createdAt: Temporal.DateTime
  public var updatedAt: Temporal.DateTime
  public var participants: List<UserChatRooms>?
  public var messages: List<Message>?
  public var lastMessage: String?
  public var lastMessageTimestamp: Temporal.DateTime?
  public var associatedEvent: String?
  
  public init(id: String = UUID().uuidString,
      name: String,
      createdAt: Temporal.DateTime,
      updatedAt: Temporal.DateTime,
      participants: List<UserChatRooms>? = [],
      messages: List<Message>? = [],
      lastMessage: String? = nil,
      lastMessageTimestamp: Temporal.DateTime? = nil,
      associatedEvent: String? = nil) {
      self.id = id
      self.name = name
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.participants = participants
      self.messages = messages
      self.lastMessage = lastMessage
      self.lastMessageTimestamp = lastMessageTimestamp
      self.associatedEvent = associatedEvent
  }
}