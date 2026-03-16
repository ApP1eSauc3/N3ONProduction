// swiftlint:disable all
import Amplify
import Foundation

extension Transaction {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case fromUserID
    case toUserID
    case amount
    case eventID
    case type
    case note
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let transaction = Transaction.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.read]),
      rule(allow: .private, provider: .iam, operations: [.create, .read])
    ]
    
    model.listPluralName = "Transactions"
    model.syncPluralName = "Transactions"
    
    model.attributes(
      .index(fields: ["fromUserID", "createdAt"], name: "byFromUser"),
      .index(fields: ["toUserID", "createdAt"], name: "byToUser"),
      .index(fields: ["eventID", "createdAt"], name: "byEvent"),
      .primaryKey(fields: [transaction.id])
    )
    
    model.fields(
      .field(transaction.id, is: .required, ofType: .string),
      .field(transaction.fromUserID, is: .required, ofType: .string),
      .field(transaction.toUserID, is: .required, ofType: .string),
      .field(transaction.amount, is: .required, ofType: .int),
      .field(transaction.eventID, is: .optional, ofType: .string),
      .field(transaction.type, is: .required, ofType: .string),
      .field(transaction.note, is: .optional, ofType: .string),
      .field(transaction.createdAt, is: .required, ofType: .dateTime),
      .field(transaction.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
}

extension Transaction: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}