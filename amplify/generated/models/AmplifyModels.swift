// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "d7352d4f603ab90727697f6da4ed8c81"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: User.self)
    ModelRegistry.register(modelType: Venue.self)
    ModelRegistry.register(modelType: DailyUserCount.self)
    ModelRegistry.register(modelType: Review.self)
    ModelRegistry.register(modelType: ChatRoom.self)
    ModelRegistry.register(modelType: Message.self)
    ModelRegistry.register(modelType: Post.self)
    ModelRegistry.register(modelType: Event.self)
    ModelRegistry.register(modelType: Ticket.self)
    ModelRegistry.register(modelType: EndorsementRequest.self)
    ModelRegistry.register(modelType: Attendance.self)
    ModelRegistry.register(modelType: EventDJLink.self)
    ModelRegistry.register(modelType: UserFollows.self)
    ModelRegistry.register(modelType: Transaction.self)
    ModelRegistry.register(modelType: VenueComplianceSubmission.self)
    ModelRegistry.register(modelType: UserChatRooms.self)
  }
}