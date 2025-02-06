// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "ca6089ee8600cb2af2e2c04b2d41d307"
  
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