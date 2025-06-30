// swiftlint:disable all
import Amplify
import Foundation

public struct Event: Model {
  public let id: String
  public var venueID: String
  public var hostDJID: String
  public var djUsernames: [String]
  public var vjUsername: String?
  public var package: String
  public var requestNote: String?
  public var eventDate: Temporal.DateTime
  public var posterKey: String?
  public var eventName: String
  public var description: String
  public var attendances: List<Attendance>?
  public var attendees: [String?]
  public var ticketPrice: Double
  public var availableTickets: Int
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      venueID: String,
      hostDJID: String,
      djUsernames: [String] = [],
      vjUsername: String? = nil,
      package: String,
      requestNote: String? = nil,
      eventDate: Temporal.DateTime,
      posterKey: String? = nil,
      eventName: String,
      description: String,
      attendances: List<Attendance>? = [],
      attendees: [String?] = [],
      ticketPrice: Double,
      availableTickets: Int) {
    self.init(id: id,
      venueID: venueID,
      hostDJID: hostDJID,
      djUsernames: djUsernames,
      vjUsername: vjUsername,
      package: package,
      requestNote: requestNote,
      eventDate: eventDate,
      posterKey: posterKey,
      eventName: eventName,
      description: description,
      attendances: attendances,
      attendees: attendees,
      ticketPrice: ticketPrice,
      availableTickets: availableTickets,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      venueID: String,
      hostDJID: String,
      djUsernames: [String] = [],
      vjUsername: String? = nil,
      package: String,
      requestNote: String? = nil,
      eventDate: Temporal.DateTime,
      posterKey: String? = nil,
      eventName: String,
      description: String,
      attendances: List<Attendance>? = [],
      attendees: [String?] = [],
      ticketPrice: Double,
      availableTickets: Int,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.venueID = venueID
      self.hostDJID = hostDJID
      self.djUsernames = djUsernames
      self.vjUsername = vjUsername
      self.package = package
      self.requestNote = requestNote
      self.eventDate = eventDate
      self.posterKey = posterKey
      self.eventName = eventName
      self.description = description
      self.attendances = attendances
      self.attendees = attendees
      self.ticketPrice = ticketPrice
      self.availableTickets = availableTickets
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}