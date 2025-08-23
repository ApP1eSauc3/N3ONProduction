// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "0347220de3d9cdd5df5c235c8bb22c51"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: User.self)
    ModelRegistry.register(modelType: Venue.self)
    ModelRegistry.register(modelType: DailyUserCount.self)
    ModelRegistry.register(modelType: Review.self)
    ModelRegistry.register(modelType: ChatRoom.self)
    ModelRegistry.register(modelType: Message.self)
    ModelRegistry.register(modelType: Post.self)
    ModelRegistry.register(modelType: Ticket.self)
    ModelRegistry.register(modelType: Event.self)
    ModelRegistry.register(modelType: EndorsementRequest.self)
    ModelRegistry.register(modelType: Attendance.self)
    ModelRegistry.register(modelType: UserChatRooms.self)
  }
}