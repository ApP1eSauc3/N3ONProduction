// swiftlint:disable all
import Amplify
import Foundation

public struct Event: Model {
  public let id: String
  public var venueID: String
  public var hostDJID: String
  public var djLinks: List<EventDJLink>?
  public var vjUsername: String?
  public var package: String
  public var requestNote: String?
  public var eventDate: Temporal.DateTime
  public var posterKey: String?
  public var eventName: String
  public var description: String
  public var ticketPrice: Double
  public var availableTickets: Int
  public var status: String
  public var isFeatured: Bool
  public var attendances: List<Attendance>?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      venueID: String,
      hostDJID: String,
      djLinks: List<EventDJLink>? = [],
      vjUsername: String? = nil,
      package: String,
      requestNote: String? = nil,
      eventDate: Temporal.DateTime,
      posterKey: String? = nil,
      eventName: String,
      description: String,
      ticketPrice: Double,
      availableTickets: Int,
      status: String,
      isFeatured: Bool,
      attendances: List<Attendance>? = []) {
    self.init(id: id,
      venueID: venueID,
      hostDJID: hostDJID,
      djLinks: djLinks,
      vjUsername: vjUsername,
      package: package,
      requestNote: requestNote,
      eventDate: eventDate,
      posterKey: posterKey,
      eventName: eventName,
      description: description,
      ticketPrice: ticketPrice,
      availableTickets: availableTickets,
      status: status,
      isFeatured: isFeatured,
      attendances: attendances,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      venueID: String,
      hostDJID: String,
      djLinks: List<EventDJLink>? = [],
      vjUsername: String? = nil,
      package: String,
      requestNote: String? = nil,
      eventDate: Temporal.DateTime,
      posterKey: String? = nil,
      eventName: String,
      description: String,
      ticketPrice: Double,
      availableTickets: Int,
      status: String,
      isFeatured: Bool,
      attendances: List<Attendance>? = [],
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.venueID = venueID
      self.hostDJID = hostDJID
      self.djLinks = djLinks
      self.vjUsername = vjUsername
      self.package = package
      self.requestNote = requestNote
      self.eventDate = eventDate
      self.posterKey = posterKey
      self.eventName = eventName
      self.description = description
      self.ticketPrice = ticketPrice
      self.availableTickets = availableTickets
      self.status = status
      self.isFeatured = isFeatured
      self.attendances = attendances
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}