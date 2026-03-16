// swiftlint:disable all
import Amplify
import Foundation

public struct VenueComplianceSubmission: Model {
  public let id: String
  public var venueID: String
  public var licenseType: String
  public var contractorName: String
  public var submittedAt: Temporal.DateTime
  public var status: String
  public var reviewNote: String?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      venueID: String,
      licenseType: String,
      contractorName: String,
      submittedAt: Temporal.DateTime,
      status: String,
      reviewNote: String? = nil) {
    self.init(id: id,
      venueID: venueID,
      licenseType: licenseType,
      contractorName: contractorName,
      submittedAt: submittedAt,
      status: status,
      reviewNote: reviewNote,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      venueID: String,
      licenseType: String,
      contractorName: String,
      submittedAt: Temporal.DateTime,
      status: String,
      reviewNote: String? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.venueID = venueID
      self.licenseType = licenseType
      self.contractorName = contractorName
      self.submittedAt = submittedAt
      self.status = status
      self.reviewNote = reviewNote
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}