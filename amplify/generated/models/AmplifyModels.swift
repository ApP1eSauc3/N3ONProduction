// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "824f7507d5d7a675d498273c90ed848f"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: User.self)
    ModelRegistry.register(modelType: Venue.self)
    ModelRegistry.register(modelType: DailyUserCount.self)
    ModelRegistry.register(modelType: Review.self)
    ModelRegistry.register(modelType: ChatRoom.self)
    ModelRegistry.register(modelType: Message.self)
    ModelRegistry.register(modelType: UserChatRooms.self)
  }
}