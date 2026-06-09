// swiftlint:disable all
import Amplify
import Foundation

public struct User: Model {
  public let id: String
  public var username: String
  public var avatarKey: String?
  public var profileAudioKey: String?
  public var beatBPM: Int?
  public var isDJ: Bool
  public var djRank: Int?
  public var isCurated: Bool
  public var messages: List<Message>?
  public var chatRoom: List<UserChatRooms>?
  public var venues: List<Venue>?
  public var review: List<Review>?
  public var sentEndorsements: List<EndorsementRequest>?
  public var receivedEndorsements: List<EndorsementRequest>?
  public var currentLatitude: Double?
  public var currentLongitude: Double?
  public var isSharingLocation: Bool
  public var sharingForEvent: String?
  public var coinBalance: Int
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      username: String,
      avatarKey: String? = nil,
      profileAudioKey: String? = nil,
      beatBPM: Int? = nil,
      isDJ: Bool,
      djRank: Int? = nil,
      isCurated: Bool,
      messages: List<Message>? = [],
      chatRoom: List<UserChatRooms>? = [],
      venues: List<Venue>? = [],
      review: List<Review>? = [],
      sentEndorsements: List<EndorsementRequest>? = [],
      receivedEndorsements: List<EndorsementRequest>? = [],
      currentLatitude: Double? = nil,
      currentLongitude: Double? = nil,
      isSharingLocation: Bool,
      sharingForEvent: String? = nil,
      coinBalance: Int) {
    self.init(id: id,
      username: username,
      avatarKey: avatarKey,
      profileAudioKey: profileAudioKey,
      beatBPM: beatBPM,
      isDJ: isDJ,
      djRank: djRank,
      isCurated: isCurated,
      messages: messages,
      chatRoom: chatRoom,
      venues: venues,
      review: review,
      sentEndorsements: sentEndorsements,
      receivedEndorsements: receivedEndorsements,
      currentLatitude: currentLatitude,
      currentLongitude: currentLongitude,
      isSharingLocation: isSharingLocation,
      sharingForEvent: sharingForEvent,
      coinBalance: coinBalance,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      username: String,
      avatarKey: String? = nil,
      profileAudioKey: String? = nil,
      beatBPM: Int? = nil,
      isDJ: Bool,
      djRank: Int? = nil,
      isCurated: Bool,
      messages: List<Message>? = [],
      chatRoom: List<UserChatRooms>? = [],
      venues: List<Venue>? = [],
      review: List<Review>? = [],
      sentEndorsements: List<EndorsementRequest>? = [],
      receivedEndorsements: List<EndorsementRequest>? = [],
      currentLatitude: Double? = nil,
      currentLongitude: Double? = nil,
      isSharingLocation: Bool,
      sharingForEvent: String? = nil,
      coinBalance: Int,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.username = username
      self.avatarKey = avatarKey
      self.profileAudioKey = profileAudioKey
      self.beatBPM = beatBPM
      self.isDJ = isDJ
      self.djRank = djRank
      self.isCurated = isCurated
      self.messages = messages
      self.chatRoom = chatRoom
      self.venues = venues
      self.review = review
      self.sentEndorsements = sentEndorsements
      self.receivedEndorsements = receivedEndorsements
      self.currentLatitude = currentLatitude
      self.currentLongitude = currentLongitude
      self.isSharingLocation = isSharingLocation
      self.sharingForEvent = sharingForEvent
      self.coinBalance = coinBalance
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}