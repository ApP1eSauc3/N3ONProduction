//  This file was automatically generated and should not be edited.

#if canImport(AWSAPIPlugin)
import Foundation

public protocol GraphQLInputValue {
}

public struct GraphQLVariable {
  let name: String
  
  public init(_ name: String) {
    self.name = name
  }
}

extension GraphQLVariable: GraphQLInputValue {
}

extension JSONEncodable {
  public func evaluate(with variables: [String: JSONEncodable]?) throws -> Any {
    return jsonValue
  }
}

public typealias GraphQLMap = [String: JSONEncodable?]

extension Dictionary where Key == String, Value == JSONEncodable? {
  public var withNilValuesRemoved: Dictionary<String, JSONEncodable> {
    var filtered = Dictionary<String, JSONEncodable>(minimumCapacity: count)
    for (key, value) in self {
      if value != nil {
        filtered[key] = value
      }
    }
    return filtered
  }
}

public protocol GraphQLMapConvertible: JSONEncodable {
  var graphQLMap: GraphQLMap { get }
}

public extension GraphQLMapConvertible {
  var jsonValue: Any {
    return graphQLMap.withNilValuesRemoved.jsonValue
  }
}

public typealias GraphQLID = String

public protocol APISwiftGraphQLOperation: AnyObject {
  
  static var operationString: String { get }
  static var requestString: String { get }
  static var operationIdentifier: String? { get }
  
  var variables: GraphQLMap? { get }
  
  associatedtype Data: GraphQLSelectionSet
}

public extension APISwiftGraphQLOperation {
  static var requestString: String {
    return operationString
  }

  static var operationIdentifier: String? {
    return nil
  }

  var variables: GraphQLMap? {
    return nil
  }
}

public protocol GraphQLQuery: APISwiftGraphQLOperation {}

public protocol GraphQLMutation: APISwiftGraphQLOperation {}

public protocol GraphQLSubscription: APISwiftGraphQLOperation {}

public protocol GraphQLFragment: GraphQLSelectionSet {
  static var possibleTypes: [String] { get }
}

public typealias Snapshot = [String: Any?]

public protocol GraphQLSelectionSet: Decodable {
  static var selections: [GraphQLSelection] { get }
  
  var snapshot: Snapshot { get }
  init(snapshot: Snapshot)
}

extension GraphQLSelectionSet {
    public init(from decoder: Decoder) throws {
        if let jsonObject = try? APISwiftJSONValue(from: decoder) {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(jsonObject)
            let decodedDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
            let optionalDictionary = decodedDictionary.mapValues { $0 as Any? }

            self.init(snapshot: optionalDictionary)
        } else {
            self.init(snapshot: [:])
        }
    }
}

enum APISwiftJSONValue: Codable {
    case array([APISwiftJSONValue])
    case boolean(Bool)
    case number(Double)
    case object([String: APISwiftJSONValue])
    case string(String)
    case null
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode([String: APISwiftJSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([APISwiftJSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            self = .null
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .array(let value):
            try container.encode(value)
        case .boolean(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

public protocol GraphQLSelection {
}

public struct GraphQLField: GraphQLSelection {
  let name: String
  let alias: String?
  let arguments: [String: GraphQLInputValue]?
  
  var responseKey: String {
    return alias ?? name
  }
  
  let type: GraphQLOutputType
  
  public init(_ name: String, alias: String? = nil, arguments: [String: GraphQLInputValue]? = nil, type: GraphQLOutputType) {
    self.name = name
    self.alias = alias
    
    self.arguments = arguments
    
    self.type = type
  }
}

public indirect enum GraphQLOutputType {
  case scalar(JSONDecodable.Type)
  case object([GraphQLSelection])
  case nonNull(GraphQLOutputType)
  case list(GraphQLOutputType)
  
  var namedType: GraphQLOutputType {
    switch self {
    case .nonNull(let innerType), .list(let innerType):
      return innerType.namedType
    case .scalar, .object:
      return self
    }
  }
}

public struct GraphQLBooleanCondition: GraphQLSelection {
  let variableName: String
  let inverted: Bool
  let selections: [GraphQLSelection]
  
  public init(variableName: String, inverted: Bool, selections: [GraphQLSelection]) {
    self.variableName = variableName
    self.inverted = inverted;
    self.selections = selections;
  }
}

public struct GraphQLTypeCondition: GraphQLSelection {
  let possibleTypes: [String]
  let selections: [GraphQLSelection]
  
  public init(possibleTypes: [String], selections: [GraphQLSelection]) {
    self.possibleTypes = possibleTypes
    self.selections = selections;
  }
}

public struct GraphQLFragmentSpread: GraphQLSelection {
  let fragment: GraphQLFragment.Type
  
  public init(_ fragment: GraphQLFragment.Type) {
    self.fragment = fragment
  }
}

public struct GraphQLTypeCase: GraphQLSelection {
  let variants: [String: [GraphQLSelection]]
  let `default`: [GraphQLSelection]
  
  public init(variants: [String: [GraphQLSelection]], default: [GraphQLSelection]) {
    self.variants = variants
    self.default = `default`;
  }
}

public typealias JSONObject = [String: Any]

public protocol JSONDecodable {
  init(jsonValue value: Any) throws
}

public protocol JSONEncodable: GraphQLInputValue {
  var jsonValue: Any { get }
}

public enum JSONDecodingError: Error, LocalizedError {
  case missingValue
  case nullValue
  case wrongType
  case couldNotConvert(value: Any, to: Any.Type)
  
  public var errorDescription: String? {
    switch self {
    case .missingValue:
      return "Missing value"
    case .nullValue:
      return "Unexpected null value"
    case .wrongType:
      return "Wrong type"
    case .couldNotConvert(let value, let expectedType):
      return "Could not convert \"\(value)\" to \(expectedType)"
    }
  }
}

extension String: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let string = value as? String else {
      throw JSONDecodingError.couldNotConvert(value: value, to: String.self)
    }
    self = string
  }

  public var jsonValue: Any {
    return self
  }
}

extension Int: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let number = value as? NSNumber else {
      throw JSONDecodingError.couldNotConvert(value: value, to: Int.self)
    }
    self = number.intValue
  }

  public var jsonValue: Any {
    return self
  }
}

extension Float: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let number = value as? NSNumber else {
      throw JSONDecodingError.couldNotConvert(value: value, to: Float.self)
    }
    self = number.floatValue
  }

  public var jsonValue: Any {
    return self
  }
}

extension Double: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let number = value as? NSNumber else {
      throw JSONDecodingError.couldNotConvert(value: value, to: Double.self)
    }
    self = number.doubleValue
  }

  public var jsonValue: Any {
    return self
  }
}

extension Bool: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let bool = value as? Bool else {
        throw JSONDecodingError.couldNotConvert(value: value, to: Bool.self)
    }
    self = bool
  }

  public var jsonValue: Any {
    return self
  }
}

extension RawRepresentable where RawValue: JSONDecodable {
  public init(jsonValue value: Any) throws {
    let rawValue = try RawValue(jsonValue: value)
    if let tempSelf = Self(rawValue: rawValue) {
      self = tempSelf
    } else {
      throw JSONDecodingError.couldNotConvert(value: value, to: Self.self)
    }
  }
}

extension RawRepresentable where RawValue: JSONEncodable {
  public var jsonValue: Any {
    return rawValue.jsonValue
  }
}

extension Optional where Wrapped: JSONDecodable {
  public init(jsonValue value: Any) throws {
    if value is NSNull {
      self = .none
    } else {
      self = .some(try Wrapped(jsonValue: value))
    }
  }
}

extension Optional: JSONEncodable {
  public var jsonValue: Any {
    switch self {
    case .none:
      return NSNull()
    case .some(let wrapped as JSONEncodable):
      return wrapped.jsonValue
    default:
      fatalError("Optional is only JSONEncodable if Wrapped is")
    }
  }
}

extension Dictionary: JSONEncodable {
  public var jsonValue: Any {
    return jsonObject
  }
  
  public var jsonObject: JSONObject {
    var jsonObject = JSONObject(minimumCapacity: count)
    for (key, value) in self {
      if case let (key as String, value as JSONEncodable) = (key, value) {
        jsonObject[key] = value.jsonValue
      } else {
        fatalError("Dictionary is only JSONEncodable if Value is (and if Key is String)")
      }
    }
    return jsonObject
  }
}

extension Array: JSONEncodable {
  public var jsonValue: Any {
    return map() { element -> (Any) in
      if case let element as JSONEncodable = element {
        return element.jsonValue
      } else {
        fatalError("Array is only JSONEncodable if Element is")
      }
    }
  }
}

extension URL: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let string = value as? String else {
      throw JSONDecodingError.couldNotConvert(value: value, to: URL.self)
    }
    self.init(string: string)!
  }

  public var jsonValue: Any {
    return self.absoluteString
  }
}

extension Dictionary {
  static func += (lhs: inout Dictionary, rhs: Dictionary) {
    lhs.merge(rhs) { (_, new) in new }
  }
}

#elseif canImport(AWSAppSync)
import AWSAppSync
#endif

public struct CreateUserInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID? = nil, username: String, version: Int? = nil) {
    graphQLMap = ["id": id, "username": username, "_version": version]
  }

  public var id: GraphQLID? {
    get {
      return graphQLMap["id"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var username: String {
    get {
      return graphQLMap["username"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "username")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct ModelUserConditionInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(username: ModelStringInput? = nil, and: [ModelUserConditionInput?]? = nil, or: [ModelUserConditionInput?]? = nil, not: ModelUserConditionInput? = nil, deleted: ModelBooleanInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil) {
    graphQLMap = ["username": username, "and": and, "or": or, "not": not, "_deleted": deleted, "createdAt": createdAt, "updatedAt": updatedAt]
  }

  public var username: ModelStringInput? {
    get {
      return graphQLMap["username"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "username")
    }
  }

  public var and: [ModelUserConditionInput?]? {
    get {
      return graphQLMap["and"] as! [ModelUserConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelUserConditionInput?]? {
    get {
      return graphQLMap["or"] as! [ModelUserConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelUserConditionInput? {
    get {
      return graphQLMap["not"] as! ModelUserConditionInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }
}

public struct ModelStringInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: String? = nil, eq: String? = nil, le: String? = nil, lt: String? = nil, ge: String? = nil, gt: String? = nil, contains: String? = nil, notContains: String? = nil, between: [String?]? = nil, beginsWith: String? = nil, attributeExists: Bool? = nil, attributeType: ModelAttributeTypes? = nil, size: ModelSizeInput? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "contains": contains, "notContains": notContains, "between": between, "beginsWith": beginsWith, "attributeExists": attributeExists, "attributeType": attributeType, "size": size]
  }

  public var ne: String? {
    get {
      return graphQLMap["ne"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: String? {
    get {
      return graphQLMap["eq"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: String? {
    get {
      return graphQLMap["le"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: String? {
    get {
      return graphQLMap["lt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: String? {
    get {
      return graphQLMap["ge"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: String? {
    get {
      return graphQLMap["gt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var contains: String? {
    get {
      return graphQLMap["contains"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "contains")
    }
  }

  public var notContains: String? {
    get {
      return graphQLMap["notContains"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notContains")
    }
  }

  public var between: [String?]? {
    get {
      return graphQLMap["between"] as! [String?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var beginsWith: String? {
    get {
      return graphQLMap["beginsWith"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "beginsWith")
    }
  }

  public var attributeExists: Bool? {
    get {
      return graphQLMap["attributeExists"] as! Bool?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeExists")
    }
  }

  public var attributeType: ModelAttributeTypes? {
    get {
      return graphQLMap["attributeType"] as! ModelAttributeTypes?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeType")
    }
  }

  public var size: ModelSizeInput? {
    get {
      return graphQLMap["size"] as! ModelSizeInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "size")
    }
  }
}

public enum ModelAttributeTypes: RawRepresentable, Equatable, JSONDecodable, JSONEncodable {
  public typealias RawValue = String
  case binary
  case binarySet
  case bool
  case list
  case map
  case number
  case numberSet
  case string
  case stringSet
  case null
  /// Auto generated constant for unknown enum values
  case unknown(RawValue)

  public init?(rawValue: RawValue) {
    switch rawValue {
      case "binary": self = .binary
      case "binarySet": self = .binarySet
      case "bool": self = .bool
      case "list": self = .list
      case "map": self = .map
      case "number": self = .number
      case "numberSet": self = .numberSet
      case "string": self = .string
      case "stringSet": self = .stringSet
      case "_null": self = .null
      default: self = .unknown(rawValue)
    }
  }

  public var rawValue: RawValue {
    switch self {
      case .binary: return "binary"
      case .binarySet: return "binarySet"
      case .bool: return "bool"
      case .list: return "list"
      case .map: return "map"
      case .number: return "number"
      case .numberSet: return "numberSet"
      case .string: return "string"
      case .stringSet: return "stringSet"
      case .null: return "_null"
      case .unknown(let value): return value
    }
  }

  public static func == (lhs: ModelAttributeTypes, rhs: ModelAttributeTypes) -> Bool {
    switch (lhs, rhs) {
      case (.binary, .binary): return true
      case (.binarySet, .binarySet): return true
      case (.bool, .bool): return true
      case (.list, .list): return true
      case (.map, .map): return true
      case (.number, .number): return true
      case (.numberSet, .numberSet): return true
      case (.string, .string): return true
      case (.stringSet, .stringSet): return true
      case (.null, .null): return true
      case (.unknown(let lhsValue), .unknown(let rhsValue)): return lhsValue == rhsValue
      default: return false
    }
  }
}

public struct ModelSizeInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: Int? = nil, eq: Int? = nil, le: Int? = nil, lt: Int? = nil, ge: Int? = nil, gt: Int? = nil, between: [Int?]? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "between": between]
  }

  public var ne: Int? {
    get {
      return graphQLMap["ne"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: Int? {
    get {
      return graphQLMap["eq"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: Int? {
    get {
      return graphQLMap["le"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: Int? {
    get {
      return graphQLMap["lt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: Int? {
    get {
      return graphQLMap["ge"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: Int? {
    get {
      return graphQLMap["gt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var between: [Int?]? {
    get {
      return graphQLMap["between"] as! [Int?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }
}

public struct ModelBooleanInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: Bool? = nil, eq: Bool? = nil, attributeExists: Bool? = nil, attributeType: ModelAttributeTypes? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "attributeExists": attributeExists, "attributeType": attributeType]
  }

  public var ne: Bool? {
    get {
      return graphQLMap["ne"] as! Bool?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: Bool? {
    get {
      return graphQLMap["eq"] as! Bool?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var attributeExists: Bool? {
    get {
      return graphQLMap["attributeExists"] as! Bool?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeExists")
    }
  }

  public var attributeType: ModelAttributeTypes? {
    get {
      return graphQLMap["attributeType"] as! ModelAttributeTypes?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeType")
    }
  }
}

public struct UpdateUserInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, username: String? = nil, version: Int? = nil) {
    graphQLMap = ["id": id, "username": username, "_version": version]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var username: String? {
    get {
      return graphQLMap["username"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "username")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct DeleteUserInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, version: Int? = nil) {
    graphQLMap = ["id": id, "_version": version]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct CreateVenueInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID? = nil, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, version: Int? = nil) {
    graphQLMap = ["id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "_version": version]
  }

  public var id: GraphQLID? {
    get {
      return graphQLMap["id"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var name: String {
    get {
      return graphQLMap["name"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var description: String {
    get {
      return graphQLMap["description"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "description")
    }
  }

  public var address: String {
    get {
      return graphQLMap["address"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "address")
    }
  }

  public var latitude: Double {
    get {
      return graphQLMap["latitude"] as! Double
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "latitude")
    }
  }

  public var longitude: Double {
    get {
      return graphQLMap["longitude"] as! Double
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "longitude")
    }
  }

  public var rating: Double? {
    get {
      return graphQLMap["rating"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "rating")
    }
  }

  public var imageKey: [String]? {
    get {
      return graphQLMap["imageKey"] as! [String]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "imageKey")
    }
  }

  public var ownerId: GraphQLID {
    get {
      return graphQLMap["ownerID"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ownerID")
    }
  }

  public var maxCapacity: Int? {
    get {
      return graphQLMap["maxCapacity"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "maxCapacity")
    }
  }

  public var currentUsers: Int? {
    get {
      return graphQLMap["currentUsers"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "currentUsers")
    }
  }

  public var revenue: Double? {
    get {
      return graphQLMap["revenue"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "revenue")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct ModelVenueConditionInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(name: ModelStringInput? = nil, description: ModelStringInput? = nil, address: ModelStringInput? = nil, latitude: ModelFloatInput? = nil, longitude: ModelFloatInput? = nil, rating: ModelFloatInput? = nil, imageKey: ModelStringInput? = nil, ownerId: ModelIDInput? = nil, maxCapacity: ModelIntInput? = nil, currentUsers: ModelIntInput? = nil, revenue: ModelFloatInput? = nil, and: [ModelVenueConditionInput?]? = nil, or: [ModelVenueConditionInput?]? = nil, not: ModelVenueConditionInput? = nil, deleted: ModelBooleanInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil) {
    graphQLMap = ["name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "and": and, "or": or, "not": not, "_deleted": deleted, "createdAt": createdAt, "updatedAt": updatedAt]
  }

  public var name: ModelStringInput? {
    get {
      return graphQLMap["name"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var description: ModelStringInput? {
    get {
      return graphQLMap["description"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "description")
    }
  }

  public var address: ModelStringInput? {
    get {
      return graphQLMap["address"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "address")
    }
  }

  public var latitude: ModelFloatInput? {
    get {
      return graphQLMap["latitude"] as! ModelFloatInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "latitude")
    }
  }

  public var longitude: ModelFloatInput? {
    get {
      return graphQLMap["longitude"] as! ModelFloatInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "longitude")
    }
  }

  public var rating: ModelFloatInput? {
    get {
      return graphQLMap["rating"] as! ModelFloatInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "rating")
    }
  }

  public var imageKey: ModelStringInput? {
    get {
      return graphQLMap["imageKey"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "imageKey")
    }
  }

  public var ownerId: ModelIDInput? {
    get {
      return graphQLMap["ownerID"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ownerID")
    }
  }

  public var maxCapacity: ModelIntInput? {
    get {
      return graphQLMap["maxCapacity"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "maxCapacity")
    }
  }

  public var currentUsers: ModelIntInput? {
    get {
      return graphQLMap["currentUsers"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "currentUsers")
    }
  }

  public var revenue: ModelFloatInput? {
    get {
      return graphQLMap["revenue"] as! ModelFloatInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "revenue")
    }
  }

  public var and: [ModelVenueConditionInput?]? {
    get {
      return graphQLMap["and"] as! [ModelVenueConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelVenueConditionInput?]? {
    get {
      return graphQLMap["or"] as! [ModelVenueConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelVenueConditionInput? {
    get {
      return graphQLMap["not"] as! ModelVenueConditionInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }
}

public struct ModelFloatInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: Double? = nil, eq: Double? = nil, le: Double? = nil, lt: Double? = nil, ge: Double? = nil, gt: Double? = nil, between: [Double?]? = nil, attributeExists: Bool? = nil, attributeType: ModelAttributeTypes? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "between": between, "attributeExists": attributeExists, "attributeType": attributeType]
  }

  public var ne: Double? {
    get {
      return graphQLMap["ne"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: Double? {
    get {
      return graphQLMap["eq"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: Double? {
    get {
      return graphQLMap["le"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: Double? {
    get {
      return graphQLMap["lt"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: Double? {
    get {
      return graphQLMap["ge"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: Double? {
    get {
      return graphQLMap["gt"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var between: [Double?]? {
    get {
      return graphQLMap["between"] as! [Double?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var attributeExists: Bool? {
    get {
      return graphQLMap["attributeExists"] as! Bool?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeExists")
    }
  }

  public var attributeType: ModelAttributeTypes? {
    get {
      return graphQLMap["attributeType"] as! ModelAttributeTypes?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeType")
    }
  }
}

public struct ModelIDInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: GraphQLID? = nil, eq: GraphQLID? = nil, le: GraphQLID? = nil, lt: GraphQLID? = nil, ge: GraphQLID? = nil, gt: GraphQLID? = nil, contains: GraphQLID? = nil, notContains: GraphQLID? = nil, between: [GraphQLID?]? = nil, beginsWith: GraphQLID? = nil, attributeExists: Bool? = nil, attributeType: ModelAttributeTypes? = nil, size: ModelSizeInput? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "contains": contains, "notContains": notContains, "between": between, "beginsWith": beginsWith, "attributeExists": attributeExists, "attributeType": attributeType, "size": size]
  }

  public var ne: GraphQLID? {
    get {
      return graphQLMap["ne"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: GraphQLID? {
    get {
      return graphQLMap["eq"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: GraphQLID? {
    get {
      return graphQLMap["le"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: GraphQLID? {
    get {
      return graphQLMap["lt"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: GraphQLID? {
    get {
      return graphQLMap["ge"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: GraphQLID? {
    get {
      return graphQLMap["gt"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var contains: GraphQLID? {
    get {
      return graphQLMap["contains"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "contains")
    }
  }

  public var notContains: GraphQLID? {
    get {
      return graphQLMap["notContains"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notContains")
    }
  }

  public var between: [GraphQLID?]? {
    get {
      return graphQLMap["between"] as! [GraphQLID?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var beginsWith: GraphQLID? {
    get {
      return graphQLMap["beginsWith"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "beginsWith")
    }
  }

  public var attributeExists: Bool? {
    get {
      return graphQLMap["attributeExists"] as! Bool?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeExists")
    }
  }

  public var attributeType: ModelAttributeTypes? {
    get {
      return graphQLMap["attributeType"] as! ModelAttributeTypes?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeType")
    }
  }

  public var size: ModelSizeInput? {
    get {
      return graphQLMap["size"] as! ModelSizeInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "size")
    }
  }
}

public struct ModelIntInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: Int? = nil, eq: Int? = nil, le: Int? = nil, lt: Int? = nil, ge: Int? = nil, gt: Int? = nil, between: [Int?]? = nil, attributeExists: Bool? = nil, attributeType: ModelAttributeTypes? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "between": between, "attributeExists": attributeExists, "attributeType": attributeType]
  }

  public var ne: Int? {
    get {
      return graphQLMap["ne"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: Int? {
    get {
      return graphQLMap["eq"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: Int? {
    get {
      return graphQLMap["le"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: Int? {
    get {
      return graphQLMap["lt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: Int? {
    get {
      return graphQLMap["ge"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: Int? {
    get {
      return graphQLMap["gt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var between: [Int?]? {
    get {
      return graphQLMap["between"] as! [Int?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var attributeExists: Bool? {
    get {
      return graphQLMap["attributeExists"] as! Bool?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeExists")
    }
  }

  public var attributeType: ModelAttributeTypes? {
    get {
      return graphQLMap["attributeType"] as! ModelAttributeTypes?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeType")
    }
  }
}

public struct UpdateVenueInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, name: String? = nil, description: String? = nil, address: String? = nil, latitude: Double? = nil, longitude: Double? = nil, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID? = nil, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, version: Int? = nil) {
    graphQLMap = ["id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "_version": version]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var name: String? {
    get {
      return graphQLMap["name"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var description: String? {
    get {
      return graphQLMap["description"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "description")
    }
  }

  public var address: String? {
    get {
      return graphQLMap["address"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "address")
    }
  }

  public var latitude: Double? {
    get {
      return graphQLMap["latitude"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "latitude")
    }
  }

  public var longitude: Double? {
    get {
      return graphQLMap["longitude"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "longitude")
    }
  }

  public var rating: Double? {
    get {
      return graphQLMap["rating"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "rating")
    }
  }

  public var imageKey: [String]? {
    get {
      return graphQLMap["imageKey"] as! [String]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "imageKey")
    }
  }

  public var ownerId: GraphQLID? {
    get {
      return graphQLMap["ownerID"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ownerID")
    }
  }

  public var maxCapacity: Int? {
    get {
      return graphQLMap["maxCapacity"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "maxCapacity")
    }
  }

  public var currentUsers: Int? {
    get {
      return graphQLMap["currentUsers"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "currentUsers")
    }
  }

  public var revenue: Double? {
    get {
      return graphQLMap["revenue"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "revenue")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct DeleteVenueInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, version: Int? = nil) {
    graphQLMap = ["id": id, "_version": version]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct CreateDailyUserCountInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID? = nil, venueId: GraphQLID, date: String, userCount: Int? = nil, version: Int? = nil) {
    graphQLMap = ["id": id, "venueID": venueId, "date": date, "userCount": userCount, "_version": version]
  }

  public var id: GraphQLID? {
    get {
      return graphQLMap["id"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var venueId: GraphQLID {
    get {
      return graphQLMap["venueID"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "venueID")
    }
  }

  public var date: String {
    get {
      return graphQLMap["date"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "date")
    }
  }

  public var userCount: Int? {
    get {
      return graphQLMap["userCount"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userCount")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct ModelDailyUserCountConditionInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(venueId: ModelIDInput? = nil, date: ModelStringInput? = nil, userCount: ModelIntInput? = nil, and: [ModelDailyUserCountConditionInput?]? = nil, or: [ModelDailyUserCountConditionInput?]? = nil, not: ModelDailyUserCountConditionInput? = nil, deleted: ModelBooleanInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil) {
    graphQLMap = ["venueID": venueId, "date": date, "userCount": userCount, "and": and, "or": or, "not": not, "_deleted": deleted, "createdAt": createdAt, "updatedAt": updatedAt]
  }

  public var venueId: ModelIDInput? {
    get {
      return graphQLMap["venueID"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "venueID")
    }
  }

  public var date: ModelStringInput? {
    get {
      return graphQLMap["date"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "date")
    }
  }

  public var userCount: ModelIntInput? {
    get {
      return graphQLMap["userCount"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userCount")
    }
  }

  public var and: [ModelDailyUserCountConditionInput?]? {
    get {
      return graphQLMap["and"] as! [ModelDailyUserCountConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelDailyUserCountConditionInput?]? {
    get {
      return graphQLMap["or"] as! [ModelDailyUserCountConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelDailyUserCountConditionInput? {
    get {
      return graphQLMap["not"] as! ModelDailyUserCountConditionInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }
}

public struct UpdateDailyUserCountInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, venueId: GraphQLID? = nil, date: String? = nil, userCount: Int? = nil, version: Int? = nil) {
    graphQLMap = ["id": id, "venueID": venueId, "date": date, "userCount": userCount, "_version": version]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var venueId: GraphQLID? {
    get {
      return graphQLMap["venueID"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "venueID")
    }
  }

  public var date: String? {
    get {
      return graphQLMap["date"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "date")
    }
  }

  public var userCount: Int? {
    get {
      return graphQLMap["userCount"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userCount")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct DeleteDailyUserCountInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, version: Int? = nil) {
    graphQLMap = ["id": id, "_version": version]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct CreateReviewInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID? = nil, venueId: GraphQLID, userId: GraphQLID, rating: Double, comment: String, createdAt: String? = nil, version: Int? = nil) {
    graphQLMap = ["id": id, "venueID": venueId, "userID": userId, "rating": rating, "comment": comment, "createdAt": createdAt, "_version": version]
  }

  public var id: GraphQLID? {
    get {
      return graphQLMap["id"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var venueId: GraphQLID {
    get {
      return graphQLMap["venueID"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "venueID")
    }
  }

  public var userId: GraphQLID {
    get {
      return graphQLMap["userID"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userID")
    }
  }

  public var rating: Double {
    get {
      return graphQLMap["rating"] as! Double
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "rating")
    }
  }

  public var comment: String {
    get {
      return graphQLMap["comment"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "comment")
    }
  }

  public var createdAt: String? {
    get {
      return graphQLMap["createdAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct ModelReviewConditionInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(venueId: ModelIDInput? = nil, userId: ModelIDInput? = nil, rating: ModelFloatInput? = nil, comment: ModelStringInput? = nil, createdAt: ModelStringInput? = nil, and: [ModelReviewConditionInput?]? = nil, or: [ModelReviewConditionInput?]? = nil, not: ModelReviewConditionInput? = nil, deleted: ModelBooleanInput? = nil, updatedAt: ModelStringInput? = nil) {
    graphQLMap = ["venueID": venueId, "userID": userId, "rating": rating, "comment": comment, "createdAt": createdAt, "and": and, "or": or, "not": not, "_deleted": deleted, "updatedAt": updatedAt]
  }

  public var venueId: ModelIDInput? {
    get {
      return graphQLMap["venueID"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "venueID")
    }
  }

  public var userId: ModelIDInput? {
    get {
      return graphQLMap["userID"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userID")
    }
  }

  public var rating: ModelFloatInput? {
    get {
      return graphQLMap["rating"] as! ModelFloatInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "rating")
    }
  }

  public var comment: ModelStringInput? {
    get {
      return graphQLMap["comment"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "comment")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var and: [ModelReviewConditionInput?]? {
    get {
      return graphQLMap["and"] as! [ModelReviewConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelReviewConditionInput?]? {
    get {
      return graphQLMap["or"] as! [ModelReviewConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelReviewConditionInput? {
    get {
      return graphQLMap["not"] as! ModelReviewConditionInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }
}

public struct UpdateReviewInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, venueId: GraphQLID? = nil, userId: GraphQLID? = nil, rating: Double? = nil, comment: String? = nil, createdAt: String? = nil, version: Int? = nil) {
    graphQLMap = ["id": id, "venueID": venueId, "userID": userId, "rating": rating, "comment": comment, "createdAt": createdAt, "_version": version]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var venueId: GraphQLID? {
    get {
      return graphQLMap["venueID"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "venueID")
    }
  }

  public var userId: GraphQLID? {
    get {
      return graphQLMap["userID"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userID")
    }
  }

  public var rating: Double? {
    get {
      return graphQLMap["rating"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "rating")
    }
  }

  public var comment: String? {
    get {
      return graphQLMap["comment"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "comment")
    }
  }

  public var createdAt: String? {
    get {
      return graphQLMap["createdAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct DeleteReviewInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, version: Int? = nil) {
    graphQLMap = ["id": id, "_version": version]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct CreateChatRoomInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID? = nil, name: String, createdAt: String? = nil, updatedAt: String? = nil, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int? = nil) {
    graphQLMap = ["id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version]
  }

  public var id: GraphQLID? {
    get {
      return graphQLMap["id"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var name: String {
    get {
      return graphQLMap["name"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var createdAt: String? {
    get {
      return graphQLMap["createdAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: String? {
    get {
      return graphQLMap["updatedAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var lastMessage: String? {
    get {
      return graphQLMap["lastMessage"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lastMessage")
    }
  }

  public var lastMessageTimestamp: String? {
    get {
      return graphQLMap["lastMessageTimestamp"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lastMessageTimestamp")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct ModelChatRoomConditionInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(name: ModelStringInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, lastMessage: ModelStringInput? = nil, lastMessageTimestamp: ModelStringInput? = nil, and: [ModelChatRoomConditionInput?]? = nil, or: [ModelChatRoomConditionInput?]? = nil, not: ModelChatRoomConditionInput? = nil, deleted: ModelBooleanInput? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["name": name, "createdAt": createdAt, "updatedAt": updatedAt, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "and": and, "or": or, "not": not, "_deleted": deleted, "owner": owner]
  }

  public var name: ModelStringInput? {
    get {
      return graphQLMap["name"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var lastMessage: ModelStringInput? {
    get {
      return graphQLMap["lastMessage"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lastMessage")
    }
  }

  public var lastMessageTimestamp: ModelStringInput? {
    get {
      return graphQLMap["lastMessageTimestamp"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lastMessageTimestamp")
    }
  }

  public var and: [ModelChatRoomConditionInput?]? {
    get {
      return graphQLMap["and"] as! [ModelChatRoomConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelChatRoomConditionInput?]? {
    get {
      return graphQLMap["or"] as! [ModelChatRoomConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelChatRoomConditionInput? {
    get {
      return graphQLMap["not"] as! ModelChatRoomConditionInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct UpdateChatRoomInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, name: String? = nil, createdAt: String? = nil, updatedAt: String? = nil, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int? = nil) {
    graphQLMap = ["id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var name: String? {
    get {
      return graphQLMap["name"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var createdAt: String? {
    get {
      return graphQLMap["createdAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: String? {
    get {
      return graphQLMap["updatedAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var lastMessage: String? {
    get {
      return graphQLMap["lastMessage"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lastMessage")
    }
  }

  public var lastMessageTimestamp: String? {
    get {
      return graphQLMap["lastMessageTimestamp"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lastMessageTimestamp")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct DeleteChatRoomInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, version: Int? = nil) {
    graphQLMap = ["id": id, "_version": version]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct CreateMessageInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID? = nil, senderId: GraphQLID, chatRoomId: GraphQLID, content: String, timestamp: String, isRead: Bool, readBy: [String?]? = nil, version: Int? = nil) {
    graphQLMap = ["id": id, "senderID": senderId, "chatRoomID": chatRoomId, "content": content, "timestamp": timestamp, "isRead": isRead, "readBy": readBy, "_version": version]
  }

  public var id: GraphQLID? {
    get {
      return graphQLMap["id"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var senderId: GraphQLID {
    get {
      return graphQLMap["senderID"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "senderID")
    }
  }

  public var chatRoomId: GraphQLID {
    get {
      return graphQLMap["chatRoomID"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "chatRoomID")
    }
  }

  public var content: String {
    get {
      return graphQLMap["content"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "content")
    }
  }

  public var timestamp: String {
    get {
      return graphQLMap["timestamp"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "timestamp")
    }
  }

  public var isRead: Bool {
    get {
      return graphQLMap["isRead"] as! Bool
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "isRead")
    }
  }

  public var readBy: [String?]? {
    get {
      return graphQLMap["readBy"] as! [String?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "readBy")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct ModelMessageConditionInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(senderId: ModelIDInput? = nil, chatRoomId: ModelIDInput? = nil, content: ModelStringInput? = nil, timestamp: ModelStringInput? = nil, isRead: ModelBooleanInput? = nil, readBy: ModelStringInput? = nil, and: [ModelMessageConditionInput?]? = nil, or: [ModelMessageConditionInput?]? = nil, not: ModelMessageConditionInput? = nil, deleted: ModelBooleanInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["senderID": senderId, "chatRoomID": chatRoomId, "content": content, "timestamp": timestamp, "isRead": isRead, "readBy": readBy, "and": and, "or": or, "not": not, "_deleted": deleted, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner]
  }

  public var senderId: ModelIDInput? {
    get {
      return graphQLMap["senderID"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "senderID")
    }
  }

  public var chatRoomId: ModelIDInput? {
    get {
      return graphQLMap["chatRoomID"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "chatRoomID")
    }
  }

  public var content: ModelStringInput? {
    get {
      return graphQLMap["content"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "content")
    }
  }

  public var timestamp: ModelStringInput? {
    get {
      return graphQLMap["timestamp"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "timestamp")
    }
  }

  public var isRead: ModelBooleanInput? {
    get {
      return graphQLMap["isRead"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "isRead")
    }
  }

  public var readBy: ModelStringInput? {
    get {
      return graphQLMap["readBy"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "readBy")
    }
  }

  public var and: [ModelMessageConditionInput?]? {
    get {
      return graphQLMap["and"] as! [ModelMessageConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelMessageConditionInput?]? {
    get {
      return graphQLMap["or"] as! [ModelMessageConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelMessageConditionInput? {
    get {
      return graphQLMap["not"] as! ModelMessageConditionInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct UpdateMessageInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, senderId: GraphQLID? = nil, chatRoomId: GraphQLID? = nil, content: String? = nil, timestamp: String? = nil, isRead: Bool? = nil, readBy: [String?]? = nil, version: Int? = nil) {
    graphQLMap = ["id": id, "senderID": senderId, "chatRoomID": chatRoomId, "content": content, "timestamp": timestamp, "isRead": isRead, "readBy": readBy, "_version": version]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var senderId: GraphQLID? {
    get {
      return graphQLMap["senderID"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "senderID")
    }
  }

  public var chatRoomId: GraphQLID? {
    get {
      return graphQLMap["chatRoomID"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "chatRoomID")
    }
  }

  public var content: String? {
    get {
      return graphQLMap["content"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "content")
    }
  }

  public var timestamp: String? {
    get {
      return graphQLMap["timestamp"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "timestamp")
    }
  }

  public var isRead: Bool? {
    get {
      return graphQLMap["isRead"] as! Bool?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "isRead")
    }
  }

  public var readBy: [String?]? {
    get {
      return graphQLMap["readBy"] as! [String?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "readBy")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct DeleteMessageInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, version: Int? = nil) {
    graphQLMap = ["id": id, "_version": version]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct CreateUserChatRoomsInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID? = nil, userId: GraphQLID, chatRoomId: GraphQLID, version: Int? = nil) {
    graphQLMap = ["id": id, "userId": userId, "chatRoomId": chatRoomId, "_version": version]
  }

  public var id: GraphQLID? {
    get {
      return graphQLMap["id"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var userId: GraphQLID {
    get {
      return graphQLMap["userId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userId")
    }
  }

  public var chatRoomId: GraphQLID {
    get {
      return graphQLMap["chatRoomId"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "chatRoomId")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct ModelUserChatRoomsConditionInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(userId: ModelIDInput? = nil, chatRoomId: ModelIDInput? = nil, and: [ModelUserChatRoomsConditionInput?]? = nil, or: [ModelUserChatRoomsConditionInput?]? = nil, not: ModelUserChatRoomsConditionInput? = nil, deleted: ModelBooleanInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["userId": userId, "chatRoomId": chatRoomId, "and": and, "or": or, "not": not, "_deleted": deleted, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner]
  }

  public var userId: ModelIDInput? {
    get {
      return graphQLMap["userId"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userId")
    }
  }

  public var chatRoomId: ModelIDInput? {
    get {
      return graphQLMap["chatRoomId"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "chatRoomId")
    }
  }

  public var and: [ModelUserChatRoomsConditionInput?]? {
    get {
      return graphQLMap["and"] as! [ModelUserChatRoomsConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelUserChatRoomsConditionInput?]? {
    get {
      return graphQLMap["or"] as! [ModelUserChatRoomsConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelUserChatRoomsConditionInput? {
    get {
      return graphQLMap["not"] as! ModelUserChatRoomsConditionInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct UpdateUserChatRoomsInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, userId: GraphQLID? = nil, chatRoomId: GraphQLID? = nil, version: Int? = nil) {
    graphQLMap = ["id": id, "userId": userId, "chatRoomId": chatRoomId, "_version": version]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var userId: GraphQLID? {
    get {
      return graphQLMap["userId"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userId")
    }
  }

  public var chatRoomId: GraphQLID? {
    get {
      return graphQLMap["chatRoomId"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "chatRoomId")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct DeleteUserChatRoomsInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, version: Int? = nil) {
    graphQLMap = ["id": id, "_version": version]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var version: Int? {
    get {
      return graphQLMap["_version"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_version")
    }
  }
}

public struct ModelUserFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelIDInput? = nil, username: ModelStringInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, and: [ModelUserFilterInput?]? = nil, or: [ModelUserFilterInput?]? = nil, not: ModelUserFilterInput? = nil, deleted: ModelBooleanInput? = nil) {
    graphQLMap = ["id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "not": not, "_deleted": deleted]
  }

  public var id: ModelIDInput? {
    get {
      return graphQLMap["id"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var username: ModelStringInput? {
    get {
      return graphQLMap["username"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "username")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelUserFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelUserFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelUserFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelUserFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelUserFilterInput? {
    get {
      return graphQLMap["not"] as! ModelUserFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }
}

public struct ModelVenueFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelIDInput? = nil, name: ModelStringInput? = nil, description: ModelStringInput? = nil, address: ModelStringInput? = nil, latitude: ModelFloatInput? = nil, longitude: ModelFloatInput? = nil, rating: ModelFloatInput? = nil, imageKey: ModelStringInput? = nil, ownerId: ModelIDInput? = nil, maxCapacity: ModelIntInput? = nil, currentUsers: ModelIntInput? = nil, revenue: ModelFloatInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, and: [ModelVenueFilterInput?]? = nil, or: [ModelVenueFilterInput?]? = nil, not: ModelVenueFilterInput? = nil, deleted: ModelBooleanInput? = nil) {
    graphQLMap = ["id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "not": not, "_deleted": deleted]
  }

  public var id: ModelIDInput? {
    get {
      return graphQLMap["id"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var name: ModelStringInput? {
    get {
      return graphQLMap["name"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var description: ModelStringInput? {
    get {
      return graphQLMap["description"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "description")
    }
  }

  public var address: ModelStringInput? {
    get {
      return graphQLMap["address"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "address")
    }
  }

  public var latitude: ModelFloatInput? {
    get {
      return graphQLMap["latitude"] as! ModelFloatInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "latitude")
    }
  }

  public var longitude: ModelFloatInput? {
    get {
      return graphQLMap["longitude"] as! ModelFloatInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "longitude")
    }
  }

  public var rating: ModelFloatInput? {
    get {
      return graphQLMap["rating"] as! ModelFloatInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "rating")
    }
  }

  public var imageKey: ModelStringInput? {
    get {
      return graphQLMap["imageKey"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "imageKey")
    }
  }

  public var ownerId: ModelIDInput? {
    get {
      return graphQLMap["ownerID"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ownerID")
    }
  }

  public var maxCapacity: ModelIntInput? {
    get {
      return graphQLMap["maxCapacity"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "maxCapacity")
    }
  }

  public var currentUsers: ModelIntInput? {
    get {
      return graphQLMap["currentUsers"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "currentUsers")
    }
  }

  public var revenue: ModelFloatInput? {
    get {
      return graphQLMap["revenue"] as! ModelFloatInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "revenue")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelVenueFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelVenueFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelVenueFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelVenueFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelVenueFilterInput? {
    get {
      return graphQLMap["not"] as! ModelVenueFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }
}

public struct ModelDailyUserCountFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelIDInput? = nil, venueId: ModelIDInput? = nil, date: ModelStringInput? = nil, userCount: ModelIntInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, and: [ModelDailyUserCountFilterInput?]? = nil, or: [ModelDailyUserCountFilterInput?]? = nil, not: ModelDailyUserCountFilterInput? = nil, deleted: ModelBooleanInput? = nil) {
    graphQLMap = ["id": id, "venueID": venueId, "date": date, "userCount": userCount, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "not": not, "_deleted": deleted]
  }

  public var id: ModelIDInput? {
    get {
      return graphQLMap["id"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var venueId: ModelIDInput? {
    get {
      return graphQLMap["venueID"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "venueID")
    }
  }

  public var date: ModelStringInput? {
    get {
      return graphQLMap["date"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "date")
    }
  }

  public var userCount: ModelIntInput? {
    get {
      return graphQLMap["userCount"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userCount")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelDailyUserCountFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelDailyUserCountFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelDailyUserCountFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelDailyUserCountFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelDailyUserCountFilterInput? {
    get {
      return graphQLMap["not"] as! ModelDailyUserCountFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }
}

public struct ModelReviewFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelIDInput? = nil, venueId: ModelIDInput? = nil, userId: ModelIDInput? = nil, rating: ModelFloatInput? = nil, comment: ModelStringInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, and: [ModelReviewFilterInput?]? = nil, or: [ModelReviewFilterInput?]? = nil, not: ModelReviewFilterInput? = nil, deleted: ModelBooleanInput? = nil) {
    graphQLMap = ["id": id, "venueID": venueId, "userID": userId, "rating": rating, "comment": comment, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "not": not, "_deleted": deleted]
  }

  public var id: ModelIDInput? {
    get {
      return graphQLMap["id"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var venueId: ModelIDInput? {
    get {
      return graphQLMap["venueID"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "venueID")
    }
  }

  public var userId: ModelIDInput? {
    get {
      return graphQLMap["userID"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userID")
    }
  }

  public var rating: ModelFloatInput? {
    get {
      return graphQLMap["rating"] as! ModelFloatInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "rating")
    }
  }

  public var comment: ModelStringInput? {
    get {
      return graphQLMap["comment"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "comment")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelReviewFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelReviewFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelReviewFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelReviewFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelReviewFilterInput? {
    get {
      return graphQLMap["not"] as! ModelReviewFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }
}

public struct ModelChatRoomFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelIDInput? = nil, name: ModelStringInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, lastMessage: ModelStringInput? = nil, lastMessageTimestamp: ModelStringInput? = nil, and: [ModelChatRoomFilterInput?]? = nil, or: [ModelChatRoomFilterInput?]? = nil, not: ModelChatRoomFilterInput? = nil, deleted: ModelBooleanInput? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "and": and, "or": or, "not": not, "_deleted": deleted, "owner": owner]
  }

  public var id: ModelIDInput? {
    get {
      return graphQLMap["id"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var name: ModelStringInput? {
    get {
      return graphQLMap["name"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var lastMessage: ModelStringInput? {
    get {
      return graphQLMap["lastMessage"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lastMessage")
    }
  }

  public var lastMessageTimestamp: ModelStringInput? {
    get {
      return graphQLMap["lastMessageTimestamp"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lastMessageTimestamp")
    }
  }

  public var and: [ModelChatRoomFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelChatRoomFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelChatRoomFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelChatRoomFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelChatRoomFilterInput? {
    get {
      return graphQLMap["not"] as! ModelChatRoomFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct ModelMessageFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelIDInput? = nil, senderId: ModelIDInput? = nil, chatRoomId: ModelIDInput? = nil, content: ModelStringInput? = nil, timestamp: ModelStringInput? = nil, isRead: ModelBooleanInput? = nil, readBy: ModelStringInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, and: [ModelMessageFilterInput?]? = nil, or: [ModelMessageFilterInput?]? = nil, not: ModelMessageFilterInput? = nil, deleted: ModelBooleanInput? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["id": id, "senderID": senderId, "chatRoomID": chatRoomId, "content": content, "timestamp": timestamp, "isRead": isRead, "readBy": readBy, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "not": not, "_deleted": deleted, "owner": owner]
  }

  public var id: ModelIDInput? {
    get {
      return graphQLMap["id"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var senderId: ModelIDInput? {
    get {
      return graphQLMap["senderID"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "senderID")
    }
  }

  public var chatRoomId: ModelIDInput? {
    get {
      return graphQLMap["chatRoomID"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "chatRoomID")
    }
  }

  public var content: ModelStringInput? {
    get {
      return graphQLMap["content"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "content")
    }
  }

  public var timestamp: ModelStringInput? {
    get {
      return graphQLMap["timestamp"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "timestamp")
    }
  }

  public var isRead: ModelBooleanInput? {
    get {
      return graphQLMap["isRead"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "isRead")
    }
  }

  public var readBy: ModelStringInput? {
    get {
      return graphQLMap["readBy"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "readBy")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelMessageFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelMessageFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelMessageFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelMessageFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelMessageFilterInput? {
    get {
      return graphQLMap["not"] as! ModelMessageFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct ModelUserChatRoomsFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelIDInput? = nil, userId: ModelIDInput? = nil, chatRoomId: ModelIDInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, and: [ModelUserChatRoomsFilterInput?]? = nil, or: [ModelUserChatRoomsFilterInput?]? = nil, not: ModelUserChatRoomsFilterInput? = nil, deleted: ModelBooleanInput? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["id": id, "userId": userId, "chatRoomId": chatRoomId, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "not": not, "_deleted": deleted, "owner": owner]
  }

  public var id: ModelIDInput? {
    get {
      return graphQLMap["id"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var userId: ModelIDInput? {
    get {
      return graphQLMap["userId"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userId")
    }
  }

  public var chatRoomId: ModelIDInput? {
    get {
      return graphQLMap["chatRoomId"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "chatRoomId")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelUserChatRoomsFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelUserChatRoomsFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelUserChatRoomsFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelUserChatRoomsFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelUserChatRoomsFilterInput? {
    get {
      return graphQLMap["not"] as! ModelUserChatRoomsFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct ModelStringKeyConditionInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(eq: String? = nil, le: String? = nil, lt: String? = nil, ge: String? = nil, gt: String? = nil, between: [String?]? = nil, beginsWith: String? = nil) {
    graphQLMap = ["eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "between": between, "beginsWith": beginsWith]
  }

  public var eq: String? {
    get {
      return graphQLMap["eq"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: String? {
    get {
      return graphQLMap["le"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: String? {
    get {
      return graphQLMap["lt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: String? {
    get {
      return graphQLMap["ge"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: String? {
    get {
      return graphQLMap["gt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var between: [String?]? {
    get {
      return graphQLMap["between"] as! [String?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var beginsWith: String? {
    get {
      return graphQLMap["beginsWith"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "beginsWith")
    }
  }
}

public enum ModelSortDirection: RawRepresentable, Equatable, JSONDecodable, JSONEncodable {
  public typealias RawValue = String
  case asc
  case desc
  /// Auto generated constant for unknown enum values
  case unknown(RawValue)

  public init?(rawValue: RawValue) {
    switch rawValue {
      case "ASC": self = .asc
      case "DESC": self = .desc
      default: self = .unknown(rawValue)
    }
  }

  public var rawValue: RawValue {
    switch self {
      case .asc: return "ASC"
      case .desc: return "DESC"
      case .unknown(let value): return value
    }
  }

  public static func == (lhs: ModelSortDirection, rhs: ModelSortDirection) -> Bool {
    switch (lhs, rhs) {
      case (.asc, .asc): return true
      case (.desc, .desc): return true
      case (.unknown(let lhsValue), .unknown(let rhsValue)): return lhsValue == rhsValue
      default: return false
    }
  }
}

public struct ModelSubscriptionUserFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelSubscriptionIDInput? = nil, username: ModelSubscriptionStringInput? = nil, createdAt: ModelSubscriptionStringInput? = nil, updatedAt: ModelSubscriptionStringInput? = nil, and: [ModelSubscriptionUserFilterInput?]? = nil, or: [ModelSubscriptionUserFilterInput?]? = nil, deleted: ModelBooleanInput? = nil) {
    graphQLMap = ["id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "_deleted": deleted]
  }

  public var id: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["id"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var username: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["username"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "username")
    }
  }

  public var createdAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelSubscriptionUserFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelSubscriptionUserFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelSubscriptionUserFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelSubscriptionUserFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }
}

public struct ModelSubscriptionIDInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: GraphQLID? = nil, eq: GraphQLID? = nil, le: GraphQLID? = nil, lt: GraphQLID? = nil, ge: GraphQLID? = nil, gt: GraphQLID? = nil, contains: GraphQLID? = nil, notContains: GraphQLID? = nil, between: [GraphQLID?]? = nil, beginsWith: GraphQLID? = nil, `in`: [GraphQLID?]? = nil, notIn: [GraphQLID?]? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "contains": contains, "notContains": notContains, "between": between, "beginsWith": beginsWith, "in": `in`, "notIn": notIn]
  }

  public var ne: GraphQLID? {
    get {
      return graphQLMap["ne"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: GraphQLID? {
    get {
      return graphQLMap["eq"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: GraphQLID? {
    get {
      return graphQLMap["le"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: GraphQLID? {
    get {
      return graphQLMap["lt"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: GraphQLID? {
    get {
      return graphQLMap["ge"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: GraphQLID? {
    get {
      return graphQLMap["gt"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var contains: GraphQLID? {
    get {
      return graphQLMap["contains"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "contains")
    }
  }

  public var notContains: GraphQLID? {
    get {
      return graphQLMap["notContains"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notContains")
    }
  }

  public var between: [GraphQLID?]? {
    get {
      return graphQLMap["between"] as! [GraphQLID?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var beginsWith: GraphQLID? {
    get {
      return graphQLMap["beginsWith"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "beginsWith")
    }
  }

  public var `in`: [GraphQLID?]? {
    get {
      return graphQLMap["in"] as! [GraphQLID?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "in")
    }
  }

  public var notIn: [GraphQLID?]? {
    get {
      return graphQLMap["notIn"] as! [GraphQLID?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notIn")
    }
  }
}

public struct ModelSubscriptionStringInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: String? = nil, eq: String? = nil, le: String? = nil, lt: String? = nil, ge: String? = nil, gt: String? = nil, contains: String? = nil, notContains: String? = nil, between: [String?]? = nil, beginsWith: String? = nil, `in`: [String?]? = nil, notIn: [String?]? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "contains": contains, "notContains": notContains, "between": between, "beginsWith": beginsWith, "in": `in`, "notIn": notIn]
  }

  public var ne: String? {
    get {
      return graphQLMap["ne"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: String? {
    get {
      return graphQLMap["eq"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: String? {
    get {
      return graphQLMap["le"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: String? {
    get {
      return graphQLMap["lt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: String? {
    get {
      return graphQLMap["ge"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: String? {
    get {
      return graphQLMap["gt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var contains: String? {
    get {
      return graphQLMap["contains"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "contains")
    }
  }

  public var notContains: String? {
    get {
      return graphQLMap["notContains"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notContains")
    }
  }

  public var between: [String?]? {
    get {
      return graphQLMap["between"] as! [String?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var beginsWith: String? {
    get {
      return graphQLMap["beginsWith"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "beginsWith")
    }
  }

  public var `in`: [String?]? {
    get {
      return graphQLMap["in"] as! [String?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "in")
    }
  }

  public var notIn: [String?]? {
    get {
      return graphQLMap["notIn"] as! [String?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notIn")
    }
  }
}

public struct ModelSubscriptionVenueFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelSubscriptionIDInput? = nil, name: ModelSubscriptionStringInput? = nil, description: ModelSubscriptionStringInput? = nil, address: ModelSubscriptionStringInput? = nil, latitude: ModelSubscriptionFloatInput? = nil, longitude: ModelSubscriptionFloatInput? = nil, rating: ModelSubscriptionFloatInput? = nil, imageKey: ModelSubscriptionStringInput? = nil, ownerId: ModelSubscriptionIDInput? = nil, maxCapacity: ModelSubscriptionIntInput? = nil, currentUsers: ModelSubscriptionIntInput? = nil, revenue: ModelSubscriptionFloatInput? = nil, createdAt: ModelSubscriptionStringInput? = nil, updatedAt: ModelSubscriptionStringInput? = nil, and: [ModelSubscriptionVenueFilterInput?]? = nil, or: [ModelSubscriptionVenueFilterInput?]? = nil, deleted: ModelBooleanInput? = nil) {
    graphQLMap = ["id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "_deleted": deleted]
  }

  public var id: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["id"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var name: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["name"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var description: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["description"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "description")
    }
  }

  public var address: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["address"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "address")
    }
  }

  public var latitude: ModelSubscriptionFloatInput? {
    get {
      return graphQLMap["latitude"] as! ModelSubscriptionFloatInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "latitude")
    }
  }

  public var longitude: ModelSubscriptionFloatInput? {
    get {
      return graphQLMap["longitude"] as! ModelSubscriptionFloatInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "longitude")
    }
  }

  public var rating: ModelSubscriptionFloatInput? {
    get {
      return graphQLMap["rating"] as! ModelSubscriptionFloatInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "rating")
    }
  }

  public var imageKey: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["imageKey"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "imageKey")
    }
  }

  public var ownerId: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["ownerID"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ownerID")
    }
  }

  public var maxCapacity: ModelSubscriptionIntInput? {
    get {
      return graphQLMap["maxCapacity"] as! ModelSubscriptionIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "maxCapacity")
    }
  }

  public var currentUsers: ModelSubscriptionIntInput? {
    get {
      return graphQLMap["currentUsers"] as! ModelSubscriptionIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "currentUsers")
    }
  }

  public var revenue: ModelSubscriptionFloatInput? {
    get {
      return graphQLMap["revenue"] as! ModelSubscriptionFloatInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "revenue")
    }
  }

  public var createdAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelSubscriptionVenueFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelSubscriptionVenueFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelSubscriptionVenueFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelSubscriptionVenueFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }
}

public struct ModelSubscriptionFloatInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: Double? = nil, eq: Double? = nil, le: Double? = nil, lt: Double? = nil, ge: Double? = nil, gt: Double? = nil, between: [Double?]? = nil, `in`: [Double?]? = nil, notIn: [Double?]? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "between": between, "in": `in`, "notIn": notIn]
  }

  public var ne: Double? {
    get {
      return graphQLMap["ne"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: Double? {
    get {
      return graphQLMap["eq"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: Double? {
    get {
      return graphQLMap["le"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: Double? {
    get {
      return graphQLMap["lt"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: Double? {
    get {
      return graphQLMap["ge"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: Double? {
    get {
      return graphQLMap["gt"] as! Double?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var between: [Double?]? {
    get {
      return graphQLMap["between"] as! [Double?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var `in`: [Double?]? {
    get {
      return graphQLMap["in"] as! [Double?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "in")
    }
  }

  public var notIn: [Double?]? {
    get {
      return graphQLMap["notIn"] as! [Double?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notIn")
    }
  }
}

public struct ModelSubscriptionIntInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: Int? = nil, eq: Int? = nil, le: Int? = nil, lt: Int? = nil, ge: Int? = nil, gt: Int? = nil, between: [Int?]? = nil, `in`: [Int?]? = nil, notIn: [Int?]? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "between": between, "in": `in`, "notIn": notIn]
  }

  public var ne: Int? {
    get {
      return graphQLMap["ne"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: Int? {
    get {
      return graphQLMap["eq"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: Int? {
    get {
      return graphQLMap["le"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: Int? {
    get {
      return graphQLMap["lt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: Int? {
    get {
      return graphQLMap["ge"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: Int? {
    get {
      return graphQLMap["gt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var between: [Int?]? {
    get {
      return graphQLMap["between"] as! [Int?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var `in`: [Int?]? {
    get {
      return graphQLMap["in"] as! [Int?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "in")
    }
  }

  public var notIn: [Int?]? {
    get {
      return graphQLMap["notIn"] as! [Int?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notIn")
    }
  }
}

public struct ModelSubscriptionDailyUserCountFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelSubscriptionIDInput? = nil, venueId: ModelSubscriptionIDInput? = nil, date: ModelSubscriptionStringInput? = nil, userCount: ModelSubscriptionIntInput? = nil, createdAt: ModelSubscriptionStringInput? = nil, updatedAt: ModelSubscriptionStringInput? = nil, and: [ModelSubscriptionDailyUserCountFilterInput?]? = nil, or: [ModelSubscriptionDailyUserCountFilterInput?]? = nil, deleted: ModelBooleanInput? = nil) {
    graphQLMap = ["id": id, "venueID": venueId, "date": date, "userCount": userCount, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "_deleted": deleted]
  }

  public var id: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["id"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var venueId: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["venueID"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "venueID")
    }
  }

  public var date: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["date"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "date")
    }
  }

  public var userCount: ModelSubscriptionIntInput? {
    get {
      return graphQLMap["userCount"] as! ModelSubscriptionIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userCount")
    }
  }

  public var createdAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelSubscriptionDailyUserCountFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelSubscriptionDailyUserCountFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelSubscriptionDailyUserCountFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelSubscriptionDailyUserCountFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }
}

public struct ModelSubscriptionReviewFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelSubscriptionIDInput? = nil, venueId: ModelSubscriptionIDInput? = nil, userId: ModelSubscriptionIDInput? = nil, rating: ModelSubscriptionFloatInput? = nil, comment: ModelSubscriptionStringInput? = nil, createdAt: ModelSubscriptionStringInput? = nil, updatedAt: ModelSubscriptionStringInput? = nil, and: [ModelSubscriptionReviewFilterInput?]? = nil, or: [ModelSubscriptionReviewFilterInput?]? = nil, deleted: ModelBooleanInput? = nil) {
    graphQLMap = ["id": id, "venueID": venueId, "userID": userId, "rating": rating, "comment": comment, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "_deleted": deleted]
  }

  public var id: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["id"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var venueId: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["venueID"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "venueID")
    }
  }

  public var userId: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["userID"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userID")
    }
  }

  public var rating: ModelSubscriptionFloatInput? {
    get {
      return graphQLMap["rating"] as! ModelSubscriptionFloatInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "rating")
    }
  }

  public var comment: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["comment"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "comment")
    }
  }

  public var createdAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelSubscriptionReviewFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelSubscriptionReviewFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelSubscriptionReviewFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelSubscriptionReviewFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }
}

public struct ModelSubscriptionChatRoomFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelSubscriptionIDInput? = nil, name: ModelSubscriptionStringInput? = nil, createdAt: ModelSubscriptionStringInput? = nil, updatedAt: ModelSubscriptionStringInput? = nil, lastMessage: ModelSubscriptionStringInput? = nil, lastMessageTimestamp: ModelSubscriptionStringInput? = nil, and: [ModelSubscriptionChatRoomFilterInput?]? = nil, or: [ModelSubscriptionChatRoomFilterInput?]? = nil, deleted: ModelBooleanInput? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "and": and, "or": or, "_deleted": deleted, "owner": owner]
  }

  public var id: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["id"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var name: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["name"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "name")
    }
  }

  public var createdAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var lastMessage: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["lastMessage"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lastMessage")
    }
  }

  public var lastMessageTimestamp: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["lastMessageTimestamp"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lastMessageTimestamp")
    }
  }

  public var and: [ModelSubscriptionChatRoomFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelSubscriptionChatRoomFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelSubscriptionChatRoomFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelSubscriptionChatRoomFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct ModelSubscriptionMessageFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelSubscriptionIDInput? = nil, senderId: ModelSubscriptionIDInput? = nil, chatRoomId: ModelSubscriptionIDInput? = nil, content: ModelSubscriptionStringInput? = nil, timestamp: ModelSubscriptionStringInput? = nil, isRead: ModelSubscriptionBooleanInput? = nil, readBy: ModelSubscriptionStringInput? = nil, createdAt: ModelSubscriptionStringInput? = nil, updatedAt: ModelSubscriptionStringInput? = nil, and: [ModelSubscriptionMessageFilterInput?]? = nil, or: [ModelSubscriptionMessageFilterInput?]? = nil, deleted: ModelBooleanInput? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["id": id, "senderID": senderId, "chatRoomID": chatRoomId, "content": content, "timestamp": timestamp, "isRead": isRead, "readBy": readBy, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "_deleted": deleted, "owner": owner]
  }

  public var id: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["id"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var senderId: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["senderID"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "senderID")
    }
  }

  public var chatRoomId: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["chatRoomID"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "chatRoomID")
    }
  }

  public var content: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["content"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "content")
    }
  }

  public var timestamp: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["timestamp"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "timestamp")
    }
  }

  public var isRead: ModelSubscriptionBooleanInput? {
    get {
      return graphQLMap["isRead"] as! ModelSubscriptionBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "isRead")
    }
  }

  public var readBy: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["readBy"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "readBy")
    }
  }

  public var createdAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelSubscriptionMessageFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelSubscriptionMessageFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelSubscriptionMessageFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelSubscriptionMessageFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct ModelSubscriptionBooleanInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: Bool? = nil, eq: Bool? = nil) {
    graphQLMap = ["ne": ne, "eq": eq]
  }

  public var ne: Bool? {
    get {
      return graphQLMap["ne"] as! Bool?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: Bool? {
    get {
      return graphQLMap["eq"] as! Bool?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }
}

public struct ModelSubscriptionUserChatRoomsFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelSubscriptionIDInput? = nil, userId: ModelSubscriptionIDInput? = nil, chatRoomId: ModelSubscriptionIDInput? = nil, createdAt: ModelSubscriptionStringInput? = nil, updatedAt: ModelSubscriptionStringInput? = nil, and: [ModelSubscriptionUserChatRoomsFilterInput?]? = nil, or: [ModelSubscriptionUserChatRoomsFilterInput?]? = nil, deleted: ModelBooleanInput? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["id": id, "userId": userId, "chatRoomId": chatRoomId, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "_deleted": deleted, "owner": owner]
  }

  public var id: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["id"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var userId: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["userId"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "userId")
    }
  }

  public var chatRoomId: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["chatRoomId"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "chatRoomId")
    }
  }

  public var createdAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelSubscriptionUserChatRoomsFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelSubscriptionUserChatRoomsFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelSubscriptionUserChatRoomsFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelSubscriptionUserChatRoomsFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var deleted: ModelBooleanInput? {
    get {
      return graphQLMap["_deleted"] as! ModelBooleanInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "_deleted")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public final class CreateUserMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreateUser($input: CreateUserInput!, $condition: ModelUserConditionInput) {\n  createUser(input: $input, condition: $condition) {\n    __typename\n    id\n    username\n    messages {\n      __typename\n      nextToken\n      startedAt\n    }\n    chatRoom {\n      __typename\n      nextToken\n      startedAt\n    }\n    venues {\n      __typename\n      nextToken\n      startedAt\n    }\n    review {\n      __typename\n      nextToken\n      startedAt\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var input: CreateUserInput
  public var condition: ModelUserConditionInput?

  public init(input: CreateUserInput, condition: ModelUserConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createUser", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(CreateUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createUser: CreateUser? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createUser": createUser.flatMap { $0.snapshot }])
    }

    public var createUser: CreateUser? {
      get {
        return (snapshot["createUser"] as? Snapshot).flatMap { CreateUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createUser")
      }
    }

    public struct CreateUser: GraphQLSelectionSet {
      public static let possibleTypes = ["User"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("messages", type: .object(Message.selections)),
        GraphQLField("chatRoom", type: .object(ChatRoom.selections)),
        GraphQLField("venues", type: .object(Venue.selections)),
        GraphQLField("review", type: .object(Review.selections)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, username: String, messages: Message? = nil, chatRoom: ChatRoom? = nil, venues: Venue? = nil, review: Review? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "User", "id": id, "username": username, "messages": messages.flatMap { $0.snapshot }, "chatRoom": chatRoom.flatMap { $0.snapshot }, "venues": venues.flatMap { $0.snapshot }, "review": review.flatMap { $0.snapshot }, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var messages: Message? {
        get {
          return (snapshot["messages"] as? Snapshot).flatMap { Message(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "messages")
        }
      }

      public var chatRoom: ChatRoom? {
        get {
          return (snapshot["chatRoom"] as? Snapshot).flatMap { ChatRoom(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "chatRoom")
        }
      }

      public var venues: Venue? {
        get {
          return (snapshot["venues"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venues")
        }
      }

      public var review: Review? {
        get {
          return (snapshot["review"] as? Snapshot).flatMap { Review(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "review")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Message: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelMessageConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelMessageConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct ChatRoom: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelUserChatRoomsConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelVenueConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelVenueConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Review: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelReviewConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelReviewConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class UpdateUserMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdateUser($input: UpdateUserInput!, $condition: ModelUserConditionInput) {\n  updateUser(input: $input, condition: $condition) {\n    __typename\n    id\n    username\n    messages {\n      __typename\n      nextToken\n      startedAt\n    }\n    chatRoom {\n      __typename\n      nextToken\n      startedAt\n    }\n    venues {\n      __typename\n      nextToken\n      startedAt\n    }\n    review {\n      __typename\n      nextToken\n      startedAt\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var input: UpdateUserInput
  public var condition: ModelUserConditionInput?

  public init(input: UpdateUserInput, condition: ModelUserConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updateUser", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(UpdateUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updateUser: UpdateUser? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updateUser": updateUser.flatMap { $0.snapshot }])
    }

    public var updateUser: UpdateUser? {
      get {
        return (snapshot["updateUser"] as? Snapshot).flatMap { UpdateUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updateUser")
      }
    }

    public struct UpdateUser: GraphQLSelectionSet {
      public static let possibleTypes = ["User"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("messages", type: .object(Message.selections)),
        GraphQLField("chatRoom", type: .object(ChatRoom.selections)),
        GraphQLField("venues", type: .object(Venue.selections)),
        GraphQLField("review", type: .object(Review.selections)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, username: String, messages: Message? = nil, chatRoom: ChatRoom? = nil, venues: Venue? = nil, review: Review? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "User", "id": id, "username": username, "messages": messages.flatMap { $0.snapshot }, "chatRoom": chatRoom.flatMap { $0.snapshot }, "venues": venues.flatMap { $0.snapshot }, "review": review.flatMap { $0.snapshot }, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var messages: Message? {
        get {
          return (snapshot["messages"] as? Snapshot).flatMap { Message(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "messages")
        }
      }

      public var chatRoom: ChatRoom? {
        get {
          return (snapshot["chatRoom"] as? Snapshot).flatMap { ChatRoom(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "chatRoom")
        }
      }

      public var venues: Venue? {
        get {
          return (snapshot["venues"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venues")
        }
      }

      public var review: Review? {
        get {
          return (snapshot["review"] as? Snapshot).flatMap { Review(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "review")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Message: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelMessageConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelMessageConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct ChatRoom: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelUserChatRoomsConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelVenueConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelVenueConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Review: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelReviewConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelReviewConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class DeleteUserMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeleteUser($input: DeleteUserInput!, $condition: ModelUserConditionInput) {\n  deleteUser(input: $input, condition: $condition) {\n    __typename\n    id\n    username\n    messages {\n      __typename\n      nextToken\n      startedAt\n    }\n    chatRoom {\n      __typename\n      nextToken\n      startedAt\n    }\n    venues {\n      __typename\n      nextToken\n      startedAt\n    }\n    review {\n      __typename\n      nextToken\n      startedAt\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var input: DeleteUserInput
  public var condition: ModelUserConditionInput?

  public init(input: DeleteUserInput, condition: ModelUserConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deleteUser", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(DeleteUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deleteUser: DeleteUser? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteUser": deleteUser.flatMap { $0.snapshot }])
    }

    public var deleteUser: DeleteUser? {
      get {
        return (snapshot["deleteUser"] as? Snapshot).flatMap { DeleteUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteUser")
      }
    }

    public struct DeleteUser: GraphQLSelectionSet {
      public static let possibleTypes = ["User"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("messages", type: .object(Message.selections)),
        GraphQLField("chatRoom", type: .object(ChatRoom.selections)),
        GraphQLField("venues", type: .object(Venue.selections)),
        GraphQLField("review", type: .object(Review.selections)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, username: String, messages: Message? = nil, chatRoom: ChatRoom? = nil, venues: Venue? = nil, review: Review? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "User", "id": id, "username": username, "messages": messages.flatMap { $0.snapshot }, "chatRoom": chatRoom.flatMap { $0.snapshot }, "venues": venues.flatMap { $0.snapshot }, "review": review.flatMap { $0.snapshot }, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var messages: Message? {
        get {
          return (snapshot["messages"] as? Snapshot).flatMap { Message(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "messages")
        }
      }

      public var chatRoom: ChatRoom? {
        get {
          return (snapshot["chatRoom"] as? Snapshot).flatMap { ChatRoom(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "chatRoom")
        }
      }

      public var venues: Venue? {
        get {
          return (snapshot["venues"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venues")
        }
      }

      public var review: Review? {
        get {
          return (snapshot["review"] as? Snapshot).flatMap { Review(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "review")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Message: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelMessageConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelMessageConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct ChatRoom: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelUserChatRoomsConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelVenueConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelVenueConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Review: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelReviewConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelReviewConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class CreateVenueMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreateVenue($input: CreateVenueInput!, $condition: ModelVenueConditionInput) {\n  createVenue(input: $input, condition: $condition) {\n    __typename\n    id\n    name\n    description\n    address\n    latitude\n    longitude\n    rating\n    imageKey\n    ownerID\n    owner {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    maxCapacity\n    currentUsers\n    revenue\n    dailyUserCounts {\n      __typename\n      nextToken\n      startedAt\n    }\n    reviews {\n      __typename\n      nextToken\n      startedAt\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var input: CreateVenueInput
  public var condition: ModelVenueConditionInput?

  public init(input: CreateVenueInput, condition: ModelVenueConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createVenue", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(CreateVenue.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createVenue: CreateVenue? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createVenue": createVenue.flatMap { $0.snapshot }])
    }

    public var createVenue: CreateVenue? {
      get {
        return (snapshot["createVenue"] as? Snapshot).flatMap { CreateVenue(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createVenue")
      }
    }

    public struct CreateVenue: GraphQLSelectionSet {
      public static let possibleTypes = ["Venue"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("description", type: .nonNull(.scalar(String.self))),
        GraphQLField("address", type: .nonNull(.scalar(String.self))),
        GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
        GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
        GraphQLField("rating", type: .scalar(Double.self)),
        GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
        GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("owner", type: .object(Owner.selections)),
        GraphQLField("maxCapacity", type: .scalar(Int.self)),
        GraphQLField("currentUsers", type: .scalar(Int.self)),
        GraphQLField("revenue", type: .scalar(Double.self)),
        GraphQLField("dailyUserCounts", type: .object(DailyUserCount.selections)),
        GraphQLField("reviews", type: .object(Review.selections)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, owner: Owner? = nil, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, dailyUserCounts: DailyUserCount? = nil, reviews: Review? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "owner": owner.flatMap { $0.snapshot }, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "dailyUserCounts": dailyUserCounts.flatMap { $0.snapshot }, "reviews": reviews.flatMap { $0.snapshot }, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var description: String {
        get {
          return snapshot["description"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "description")
        }
      }

      public var address: String {
        get {
          return snapshot["address"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "address")
        }
      }

      public var latitude: Double {
        get {
          return snapshot["latitude"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "latitude")
        }
      }

      public var longitude: Double {
        get {
          return snapshot["longitude"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "longitude")
        }
      }

      public var rating: Double? {
        get {
          return snapshot["rating"] as? Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "rating")
        }
      }

      public var imageKey: [String]? {
        get {
          return snapshot["imageKey"] as? [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "imageKey")
        }
      }

      public var ownerId: GraphQLID {
        get {
          return snapshot["ownerID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "ownerID")
        }
      }

      public var owner: Owner? {
        get {
          return (snapshot["owner"] as? Snapshot).flatMap { Owner(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "owner")
        }
      }

      public var maxCapacity: Int? {
        get {
          return snapshot["maxCapacity"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxCapacity")
        }
      }

      public var currentUsers: Int? {
        get {
          return snapshot["currentUsers"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "currentUsers")
        }
      }

      public var revenue: Double? {
        get {
          return snapshot["revenue"] as? Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "revenue")
        }
      }

      public var dailyUserCounts: DailyUserCount? {
        get {
          return (snapshot["dailyUserCounts"] as? Snapshot).flatMap { DailyUserCount(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "dailyUserCounts")
        }
      }

      public var reviews: Review? {
        get {
          return (snapshot["reviews"] as? Snapshot).flatMap { Review(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "reviews")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Owner: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct DailyUserCount: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelDailyUserCountConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelDailyUserCountConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Review: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelReviewConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelReviewConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class UpdateVenueMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdateVenue($input: UpdateVenueInput!, $condition: ModelVenueConditionInput) {\n  updateVenue(input: $input, condition: $condition) {\n    __typename\n    id\n    name\n    description\n    address\n    latitude\n    longitude\n    rating\n    imageKey\n    ownerID\n    owner {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    maxCapacity\n    currentUsers\n    revenue\n    dailyUserCounts {\n      __typename\n      nextToken\n      startedAt\n    }\n    reviews {\n      __typename\n      nextToken\n      startedAt\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var input: UpdateVenueInput
  public var condition: ModelVenueConditionInput?

  public init(input: UpdateVenueInput, condition: ModelVenueConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updateVenue", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(UpdateVenue.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updateVenue: UpdateVenue? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updateVenue": updateVenue.flatMap { $0.snapshot }])
    }

    public var updateVenue: UpdateVenue? {
      get {
        return (snapshot["updateVenue"] as? Snapshot).flatMap { UpdateVenue(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updateVenue")
      }
    }

    public struct UpdateVenue: GraphQLSelectionSet {
      public static let possibleTypes = ["Venue"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("description", type: .nonNull(.scalar(String.self))),
        GraphQLField("address", type: .nonNull(.scalar(String.self))),
        GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
        GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
        GraphQLField("rating", type: .scalar(Double.self)),
        GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
        GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("owner", type: .object(Owner.selections)),
        GraphQLField("maxCapacity", type: .scalar(Int.self)),
        GraphQLField("currentUsers", type: .scalar(Int.self)),
        GraphQLField("revenue", type: .scalar(Double.self)),
        GraphQLField("dailyUserCounts", type: .object(DailyUserCount.selections)),
        GraphQLField("reviews", type: .object(Review.selections)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, owner: Owner? = nil, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, dailyUserCounts: DailyUserCount? = nil, reviews: Review? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "owner": owner.flatMap { $0.snapshot }, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "dailyUserCounts": dailyUserCounts.flatMap { $0.snapshot }, "reviews": reviews.flatMap { $0.snapshot }, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var description: String {
        get {
          return snapshot["description"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "description")
        }
      }

      public var address: String {
        get {
          return snapshot["address"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "address")
        }
      }

      public var latitude: Double {
        get {
          return snapshot["latitude"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "latitude")
        }
      }

      public var longitude: Double {
        get {
          return snapshot["longitude"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "longitude")
        }
      }

      public var rating: Double? {
        get {
          return snapshot["rating"] as? Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "rating")
        }
      }

      public var imageKey: [String]? {
        get {
          return snapshot["imageKey"] as? [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "imageKey")
        }
      }

      public var ownerId: GraphQLID {
        get {
          return snapshot["ownerID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "ownerID")
        }
      }

      public var owner: Owner? {
        get {
          return (snapshot["owner"] as? Snapshot).flatMap { Owner(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "owner")
        }
      }

      public var maxCapacity: Int? {
        get {
          return snapshot["maxCapacity"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxCapacity")
        }
      }

      public var currentUsers: Int? {
        get {
          return snapshot["currentUsers"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "currentUsers")
        }
      }

      public var revenue: Double? {
        get {
          return snapshot["revenue"] as? Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "revenue")
        }
      }

      public var dailyUserCounts: DailyUserCount? {
        get {
          return (snapshot["dailyUserCounts"] as? Snapshot).flatMap { DailyUserCount(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "dailyUserCounts")
        }
      }

      public var reviews: Review? {
        get {
          return (snapshot["reviews"] as? Snapshot).flatMap { Review(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "reviews")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Owner: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct DailyUserCount: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelDailyUserCountConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelDailyUserCountConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Review: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelReviewConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelReviewConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class DeleteVenueMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeleteVenue($input: DeleteVenueInput!, $condition: ModelVenueConditionInput) {\n  deleteVenue(input: $input, condition: $condition) {\n    __typename\n    id\n    name\n    description\n    address\n    latitude\n    longitude\n    rating\n    imageKey\n    ownerID\n    owner {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    maxCapacity\n    currentUsers\n    revenue\n    dailyUserCounts {\n      __typename\n      nextToken\n      startedAt\n    }\n    reviews {\n      __typename\n      nextToken\n      startedAt\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var input: DeleteVenueInput
  public var condition: ModelVenueConditionInput?

  public init(input: DeleteVenueInput, condition: ModelVenueConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deleteVenue", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(DeleteVenue.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deleteVenue: DeleteVenue? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteVenue": deleteVenue.flatMap { $0.snapshot }])
    }

    public var deleteVenue: DeleteVenue? {
      get {
        return (snapshot["deleteVenue"] as? Snapshot).flatMap { DeleteVenue(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteVenue")
      }
    }

    public struct DeleteVenue: GraphQLSelectionSet {
      public static let possibleTypes = ["Venue"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("description", type: .nonNull(.scalar(String.self))),
        GraphQLField("address", type: .nonNull(.scalar(String.self))),
        GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
        GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
        GraphQLField("rating", type: .scalar(Double.self)),
        GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
        GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("owner", type: .object(Owner.selections)),
        GraphQLField("maxCapacity", type: .scalar(Int.self)),
        GraphQLField("currentUsers", type: .scalar(Int.self)),
        GraphQLField("revenue", type: .scalar(Double.self)),
        GraphQLField("dailyUserCounts", type: .object(DailyUserCount.selections)),
        GraphQLField("reviews", type: .object(Review.selections)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, owner: Owner? = nil, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, dailyUserCounts: DailyUserCount? = nil, reviews: Review? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "owner": owner.flatMap { $0.snapshot }, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "dailyUserCounts": dailyUserCounts.flatMap { $0.snapshot }, "reviews": reviews.flatMap { $0.snapshot }, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var description: String {
        get {
          return snapshot["description"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "description")
        }
      }

      public var address: String {
        get {
          return snapshot["address"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "address")
        }
      }

      public var latitude: Double {
        get {
          return snapshot["latitude"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "latitude")
        }
      }

      public var longitude: Double {
        get {
          return snapshot["longitude"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "longitude")
        }
      }

      public var rating: Double? {
        get {
          return snapshot["rating"] as? Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "rating")
        }
      }

      public var imageKey: [String]? {
        get {
          return snapshot["imageKey"] as? [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "imageKey")
        }
      }

      public var ownerId: GraphQLID {
        get {
          return snapshot["ownerID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "ownerID")
        }
      }

      public var owner: Owner? {
        get {
          return (snapshot["owner"] as? Snapshot).flatMap { Owner(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "owner")
        }
      }

      public var maxCapacity: Int? {
        get {
          return snapshot["maxCapacity"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxCapacity")
        }
      }

      public var currentUsers: Int? {
        get {
          return snapshot["currentUsers"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "currentUsers")
        }
      }

      public var revenue: Double? {
        get {
          return snapshot["revenue"] as? Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "revenue")
        }
      }

      public var dailyUserCounts: DailyUserCount? {
        get {
          return (snapshot["dailyUserCounts"] as? Snapshot).flatMap { DailyUserCount(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "dailyUserCounts")
        }
      }

      public var reviews: Review? {
        get {
          return (snapshot["reviews"] as? Snapshot).flatMap { Review(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "reviews")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Owner: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct DailyUserCount: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelDailyUserCountConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelDailyUserCountConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Review: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelReviewConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelReviewConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class CreateDailyUserCountMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreateDailyUserCount($input: CreateDailyUserCountInput!, $condition: ModelDailyUserCountConditionInput) {\n  createDailyUserCount(input: $input, condition: $condition) {\n    __typename\n    id\n    venueID\n    venue {\n      __typename\n      id\n      name\n      description\n      address\n      latitude\n      longitude\n      rating\n      imageKey\n      ownerID\n      maxCapacity\n      currentUsers\n      revenue\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    date\n    userCount\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var input: CreateDailyUserCountInput
  public var condition: ModelDailyUserCountConditionInput?

  public init(input: CreateDailyUserCountInput, condition: ModelDailyUserCountConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createDailyUserCount", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(CreateDailyUserCount.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createDailyUserCount: CreateDailyUserCount? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createDailyUserCount": createDailyUserCount.flatMap { $0.snapshot }])
    }

    public var createDailyUserCount: CreateDailyUserCount? {
      get {
        return (snapshot["createDailyUserCount"] as? Snapshot).flatMap { CreateDailyUserCount(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createDailyUserCount")
      }
    }

    public struct CreateDailyUserCount: GraphQLSelectionSet {
      public static let possibleTypes = ["DailyUserCount"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venue", type: .object(Venue.selections)),
        GraphQLField("date", type: .nonNull(.scalar(String.self))),
        GraphQLField("userCount", type: .scalar(Int.self)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, venueId: GraphQLID, venue: Venue? = nil, date: String, userCount: Int? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "DailyUserCount", "id": id, "venueID": venueId, "venue": venue.flatMap { $0.snapshot }, "date": date, "userCount": userCount, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var venueId: GraphQLID {
        get {
          return snapshot["venueID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "venueID")
        }
      }

      public var venue: Venue? {
        get {
          return (snapshot["venue"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venue")
        }
      }

      public var date: String {
        get {
          return snapshot["date"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "date")
        }
      }

      public var userCount: Int? {
        get {
          return snapshot["userCount"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "userCount")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["Venue"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("address", type: .nonNull(.scalar(String.self))),
          GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("rating", type: .scalar(Double.self)),
          GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
          GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("maxCapacity", type: .scalar(Int.self)),
          GraphQLField("currentUsers", type: .scalar(Int.self)),
          GraphQLField("revenue", type: .scalar(Double.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var description: String {
          get {
            return snapshot["description"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var address: String {
          get {
            return snapshot["address"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "address")
          }
        }

        public var latitude: Double {
          get {
            return snapshot["latitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "latitude")
          }
        }

        public var longitude: Double {
          get {
            return snapshot["longitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "longitude")
          }
        }

        public var rating: Double? {
          get {
            return snapshot["rating"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var imageKey: [String]? {
          get {
            return snapshot["imageKey"] as? [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "imageKey")
          }
        }

        public var ownerId: GraphQLID {
          get {
            return snapshot["ownerID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "ownerID")
          }
        }

        public var maxCapacity: Int? {
          get {
            return snapshot["maxCapacity"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxCapacity")
          }
        }

        public var currentUsers: Int? {
          get {
            return snapshot["currentUsers"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "currentUsers")
          }
        }

        public var revenue: Double? {
          get {
            return snapshot["revenue"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "revenue")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class UpdateDailyUserCountMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdateDailyUserCount($input: UpdateDailyUserCountInput!, $condition: ModelDailyUserCountConditionInput) {\n  updateDailyUserCount(input: $input, condition: $condition) {\n    __typename\n    id\n    venueID\n    venue {\n      __typename\n      id\n      name\n      description\n      address\n      latitude\n      longitude\n      rating\n      imageKey\n      ownerID\n      maxCapacity\n      currentUsers\n      revenue\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    date\n    userCount\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var input: UpdateDailyUserCountInput
  public var condition: ModelDailyUserCountConditionInput?

  public init(input: UpdateDailyUserCountInput, condition: ModelDailyUserCountConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updateDailyUserCount", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(UpdateDailyUserCount.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updateDailyUserCount: UpdateDailyUserCount? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updateDailyUserCount": updateDailyUserCount.flatMap { $0.snapshot }])
    }

    public var updateDailyUserCount: UpdateDailyUserCount? {
      get {
        return (snapshot["updateDailyUserCount"] as? Snapshot).flatMap { UpdateDailyUserCount(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updateDailyUserCount")
      }
    }

    public struct UpdateDailyUserCount: GraphQLSelectionSet {
      public static let possibleTypes = ["DailyUserCount"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venue", type: .object(Venue.selections)),
        GraphQLField("date", type: .nonNull(.scalar(String.self))),
        GraphQLField("userCount", type: .scalar(Int.self)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, venueId: GraphQLID, venue: Venue? = nil, date: String, userCount: Int? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "DailyUserCount", "id": id, "venueID": venueId, "venue": venue.flatMap { $0.snapshot }, "date": date, "userCount": userCount, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var venueId: GraphQLID {
        get {
          return snapshot["venueID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "venueID")
        }
      }

      public var venue: Venue? {
        get {
          return (snapshot["venue"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venue")
        }
      }

      public var date: String {
        get {
          return snapshot["date"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "date")
        }
      }

      public var userCount: Int? {
        get {
          return snapshot["userCount"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "userCount")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["Venue"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("address", type: .nonNull(.scalar(String.self))),
          GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("rating", type: .scalar(Double.self)),
          GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
          GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("maxCapacity", type: .scalar(Int.self)),
          GraphQLField("currentUsers", type: .scalar(Int.self)),
          GraphQLField("revenue", type: .scalar(Double.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var description: String {
          get {
            return snapshot["description"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var address: String {
          get {
            return snapshot["address"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "address")
          }
        }

        public var latitude: Double {
          get {
            return snapshot["latitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "latitude")
          }
        }

        public var longitude: Double {
          get {
            return snapshot["longitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "longitude")
          }
        }

        public var rating: Double? {
          get {
            return snapshot["rating"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var imageKey: [String]? {
          get {
            return snapshot["imageKey"] as? [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "imageKey")
          }
        }

        public var ownerId: GraphQLID {
          get {
            return snapshot["ownerID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "ownerID")
          }
        }

        public var maxCapacity: Int? {
          get {
            return snapshot["maxCapacity"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxCapacity")
          }
        }

        public var currentUsers: Int? {
          get {
            return snapshot["currentUsers"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "currentUsers")
          }
        }

        public var revenue: Double? {
          get {
            return snapshot["revenue"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "revenue")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class DeleteDailyUserCountMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeleteDailyUserCount($input: DeleteDailyUserCountInput!, $condition: ModelDailyUserCountConditionInput) {\n  deleteDailyUserCount(input: $input, condition: $condition) {\n    __typename\n    id\n    venueID\n    venue {\n      __typename\n      id\n      name\n      description\n      address\n      latitude\n      longitude\n      rating\n      imageKey\n      ownerID\n      maxCapacity\n      currentUsers\n      revenue\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    date\n    userCount\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var input: DeleteDailyUserCountInput
  public var condition: ModelDailyUserCountConditionInput?

  public init(input: DeleteDailyUserCountInput, condition: ModelDailyUserCountConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deleteDailyUserCount", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(DeleteDailyUserCount.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deleteDailyUserCount: DeleteDailyUserCount? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteDailyUserCount": deleteDailyUserCount.flatMap { $0.snapshot }])
    }

    public var deleteDailyUserCount: DeleteDailyUserCount? {
      get {
        return (snapshot["deleteDailyUserCount"] as? Snapshot).flatMap { DeleteDailyUserCount(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteDailyUserCount")
      }
    }

    public struct DeleteDailyUserCount: GraphQLSelectionSet {
      public static let possibleTypes = ["DailyUserCount"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venue", type: .object(Venue.selections)),
        GraphQLField("date", type: .nonNull(.scalar(String.self))),
        GraphQLField("userCount", type: .scalar(Int.self)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, venueId: GraphQLID, venue: Venue? = nil, date: String, userCount: Int? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "DailyUserCount", "id": id, "venueID": venueId, "venue": venue.flatMap { $0.snapshot }, "date": date, "userCount": userCount, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var venueId: GraphQLID {
        get {
          return snapshot["venueID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "venueID")
        }
      }

      public var venue: Venue? {
        get {
          return (snapshot["venue"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venue")
        }
      }

      public var date: String {
        get {
          return snapshot["date"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "date")
        }
      }

      public var userCount: Int? {
        get {
          return snapshot["userCount"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "userCount")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["Venue"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("address", type: .nonNull(.scalar(String.self))),
          GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("rating", type: .scalar(Double.self)),
          GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
          GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("maxCapacity", type: .scalar(Int.self)),
          GraphQLField("currentUsers", type: .scalar(Int.self)),
          GraphQLField("revenue", type: .scalar(Double.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var description: String {
          get {
            return snapshot["description"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var address: String {
          get {
            return snapshot["address"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "address")
          }
        }

        public var latitude: Double {
          get {
            return snapshot["latitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "latitude")
          }
        }

        public var longitude: Double {
          get {
            return snapshot["longitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "longitude")
          }
        }

        public var rating: Double? {
          get {
            return snapshot["rating"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var imageKey: [String]? {
          get {
            return snapshot["imageKey"] as? [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "imageKey")
          }
        }

        public var ownerId: GraphQLID {
          get {
            return snapshot["ownerID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "ownerID")
          }
        }

        public var maxCapacity: Int? {
          get {
            return snapshot["maxCapacity"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxCapacity")
          }
        }

        public var currentUsers: Int? {
          get {
            return snapshot["currentUsers"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "currentUsers")
          }
        }

        public var revenue: Double? {
          get {
            return snapshot["revenue"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "revenue")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class CreateReviewMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreateReview($input: CreateReviewInput!, $condition: ModelReviewConditionInput) {\n  createReview(input: $input, condition: $condition) {\n    __typename\n    id\n    venueID\n    venue {\n      __typename\n      id\n      name\n      description\n      address\n      latitude\n      longitude\n      rating\n      imageKey\n      ownerID\n      maxCapacity\n      currentUsers\n      revenue\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    userID\n    user {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    rating\n    comment\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var input: CreateReviewInput
  public var condition: ModelReviewConditionInput?

  public init(input: CreateReviewInput, condition: ModelReviewConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createReview", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(CreateReview.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createReview: CreateReview? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createReview": createReview.flatMap { $0.snapshot }])
    }

    public var createReview: CreateReview? {
      get {
        return (snapshot["createReview"] as? Snapshot).flatMap { CreateReview(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createReview")
      }
    }

    public struct CreateReview: GraphQLSelectionSet {
      public static let possibleTypes = ["Review"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venue", type: .object(Venue.selections)),
        GraphQLField("userID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("user", type: .object(User.selections)),
        GraphQLField("rating", type: .nonNull(.scalar(Double.self))),
        GraphQLField("comment", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, venueId: GraphQLID, venue: Venue? = nil, userId: GraphQLID, user: User? = nil, rating: Double, comment: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "Review", "id": id, "venueID": venueId, "venue": venue.flatMap { $0.snapshot }, "userID": userId, "user": user.flatMap { $0.snapshot }, "rating": rating, "comment": comment, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var venueId: GraphQLID {
        get {
          return snapshot["venueID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "venueID")
        }
      }

      public var venue: Venue? {
        get {
          return (snapshot["venue"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venue")
        }
      }

      public var userId: GraphQLID {
        get {
          return snapshot["userID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "userID")
        }
      }

      public var user: User? {
        get {
          return (snapshot["user"] as? Snapshot).flatMap { User(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "user")
        }
      }

      public var rating: Double {
        get {
          return snapshot["rating"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "rating")
        }
      }

      public var comment: String {
        get {
          return snapshot["comment"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "comment")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["Venue"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("address", type: .nonNull(.scalar(String.self))),
          GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("rating", type: .scalar(Double.self)),
          GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
          GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("maxCapacity", type: .scalar(Int.self)),
          GraphQLField("currentUsers", type: .scalar(Int.self)),
          GraphQLField("revenue", type: .scalar(Double.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var description: String {
          get {
            return snapshot["description"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var address: String {
          get {
            return snapshot["address"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "address")
          }
        }

        public var latitude: Double {
          get {
            return snapshot["latitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "latitude")
          }
        }

        public var longitude: Double {
          get {
            return snapshot["longitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "longitude")
          }
        }

        public var rating: Double? {
          get {
            return snapshot["rating"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var imageKey: [String]? {
          get {
            return snapshot["imageKey"] as? [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "imageKey")
          }
        }

        public var ownerId: GraphQLID {
          get {
            return snapshot["ownerID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "ownerID")
          }
        }

        public var maxCapacity: Int? {
          get {
            return snapshot["maxCapacity"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxCapacity")
          }
        }

        public var currentUsers: Int? {
          get {
            return snapshot["currentUsers"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "currentUsers")
          }
        }

        public var revenue: Double? {
          get {
            return snapshot["revenue"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "revenue")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct User: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class UpdateReviewMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdateReview($input: UpdateReviewInput!, $condition: ModelReviewConditionInput) {\n  updateReview(input: $input, condition: $condition) {\n    __typename\n    id\n    venueID\n    venue {\n      __typename\n      id\n      name\n      description\n      address\n      latitude\n      longitude\n      rating\n      imageKey\n      ownerID\n      maxCapacity\n      currentUsers\n      revenue\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    userID\n    user {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    rating\n    comment\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var input: UpdateReviewInput
  public var condition: ModelReviewConditionInput?

  public init(input: UpdateReviewInput, condition: ModelReviewConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updateReview", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(UpdateReview.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updateReview: UpdateReview? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updateReview": updateReview.flatMap { $0.snapshot }])
    }

    public var updateReview: UpdateReview? {
      get {
        return (snapshot["updateReview"] as? Snapshot).flatMap { UpdateReview(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updateReview")
      }
    }

    public struct UpdateReview: GraphQLSelectionSet {
      public static let possibleTypes = ["Review"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venue", type: .object(Venue.selections)),
        GraphQLField("userID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("user", type: .object(User.selections)),
        GraphQLField("rating", type: .nonNull(.scalar(Double.self))),
        GraphQLField("comment", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, venueId: GraphQLID, venue: Venue? = nil, userId: GraphQLID, user: User? = nil, rating: Double, comment: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "Review", "id": id, "venueID": venueId, "venue": venue.flatMap { $0.snapshot }, "userID": userId, "user": user.flatMap { $0.snapshot }, "rating": rating, "comment": comment, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var venueId: GraphQLID {
        get {
          return snapshot["venueID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "venueID")
        }
      }

      public var venue: Venue? {
        get {
          return (snapshot["venue"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venue")
        }
      }

      public var userId: GraphQLID {
        get {
          return snapshot["userID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "userID")
        }
      }

      public var user: User? {
        get {
          return (snapshot["user"] as? Snapshot).flatMap { User(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "user")
        }
      }

      public var rating: Double {
        get {
          return snapshot["rating"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "rating")
        }
      }

      public var comment: String {
        get {
          return snapshot["comment"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "comment")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["Venue"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("address", type: .nonNull(.scalar(String.self))),
          GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("rating", type: .scalar(Double.self)),
          GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
          GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("maxCapacity", type: .scalar(Int.self)),
          GraphQLField("currentUsers", type: .scalar(Int.self)),
          GraphQLField("revenue", type: .scalar(Double.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var description: String {
          get {
            return snapshot["description"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var address: String {
          get {
            return snapshot["address"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "address")
          }
        }

        public var latitude: Double {
          get {
            return snapshot["latitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "latitude")
          }
        }

        public var longitude: Double {
          get {
            return snapshot["longitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "longitude")
          }
        }

        public var rating: Double? {
          get {
            return snapshot["rating"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var imageKey: [String]? {
          get {
            return snapshot["imageKey"] as? [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "imageKey")
          }
        }

        public var ownerId: GraphQLID {
          get {
            return snapshot["ownerID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "ownerID")
          }
        }

        public var maxCapacity: Int? {
          get {
            return snapshot["maxCapacity"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxCapacity")
          }
        }

        public var currentUsers: Int? {
          get {
            return snapshot["currentUsers"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "currentUsers")
          }
        }

        public var revenue: Double? {
          get {
            return snapshot["revenue"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "revenue")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct User: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class DeleteReviewMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeleteReview($input: DeleteReviewInput!, $condition: ModelReviewConditionInput) {\n  deleteReview(input: $input, condition: $condition) {\n    __typename\n    id\n    venueID\n    venue {\n      __typename\n      id\n      name\n      description\n      address\n      latitude\n      longitude\n      rating\n      imageKey\n      ownerID\n      maxCapacity\n      currentUsers\n      revenue\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    userID\n    user {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    rating\n    comment\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var input: DeleteReviewInput
  public var condition: ModelReviewConditionInput?

  public init(input: DeleteReviewInput, condition: ModelReviewConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deleteReview", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(DeleteReview.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deleteReview: DeleteReview? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteReview": deleteReview.flatMap { $0.snapshot }])
    }

    public var deleteReview: DeleteReview? {
      get {
        return (snapshot["deleteReview"] as? Snapshot).flatMap { DeleteReview(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteReview")
      }
    }

    public struct DeleteReview: GraphQLSelectionSet {
      public static let possibleTypes = ["Review"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venue", type: .object(Venue.selections)),
        GraphQLField("userID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("user", type: .object(User.selections)),
        GraphQLField("rating", type: .nonNull(.scalar(Double.self))),
        GraphQLField("comment", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, venueId: GraphQLID, venue: Venue? = nil, userId: GraphQLID, user: User? = nil, rating: Double, comment: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "Review", "id": id, "venueID": venueId, "venue": venue.flatMap { $0.snapshot }, "userID": userId, "user": user.flatMap { $0.snapshot }, "rating": rating, "comment": comment, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var venueId: GraphQLID {
        get {
          return snapshot["venueID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "venueID")
        }
      }

      public var venue: Venue? {
        get {
          return (snapshot["venue"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venue")
        }
      }

      public var userId: GraphQLID {
        get {
          return snapshot["userID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "userID")
        }
      }

      public var user: User? {
        get {
          return (snapshot["user"] as? Snapshot).flatMap { User(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "user")
        }
      }

      public var rating: Double {
        get {
          return snapshot["rating"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "rating")
        }
      }

      public var comment: String {
        get {
          return snapshot["comment"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "comment")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["Venue"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("address", type: .nonNull(.scalar(String.self))),
          GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("rating", type: .scalar(Double.self)),
          GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
          GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("maxCapacity", type: .scalar(Int.self)),
          GraphQLField("currentUsers", type: .scalar(Int.self)),
          GraphQLField("revenue", type: .scalar(Double.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var description: String {
          get {
            return snapshot["description"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var address: String {
          get {
            return snapshot["address"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "address")
          }
        }

        public var latitude: Double {
          get {
            return snapshot["latitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "latitude")
          }
        }

        public var longitude: Double {
          get {
            return snapshot["longitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "longitude")
          }
        }

        public var rating: Double? {
          get {
            return snapshot["rating"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var imageKey: [String]? {
          get {
            return snapshot["imageKey"] as? [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "imageKey")
          }
        }

        public var ownerId: GraphQLID {
          get {
            return snapshot["ownerID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "ownerID")
          }
        }

        public var maxCapacity: Int? {
          get {
            return snapshot["maxCapacity"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxCapacity")
          }
        }

        public var currentUsers: Int? {
          get {
            return snapshot["currentUsers"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "currentUsers")
          }
        }

        public var revenue: Double? {
          get {
            return snapshot["revenue"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "revenue")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct User: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class CreateChatRoomMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreateChatRoom($input: CreateChatRoomInput!, $condition: ModelChatRoomConditionInput) {\n  createChatRoom(input: $input, condition: $condition) {\n    __typename\n    id\n    name\n    createdAt\n    updatedAt\n    participants {\n      __typename\n      nextToken\n      startedAt\n    }\n    messages {\n      __typename\n      nextToken\n      startedAt\n    }\n    lastMessage\n    lastMessageTimestamp\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var input: CreateChatRoomInput
  public var condition: ModelChatRoomConditionInput?

  public init(input: CreateChatRoomInput, condition: ModelChatRoomConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createChatRoom", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(CreateChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createChatRoom: CreateChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createChatRoom": createChatRoom.flatMap { $0.snapshot }])
    }

    public var createChatRoom: CreateChatRoom? {
      get {
        return (snapshot["createChatRoom"] as? Snapshot).flatMap { CreateChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createChatRoom")
      }
    }

    public struct CreateChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["ChatRoom"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("participants", type: .object(Participant.selections)),
        GraphQLField("messages", type: .object(Message.selections)),
        GraphQLField("lastMessage", type: .scalar(String.self)),
        GraphQLField("lastMessageTimestamp", type: .scalar(String.self)),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String, createdAt: String, updatedAt: String, participants: Participant? = nil, messages: Message? = nil, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "ChatRoom", "id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "participants": participants.flatMap { $0.snapshot }, "messages": messages.flatMap { $0.snapshot }, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var participants: Participant? {
        get {
          return (snapshot["participants"] as? Snapshot).flatMap { Participant(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "participants")
        }
      }

      public var messages: Message? {
        get {
          return (snapshot["messages"] as? Snapshot).flatMap { Message(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "messages")
        }
      }

      public var lastMessage: String? {
        get {
          return snapshot["lastMessage"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "lastMessage")
        }
      }

      public var lastMessageTimestamp: String? {
        get {
          return snapshot["lastMessageTimestamp"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "lastMessageTimestamp")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Participant: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelUserChatRoomsConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Message: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelMessageConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelMessageConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class UpdateChatRoomMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdateChatRoom($input: UpdateChatRoomInput!, $condition: ModelChatRoomConditionInput) {\n  updateChatRoom(input: $input, condition: $condition) {\n    __typename\n    id\n    name\n    createdAt\n    updatedAt\n    participants {\n      __typename\n      nextToken\n      startedAt\n    }\n    messages {\n      __typename\n      nextToken\n      startedAt\n    }\n    lastMessage\n    lastMessageTimestamp\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var input: UpdateChatRoomInput
  public var condition: ModelChatRoomConditionInput?

  public init(input: UpdateChatRoomInput, condition: ModelChatRoomConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updateChatRoom", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(UpdateChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updateChatRoom: UpdateChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updateChatRoom": updateChatRoom.flatMap { $0.snapshot }])
    }

    public var updateChatRoom: UpdateChatRoom? {
      get {
        return (snapshot["updateChatRoom"] as? Snapshot).flatMap { UpdateChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updateChatRoom")
      }
    }

    public struct UpdateChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["ChatRoom"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("participants", type: .object(Participant.selections)),
        GraphQLField("messages", type: .object(Message.selections)),
        GraphQLField("lastMessage", type: .scalar(String.self)),
        GraphQLField("lastMessageTimestamp", type: .scalar(String.self)),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String, createdAt: String, updatedAt: String, participants: Participant? = nil, messages: Message? = nil, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "ChatRoom", "id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "participants": participants.flatMap { $0.snapshot }, "messages": messages.flatMap { $0.snapshot }, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var participants: Participant? {
        get {
          return (snapshot["participants"] as? Snapshot).flatMap { Participant(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "participants")
        }
      }

      public var messages: Message? {
        get {
          return (snapshot["messages"] as? Snapshot).flatMap { Message(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "messages")
        }
      }

      public var lastMessage: String? {
        get {
          return snapshot["lastMessage"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "lastMessage")
        }
      }

      public var lastMessageTimestamp: String? {
        get {
          return snapshot["lastMessageTimestamp"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "lastMessageTimestamp")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Participant: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelUserChatRoomsConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Message: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelMessageConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelMessageConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class DeleteChatRoomMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeleteChatRoom($input: DeleteChatRoomInput!, $condition: ModelChatRoomConditionInput) {\n  deleteChatRoom(input: $input, condition: $condition) {\n    __typename\n    id\n    name\n    createdAt\n    updatedAt\n    participants {\n      __typename\n      nextToken\n      startedAt\n    }\n    messages {\n      __typename\n      nextToken\n      startedAt\n    }\n    lastMessage\n    lastMessageTimestamp\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var input: DeleteChatRoomInput
  public var condition: ModelChatRoomConditionInput?

  public init(input: DeleteChatRoomInput, condition: ModelChatRoomConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deleteChatRoom", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(DeleteChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deleteChatRoom: DeleteChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteChatRoom": deleteChatRoom.flatMap { $0.snapshot }])
    }

    public var deleteChatRoom: DeleteChatRoom? {
      get {
        return (snapshot["deleteChatRoom"] as? Snapshot).flatMap { DeleteChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteChatRoom")
      }
    }

    public struct DeleteChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["ChatRoom"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("participants", type: .object(Participant.selections)),
        GraphQLField("messages", type: .object(Message.selections)),
        GraphQLField("lastMessage", type: .scalar(String.self)),
        GraphQLField("lastMessageTimestamp", type: .scalar(String.self)),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String, createdAt: String, updatedAt: String, participants: Participant? = nil, messages: Message? = nil, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "ChatRoom", "id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "participants": participants.flatMap { $0.snapshot }, "messages": messages.flatMap { $0.snapshot }, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var participants: Participant? {
        get {
          return (snapshot["participants"] as? Snapshot).flatMap { Participant(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "participants")
        }
      }

      public var messages: Message? {
        get {
          return (snapshot["messages"] as? Snapshot).flatMap { Message(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "messages")
        }
      }

      public var lastMessage: String? {
        get {
          return snapshot["lastMessage"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "lastMessage")
        }
      }

      public var lastMessageTimestamp: String? {
        get {
          return snapshot["lastMessageTimestamp"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "lastMessageTimestamp")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Participant: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelUserChatRoomsConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Message: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelMessageConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelMessageConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class CreateMessageMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreateMessage($input: CreateMessageInput!, $condition: ModelMessageConditionInput) {\n  createMessage(input: $input, condition: $condition) {\n    __typename\n    id\n    senderID\n    sender {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    chatRoomID\n    content\n    timestamp\n    isRead\n    readBy\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var input: CreateMessageInput
  public var condition: ModelMessageConditionInput?

  public init(input: CreateMessageInput, condition: ModelMessageConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createMessage", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(CreateMessage.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createMessage: CreateMessage? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createMessage": createMessage.flatMap { $0.snapshot }])
    }

    public var createMessage: CreateMessage? {
      get {
        return (snapshot["createMessage"] as? Snapshot).flatMap { CreateMessage(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createMessage")
      }
    }

    public struct CreateMessage: GraphQLSelectionSet {
      public static let possibleTypes = ["Message"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("senderID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("sender", type: .object(Sender.selections)),
        GraphQLField("chatRoomID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("timestamp", type: .nonNull(.scalar(String.self))),
        GraphQLField("isRead", type: .nonNull(.scalar(Bool.self))),
        GraphQLField("readBy", type: .list(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, senderId: GraphQLID, sender: Sender? = nil, chatRoomId: GraphQLID, content: String, timestamp: String, isRead: Bool, readBy: [String?]? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Message", "id": id, "senderID": senderId, "sender": sender.flatMap { $0.snapshot }, "chatRoomID": chatRoomId, "content": content, "timestamp": timestamp, "isRead": isRead, "readBy": readBy, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var senderId: GraphQLID {
        get {
          return snapshot["senderID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "senderID")
        }
      }

      public var sender: Sender? {
        get {
          return (snapshot["sender"] as? Snapshot).flatMap { Sender(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "sender")
        }
      }

      public var chatRoomId: GraphQLID {
        get {
          return snapshot["chatRoomID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "chatRoomID")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var timestamp: String {
        get {
          return snapshot["timestamp"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "timestamp")
        }
      }

      public var isRead: Bool {
        get {
          return snapshot["isRead"]! as! Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "isRead")
        }
      }

      public var readBy: [String?]? {
        get {
          return snapshot["readBy"] as? [String?]
        }
        set {
          snapshot.updateValue(newValue, forKey: "readBy")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Sender: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class UpdateMessageMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdateMessage($input: UpdateMessageInput!, $condition: ModelMessageConditionInput) {\n  updateMessage(input: $input, condition: $condition) {\n    __typename\n    id\n    senderID\n    sender {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    chatRoomID\n    content\n    timestamp\n    isRead\n    readBy\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var input: UpdateMessageInput
  public var condition: ModelMessageConditionInput?

  public init(input: UpdateMessageInput, condition: ModelMessageConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updateMessage", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(UpdateMessage.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updateMessage: UpdateMessage? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updateMessage": updateMessage.flatMap { $0.snapshot }])
    }

    public var updateMessage: UpdateMessage? {
      get {
        return (snapshot["updateMessage"] as? Snapshot).flatMap { UpdateMessage(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updateMessage")
      }
    }

    public struct UpdateMessage: GraphQLSelectionSet {
      public static let possibleTypes = ["Message"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("senderID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("sender", type: .object(Sender.selections)),
        GraphQLField("chatRoomID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("timestamp", type: .nonNull(.scalar(String.self))),
        GraphQLField("isRead", type: .nonNull(.scalar(Bool.self))),
        GraphQLField("readBy", type: .list(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, senderId: GraphQLID, sender: Sender? = nil, chatRoomId: GraphQLID, content: String, timestamp: String, isRead: Bool, readBy: [String?]? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Message", "id": id, "senderID": senderId, "sender": sender.flatMap { $0.snapshot }, "chatRoomID": chatRoomId, "content": content, "timestamp": timestamp, "isRead": isRead, "readBy": readBy, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var senderId: GraphQLID {
        get {
          return snapshot["senderID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "senderID")
        }
      }

      public var sender: Sender? {
        get {
          return (snapshot["sender"] as? Snapshot).flatMap { Sender(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "sender")
        }
      }

      public var chatRoomId: GraphQLID {
        get {
          return snapshot["chatRoomID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "chatRoomID")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var timestamp: String {
        get {
          return snapshot["timestamp"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "timestamp")
        }
      }

      public var isRead: Bool {
        get {
          return snapshot["isRead"]! as! Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "isRead")
        }
      }

      public var readBy: [String?]? {
        get {
          return snapshot["readBy"] as? [String?]
        }
        set {
          snapshot.updateValue(newValue, forKey: "readBy")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Sender: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class DeleteMessageMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeleteMessage($input: DeleteMessageInput!, $condition: ModelMessageConditionInput) {\n  deleteMessage(input: $input, condition: $condition) {\n    __typename\n    id\n    senderID\n    sender {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    chatRoomID\n    content\n    timestamp\n    isRead\n    readBy\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var input: DeleteMessageInput
  public var condition: ModelMessageConditionInput?

  public init(input: DeleteMessageInput, condition: ModelMessageConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deleteMessage", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(DeleteMessage.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deleteMessage: DeleteMessage? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteMessage": deleteMessage.flatMap { $0.snapshot }])
    }

    public var deleteMessage: DeleteMessage? {
      get {
        return (snapshot["deleteMessage"] as? Snapshot).flatMap { DeleteMessage(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteMessage")
      }
    }

    public struct DeleteMessage: GraphQLSelectionSet {
      public static let possibleTypes = ["Message"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("senderID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("sender", type: .object(Sender.selections)),
        GraphQLField("chatRoomID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("timestamp", type: .nonNull(.scalar(String.self))),
        GraphQLField("isRead", type: .nonNull(.scalar(Bool.self))),
        GraphQLField("readBy", type: .list(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, senderId: GraphQLID, sender: Sender? = nil, chatRoomId: GraphQLID, content: String, timestamp: String, isRead: Bool, readBy: [String?]? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Message", "id": id, "senderID": senderId, "sender": sender.flatMap { $0.snapshot }, "chatRoomID": chatRoomId, "content": content, "timestamp": timestamp, "isRead": isRead, "readBy": readBy, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var senderId: GraphQLID {
        get {
          return snapshot["senderID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "senderID")
        }
      }

      public var sender: Sender? {
        get {
          return (snapshot["sender"] as? Snapshot).flatMap { Sender(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "sender")
        }
      }

      public var chatRoomId: GraphQLID {
        get {
          return snapshot["chatRoomID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "chatRoomID")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var timestamp: String {
        get {
          return snapshot["timestamp"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "timestamp")
        }
      }

      public var isRead: Bool {
        get {
          return snapshot["isRead"]! as! Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "isRead")
        }
      }

      public var readBy: [String?]? {
        get {
          return snapshot["readBy"] as? [String?]
        }
        set {
          snapshot.updateValue(newValue, forKey: "readBy")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Sender: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class CreateUserChatRoomsMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreateUserChatRooms($input: CreateUserChatRoomsInput!, $condition: ModelUserChatRoomsConditionInput) {\n  createUserChatRooms(input: $input, condition: $condition) {\n    __typename\n    id\n    userId\n    chatRoomId\n    user {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    chatRoom {\n      __typename\n      id\n      name\n      createdAt\n      updatedAt\n      lastMessage\n      lastMessageTimestamp\n      _version\n      _deleted\n      _lastChangedAt\n      owner\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var input: CreateUserChatRoomsInput
  public var condition: ModelUserChatRoomsConditionInput?

  public init(input: CreateUserChatRoomsInput, condition: ModelUserChatRoomsConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createUserChatRooms", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(CreateUserChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createUserChatRooms: CreateUserChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createUserChatRooms": createUserChatRooms.flatMap { $0.snapshot }])
    }

    public var createUserChatRooms: CreateUserChatRoom? {
      get {
        return (snapshot["createUserChatRooms"] as? Snapshot).flatMap { CreateUserChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createUserChatRooms")
      }
    }

    public struct CreateUserChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["UserChatRooms"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("userId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("chatRoomId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("user", type: .nonNull(.object(User.selections))),
        GraphQLField("chatRoom", type: .nonNull(.object(ChatRoom.selections))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, userId: GraphQLID, chatRoomId: GraphQLID, user: User, chatRoom: ChatRoom, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "UserChatRooms", "id": id, "userId": userId, "chatRoomId": chatRoomId, "user": user.snapshot, "chatRoom": chatRoom.snapshot, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var userId: GraphQLID {
        get {
          return snapshot["userId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "userId")
        }
      }

      public var chatRoomId: GraphQLID {
        get {
          return snapshot["chatRoomId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "chatRoomId")
        }
      }

      public var user: User {
        get {
          return User(snapshot: snapshot["user"]! as! Snapshot)
        }
        set {
          snapshot.updateValue(newValue.snapshot, forKey: "user")
        }
      }

      public var chatRoom: ChatRoom {
        get {
          return ChatRoom(snapshot: snapshot["chatRoom"]! as! Snapshot)
        }
        set {
          snapshot.updateValue(newValue.snapshot, forKey: "chatRoom")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct User: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct ChatRoom: GraphQLSelectionSet {
        public static let possibleTypes = ["ChatRoom"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("lastMessage", type: .scalar(String.self)),
          GraphQLField("lastMessageTimestamp", type: .scalar(String.self)),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, createdAt: String, updatedAt: String, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
          self.init(snapshot: ["__typename": "ChatRoom", "id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var lastMessage: String? {
          get {
            return snapshot["lastMessage"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessage")
          }
        }

        public var lastMessageTimestamp: String? {
          get {
            return snapshot["lastMessageTimestamp"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessageTimestamp")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class UpdateUserChatRoomsMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdateUserChatRooms($input: UpdateUserChatRoomsInput!, $condition: ModelUserChatRoomsConditionInput) {\n  updateUserChatRooms(input: $input, condition: $condition) {\n    __typename\n    id\n    userId\n    chatRoomId\n    user {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    chatRoom {\n      __typename\n      id\n      name\n      createdAt\n      updatedAt\n      lastMessage\n      lastMessageTimestamp\n      _version\n      _deleted\n      _lastChangedAt\n      owner\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var input: UpdateUserChatRoomsInput
  public var condition: ModelUserChatRoomsConditionInput?

  public init(input: UpdateUserChatRoomsInput, condition: ModelUserChatRoomsConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updateUserChatRooms", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(UpdateUserChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updateUserChatRooms: UpdateUserChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updateUserChatRooms": updateUserChatRooms.flatMap { $0.snapshot }])
    }

    public var updateUserChatRooms: UpdateUserChatRoom? {
      get {
        return (snapshot["updateUserChatRooms"] as? Snapshot).flatMap { UpdateUserChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updateUserChatRooms")
      }
    }

    public struct UpdateUserChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["UserChatRooms"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("userId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("chatRoomId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("user", type: .nonNull(.object(User.selections))),
        GraphQLField("chatRoom", type: .nonNull(.object(ChatRoom.selections))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, userId: GraphQLID, chatRoomId: GraphQLID, user: User, chatRoom: ChatRoom, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "UserChatRooms", "id": id, "userId": userId, "chatRoomId": chatRoomId, "user": user.snapshot, "chatRoom": chatRoom.snapshot, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var userId: GraphQLID {
        get {
          return snapshot["userId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "userId")
        }
      }

      public var chatRoomId: GraphQLID {
        get {
          return snapshot["chatRoomId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "chatRoomId")
        }
      }

      public var user: User {
        get {
          return User(snapshot: snapshot["user"]! as! Snapshot)
        }
        set {
          snapshot.updateValue(newValue.snapshot, forKey: "user")
        }
      }

      public var chatRoom: ChatRoom {
        get {
          return ChatRoom(snapshot: snapshot["chatRoom"]! as! Snapshot)
        }
        set {
          snapshot.updateValue(newValue.snapshot, forKey: "chatRoom")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct User: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct ChatRoom: GraphQLSelectionSet {
        public static let possibleTypes = ["ChatRoom"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("lastMessage", type: .scalar(String.self)),
          GraphQLField("lastMessageTimestamp", type: .scalar(String.self)),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, createdAt: String, updatedAt: String, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
          self.init(snapshot: ["__typename": "ChatRoom", "id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var lastMessage: String? {
          get {
            return snapshot["lastMessage"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessage")
          }
        }

        public var lastMessageTimestamp: String? {
          get {
            return snapshot["lastMessageTimestamp"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessageTimestamp")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class DeleteUserChatRoomsMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeleteUserChatRooms($input: DeleteUserChatRoomsInput!, $condition: ModelUserChatRoomsConditionInput) {\n  deleteUserChatRooms(input: $input, condition: $condition) {\n    __typename\n    id\n    userId\n    chatRoomId\n    user {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    chatRoom {\n      __typename\n      id\n      name\n      createdAt\n      updatedAt\n      lastMessage\n      lastMessageTimestamp\n      _version\n      _deleted\n      _lastChangedAt\n      owner\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var input: DeleteUserChatRoomsInput
  public var condition: ModelUserChatRoomsConditionInput?

  public init(input: DeleteUserChatRoomsInput, condition: ModelUserChatRoomsConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deleteUserChatRooms", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(DeleteUserChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deleteUserChatRooms: DeleteUserChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteUserChatRooms": deleteUserChatRooms.flatMap { $0.snapshot }])
    }

    public var deleteUserChatRooms: DeleteUserChatRoom? {
      get {
        return (snapshot["deleteUserChatRooms"] as? Snapshot).flatMap { DeleteUserChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteUserChatRooms")
      }
    }

    public struct DeleteUserChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["UserChatRooms"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("userId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("chatRoomId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("user", type: .nonNull(.object(User.selections))),
        GraphQLField("chatRoom", type: .nonNull(.object(ChatRoom.selections))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, userId: GraphQLID, chatRoomId: GraphQLID, user: User, chatRoom: ChatRoom, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "UserChatRooms", "id": id, "userId": userId, "chatRoomId": chatRoomId, "user": user.snapshot, "chatRoom": chatRoom.snapshot, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var userId: GraphQLID {
        get {
          return snapshot["userId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "userId")
        }
      }

      public var chatRoomId: GraphQLID {
        get {
          return snapshot["chatRoomId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "chatRoomId")
        }
      }

      public var user: User {
        get {
          return User(snapshot: snapshot["user"]! as! Snapshot)
        }
        set {
          snapshot.updateValue(newValue.snapshot, forKey: "user")
        }
      }

      public var chatRoom: ChatRoom {
        get {
          return ChatRoom(snapshot: snapshot["chatRoom"]! as! Snapshot)
        }
        set {
          snapshot.updateValue(newValue.snapshot, forKey: "chatRoom")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct User: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct ChatRoom: GraphQLSelectionSet {
        public static let possibleTypes = ["ChatRoom"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("lastMessage", type: .scalar(String.self)),
          GraphQLField("lastMessageTimestamp", type: .scalar(String.self)),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, createdAt: String, updatedAt: String, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
          self.init(snapshot: ["__typename": "ChatRoom", "id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var lastMessage: String? {
          get {
            return snapshot["lastMessage"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessage")
          }
        }

        public var lastMessageTimestamp: String? {
          get {
            return snapshot["lastMessageTimestamp"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessageTimestamp")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class GetUserQuery: GraphQLQuery {
  public static let operationString =
    "query GetUser($id: ID!) {\n  getUser(id: $id) {\n    __typename\n    id\n    username\n    messages {\n      __typename\n      nextToken\n      startedAt\n    }\n    chatRoom {\n      __typename\n      nextToken\n      startedAt\n    }\n    venues {\n      __typename\n      nextToken\n      startedAt\n    }\n    review {\n      __typename\n      nextToken\n      startedAt\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var id: GraphQLID

  public init(id: GraphQLID) {
    self.id = id
  }

  public var variables: GraphQLMap? {
    return ["id": id]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getUser", arguments: ["id": GraphQLVariable("id")], type: .object(GetUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getUser: GetUser? = nil) {
      self.init(snapshot: ["__typename": "Query", "getUser": getUser.flatMap { $0.snapshot }])
    }

    public var getUser: GetUser? {
      get {
        return (snapshot["getUser"] as? Snapshot).flatMap { GetUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getUser")
      }
    }

    public struct GetUser: GraphQLSelectionSet {
      public static let possibleTypes = ["User"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("messages", type: .object(Message.selections)),
        GraphQLField("chatRoom", type: .object(ChatRoom.selections)),
        GraphQLField("venues", type: .object(Venue.selections)),
        GraphQLField("review", type: .object(Review.selections)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, username: String, messages: Message? = nil, chatRoom: ChatRoom? = nil, venues: Venue? = nil, review: Review? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "User", "id": id, "username": username, "messages": messages.flatMap { $0.snapshot }, "chatRoom": chatRoom.flatMap { $0.snapshot }, "venues": venues.flatMap { $0.snapshot }, "review": review.flatMap { $0.snapshot }, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var messages: Message? {
        get {
          return (snapshot["messages"] as? Snapshot).flatMap { Message(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "messages")
        }
      }

      public var chatRoom: ChatRoom? {
        get {
          return (snapshot["chatRoom"] as? Snapshot).flatMap { ChatRoom(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "chatRoom")
        }
      }

      public var venues: Venue? {
        get {
          return (snapshot["venues"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venues")
        }
      }

      public var review: Review? {
        get {
          return (snapshot["review"] as? Snapshot).flatMap { Review(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "review")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Message: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelMessageConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelMessageConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct ChatRoom: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelUserChatRoomsConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelVenueConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelVenueConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Review: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelReviewConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelReviewConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class ListUsersQuery: GraphQLQuery {
  public static let operationString =
    "query ListUsers($filter: ModelUserFilterInput, $limit: Int, $nextToken: String) {\n  listUsers(filter: $filter, limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var filter: ModelUserFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(filter: ModelUserFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listUsers", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(ListUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listUsers: ListUser? = nil) {
      self.init(snapshot: ["__typename": "Query", "listUsers": listUsers.flatMap { $0.snapshot }])
    }

    public var listUsers: ListUser? {
      get {
        return (snapshot["listUsers"] as? Snapshot).flatMap { ListUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "listUsers")
      }
    }

    public struct ListUser: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelUserConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelUserConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class SyncUsersQuery: GraphQLQuery {
  public static let operationString =
    "query SyncUsers($filter: ModelUserFilterInput, $limit: Int, $nextToken: String, $lastSync: AWSTimestamp) {\n  syncUsers(\n    filter: $filter\n    limit: $limit\n    nextToken: $nextToken\n    lastSync: $lastSync\n  ) {\n    __typename\n    items {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var filter: ModelUserFilterInput?
  public var limit: Int?
  public var nextToken: String?
  public var lastSync: Int?

  public init(filter: ModelUserFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil, lastSync: Int? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
    self.lastSync = lastSync
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken, "lastSync": lastSync]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("syncUsers", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken"), "lastSync": GraphQLVariable("lastSync")], type: .object(SyncUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(syncUsers: SyncUser? = nil) {
      self.init(snapshot: ["__typename": "Query", "syncUsers": syncUsers.flatMap { $0.snapshot }])
    }

    public var syncUsers: SyncUser? {
      get {
        return (snapshot["syncUsers"] as? Snapshot).flatMap { SyncUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "syncUsers")
      }
    }

    public struct SyncUser: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelUserConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelUserConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class GetVenueQuery: GraphQLQuery {
  public static let operationString =
    "query GetVenue($id: ID!) {\n  getVenue(id: $id) {\n    __typename\n    id\n    name\n    description\n    address\n    latitude\n    longitude\n    rating\n    imageKey\n    ownerID\n    owner {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    maxCapacity\n    currentUsers\n    revenue\n    dailyUserCounts {\n      __typename\n      nextToken\n      startedAt\n    }\n    reviews {\n      __typename\n      nextToken\n      startedAt\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var id: GraphQLID

  public init(id: GraphQLID) {
    self.id = id
  }

  public var variables: GraphQLMap? {
    return ["id": id]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getVenue", arguments: ["id": GraphQLVariable("id")], type: .object(GetVenue.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getVenue: GetVenue? = nil) {
      self.init(snapshot: ["__typename": "Query", "getVenue": getVenue.flatMap { $0.snapshot }])
    }

    public var getVenue: GetVenue? {
      get {
        return (snapshot["getVenue"] as? Snapshot).flatMap { GetVenue(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getVenue")
      }
    }

    public struct GetVenue: GraphQLSelectionSet {
      public static let possibleTypes = ["Venue"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("description", type: .nonNull(.scalar(String.self))),
        GraphQLField("address", type: .nonNull(.scalar(String.self))),
        GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
        GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
        GraphQLField("rating", type: .scalar(Double.self)),
        GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
        GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("owner", type: .object(Owner.selections)),
        GraphQLField("maxCapacity", type: .scalar(Int.self)),
        GraphQLField("currentUsers", type: .scalar(Int.self)),
        GraphQLField("revenue", type: .scalar(Double.self)),
        GraphQLField("dailyUserCounts", type: .object(DailyUserCount.selections)),
        GraphQLField("reviews", type: .object(Review.selections)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, owner: Owner? = nil, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, dailyUserCounts: DailyUserCount? = nil, reviews: Review? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "owner": owner.flatMap { $0.snapshot }, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "dailyUserCounts": dailyUserCounts.flatMap { $0.snapshot }, "reviews": reviews.flatMap { $0.snapshot }, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var description: String {
        get {
          return snapshot["description"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "description")
        }
      }

      public var address: String {
        get {
          return snapshot["address"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "address")
        }
      }

      public var latitude: Double {
        get {
          return snapshot["latitude"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "latitude")
        }
      }

      public var longitude: Double {
        get {
          return snapshot["longitude"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "longitude")
        }
      }

      public var rating: Double? {
        get {
          return snapshot["rating"] as? Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "rating")
        }
      }

      public var imageKey: [String]? {
        get {
          return snapshot["imageKey"] as? [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "imageKey")
        }
      }

      public var ownerId: GraphQLID {
        get {
          return snapshot["ownerID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "ownerID")
        }
      }

      public var owner: Owner? {
        get {
          return (snapshot["owner"] as? Snapshot).flatMap { Owner(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "owner")
        }
      }

      public var maxCapacity: Int? {
        get {
          return snapshot["maxCapacity"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxCapacity")
        }
      }

      public var currentUsers: Int? {
        get {
          return snapshot["currentUsers"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "currentUsers")
        }
      }

      public var revenue: Double? {
        get {
          return snapshot["revenue"] as? Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "revenue")
        }
      }

      public var dailyUserCounts: DailyUserCount? {
        get {
          return (snapshot["dailyUserCounts"] as? Snapshot).flatMap { DailyUserCount(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "dailyUserCounts")
        }
      }

      public var reviews: Review? {
        get {
          return (snapshot["reviews"] as? Snapshot).flatMap { Review(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "reviews")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Owner: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct DailyUserCount: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelDailyUserCountConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelDailyUserCountConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Review: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelReviewConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelReviewConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class ListVenuesQuery: GraphQLQuery {
  public static let operationString =
    "query ListVenues($filter: ModelVenueFilterInput, $limit: Int, $nextToken: String) {\n  listVenues(filter: $filter, limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      id\n      name\n      description\n      address\n      latitude\n      longitude\n      rating\n      imageKey\n      ownerID\n      maxCapacity\n      currentUsers\n      revenue\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var filter: ModelVenueFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(filter: ModelVenueFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listVenues", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(ListVenue.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listVenues: ListVenue? = nil) {
      self.init(snapshot: ["__typename": "Query", "listVenues": listVenues.flatMap { $0.snapshot }])
    }

    public var listVenues: ListVenue? {
      get {
        return (snapshot["listVenues"] as? Snapshot).flatMap { ListVenue(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "listVenues")
      }
    }

    public struct ListVenue: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelVenueConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelVenueConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["Venue"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("address", type: .nonNull(.scalar(String.self))),
          GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("rating", type: .scalar(Double.self)),
          GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
          GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("maxCapacity", type: .scalar(Int.self)),
          GraphQLField("currentUsers", type: .scalar(Int.self)),
          GraphQLField("revenue", type: .scalar(Double.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var description: String {
          get {
            return snapshot["description"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var address: String {
          get {
            return snapshot["address"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "address")
          }
        }

        public var latitude: Double {
          get {
            return snapshot["latitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "latitude")
          }
        }

        public var longitude: Double {
          get {
            return snapshot["longitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "longitude")
          }
        }

        public var rating: Double? {
          get {
            return snapshot["rating"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var imageKey: [String]? {
          get {
            return snapshot["imageKey"] as? [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "imageKey")
          }
        }

        public var ownerId: GraphQLID {
          get {
            return snapshot["ownerID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "ownerID")
          }
        }

        public var maxCapacity: Int? {
          get {
            return snapshot["maxCapacity"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxCapacity")
          }
        }

        public var currentUsers: Int? {
          get {
            return snapshot["currentUsers"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "currentUsers")
          }
        }

        public var revenue: Double? {
          get {
            return snapshot["revenue"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "revenue")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class SyncVenuesQuery: GraphQLQuery {
  public static let operationString =
    "query SyncVenues($filter: ModelVenueFilterInput, $limit: Int, $nextToken: String, $lastSync: AWSTimestamp) {\n  syncVenues(\n    filter: $filter\n    limit: $limit\n    nextToken: $nextToken\n    lastSync: $lastSync\n  ) {\n    __typename\n    items {\n      __typename\n      id\n      name\n      description\n      address\n      latitude\n      longitude\n      rating\n      imageKey\n      ownerID\n      maxCapacity\n      currentUsers\n      revenue\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var filter: ModelVenueFilterInput?
  public var limit: Int?
  public var nextToken: String?
  public var lastSync: Int?

  public init(filter: ModelVenueFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil, lastSync: Int? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
    self.lastSync = lastSync
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken, "lastSync": lastSync]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("syncVenues", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken"), "lastSync": GraphQLVariable("lastSync")], type: .object(SyncVenue.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(syncVenues: SyncVenue? = nil) {
      self.init(snapshot: ["__typename": "Query", "syncVenues": syncVenues.flatMap { $0.snapshot }])
    }

    public var syncVenues: SyncVenue? {
      get {
        return (snapshot["syncVenues"] as? Snapshot).flatMap { SyncVenue(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "syncVenues")
      }
    }

    public struct SyncVenue: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelVenueConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelVenueConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["Venue"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("address", type: .nonNull(.scalar(String.self))),
          GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("rating", type: .scalar(Double.self)),
          GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
          GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("maxCapacity", type: .scalar(Int.self)),
          GraphQLField("currentUsers", type: .scalar(Int.self)),
          GraphQLField("revenue", type: .scalar(Double.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var description: String {
          get {
            return snapshot["description"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var address: String {
          get {
            return snapshot["address"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "address")
          }
        }

        public var latitude: Double {
          get {
            return snapshot["latitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "latitude")
          }
        }

        public var longitude: Double {
          get {
            return snapshot["longitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "longitude")
          }
        }

        public var rating: Double? {
          get {
            return snapshot["rating"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var imageKey: [String]? {
          get {
            return snapshot["imageKey"] as? [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "imageKey")
          }
        }

        public var ownerId: GraphQLID {
          get {
            return snapshot["ownerID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "ownerID")
          }
        }

        public var maxCapacity: Int? {
          get {
            return snapshot["maxCapacity"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxCapacity")
          }
        }

        public var currentUsers: Int? {
          get {
            return snapshot["currentUsers"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "currentUsers")
          }
        }

        public var revenue: Double? {
          get {
            return snapshot["revenue"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "revenue")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class GetDailyUserCountQuery: GraphQLQuery {
  public static let operationString =
    "query GetDailyUserCount($id: ID!) {\n  getDailyUserCount(id: $id) {\n    __typename\n    id\n    venueID\n    venue {\n      __typename\n      id\n      name\n      description\n      address\n      latitude\n      longitude\n      rating\n      imageKey\n      ownerID\n      maxCapacity\n      currentUsers\n      revenue\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    date\n    userCount\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var id: GraphQLID

  public init(id: GraphQLID) {
    self.id = id
  }

  public var variables: GraphQLMap? {
    return ["id": id]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getDailyUserCount", arguments: ["id": GraphQLVariable("id")], type: .object(GetDailyUserCount.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getDailyUserCount: GetDailyUserCount? = nil) {
      self.init(snapshot: ["__typename": "Query", "getDailyUserCount": getDailyUserCount.flatMap { $0.snapshot }])
    }

    public var getDailyUserCount: GetDailyUserCount? {
      get {
        return (snapshot["getDailyUserCount"] as? Snapshot).flatMap { GetDailyUserCount(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getDailyUserCount")
      }
    }

    public struct GetDailyUserCount: GraphQLSelectionSet {
      public static let possibleTypes = ["DailyUserCount"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venue", type: .object(Venue.selections)),
        GraphQLField("date", type: .nonNull(.scalar(String.self))),
        GraphQLField("userCount", type: .scalar(Int.self)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, venueId: GraphQLID, venue: Venue? = nil, date: String, userCount: Int? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "DailyUserCount", "id": id, "venueID": venueId, "venue": venue.flatMap { $0.snapshot }, "date": date, "userCount": userCount, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var venueId: GraphQLID {
        get {
          return snapshot["venueID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "venueID")
        }
      }

      public var venue: Venue? {
        get {
          return (snapshot["venue"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venue")
        }
      }

      public var date: String {
        get {
          return snapshot["date"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "date")
        }
      }

      public var userCount: Int? {
        get {
          return snapshot["userCount"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "userCount")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["Venue"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("address", type: .nonNull(.scalar(String.self))),
          GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("rating", type: .scalar(Double.self)),
          GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
          GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("maxCapacity", type: .scalar(Int.self)),
          GraphQLField("currentUsers", type: .scalar(Int.self)),
          GraphQLField("revenue", type: .scalar(Double.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var description: String {
          get {
            return snapshot["description"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var address: String {
          get {
            return snapshot["address"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "address")
          }
        }

        public var latitude: Double {
          get {
            return snapshot["latitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "latitude")
          }
        }

        public var longitude: Double {
          get {
            return snapshot["longitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "longitude")
          }
        }

        public var rating: Double? {
          get {
            return snapshot["rating"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var imageKey: [String]? {
          get {
            return snapshot["imageKey"] as? [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "imageKey")
          }
        }

        public var ownerId: GraphQLID {
          get {
            return snapshot["ownerID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "ownerID")
          }
        }

        public var maxCapacity: Int? {
          get {
            return snapshot["maxCapacity"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxCapacity")
          }
        }

        public var currentUsers: Int? {
          get {
            return snapshot["currentUsers"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "currentUsers")
          }
        }

        public var revenue: Double? {
          get {
            return snapshot["revenue"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "revenue")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class ListDailyUserCountsQuery: GraphQLQuery {
  public static let operationString =
    "query ListDailyUserCounts($filter: ModelDailyUserCountFilterInput, $limit: Int, $nextToken: String) {\n  listDailyUserCounts(filter: $filter, limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      id\n      venueID\n      date\n      userCount\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var filter: ModelDailyUserCountFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(filter: ModelDailyUserCountFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listDailyUserCounts", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(ListDailyUserCount.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listDailyUserCounts: ListDailyUserCount? = nil) {
      self.init(snapshot: ["__typename": "Query", "listDailyUserCounts": listDailyUserCounts.flatMap { $0.snapshot }])
    }

    public var listDailyUserCounts: ListDailyUserCount? {
      get {
        return (snapshot["listDailyUserCounts"] as? Snapshot).flatMap { ListDailyUserCount(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "listDailyUserCounts")
      }
    }

    public struct ListDailyUserCount: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelDailyUserCountConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelDailyUserCountConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["DailyUserCount"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("date", type: .nonNull(.scalar(String.self))),
          GraphQLField("userCount", type: .scalar(Int.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, venueId: GraphQLID, date: String, userCount: Int? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "DailyUserCount", "id": id, "venueID": venueId, "date": date, "userCount": userCount, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var venueId: GraphQLID {
          get {
            return snapshot["venueID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "venueID")
          }
        }

        public var date: String {
          get {
            return snapshot["date"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "date")
          }
        }

        public var userCount: Int? {
          get {
            return snapshot["userCount"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "userCount")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class SyncDailyUserCountsQuery: GraphQLQuery {
  public static let operationString =
    "query SyncDailyUserCounts($filter: ModelDailyUserCountFilterInput, $limit: Int, $nextToken: String, $lastSync: AWSTimestamp) {\n  syncDailyUserCounts(\n    filter: $filter\n    limit: $limit\n    nextToken: $nextToken\n    lastSync: $lastSync\n  ) {\n    __typename\n    items {\n      __typename\n      id\n      venueID\n      date\n      userCount\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var filter: ModelDailyUserCountFilterInput?
  public var limit: Int?
  public var nextToken: String?
  public var lastSync: Int?

  public init(filter: ModelDailyUserCountFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil, lastSync: Int? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
    self.lastSync = lastSync
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken, "lastSync": lastSync]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("syncDailyUserCounts", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken"), "lastSync": GraphQLVariable("lastSync")], type: .object(SyncDailyUserCount.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(syncDailyUserCounts: SyncDailyUserCount? = nil) {
      self.init(snapshot: ["__typename": "Query", "syncDailyUserCounts": syncDailyUserCounts.flatMap { $0.snapshot }])
    }

    public var syncDailyUserCounts: SyncDailyUserCount? {
      get {
        return (snapshot["syncDailyUserCounts"] as? Snapshot).flatMap { SyncDailyUserCount(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "syncDailyUserCounts")
      }
    }

    public struct SyncDailyUserCount: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelDailyUserCountConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelDailyUserCountConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["DailyUserCount"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("date", type: .nonNull(.scalar(String.self))),
          GraphQLField("userCount", type: .scalar(Int.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, venueId: GraphQLID, date: String, userCount: Int? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "DailyUserCount", "id": id, "venueID": venueId, "date": date, "userCount": userCount, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var venueId: GraphQLID {
          get {
            return snapshot["venueID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "venueID")
          }
        }

        public var date: String {
          get {
            return snapshot["date"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "date")
          }
        }

        public var userCount: Int? {
          get {
            return snapshot["userCount"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "userCount")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class GetReviewQuery: GraphQLQuery {
  public static let operationString =
    "query GetReview($id: ID!) {\n  getReview(id: $id) {\n    __typename\n    id\n    venueID\n    venue {\n      __typename\n      id\n      name\n      description\n      address\n      latitude\n      longitude\n      rating\n      imageKey\n      ownerID\n      maxCapacity\n      currentUsers\n      revenue\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    userID\n    user {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    rating\n    comment\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var id: GraphQLID

  public init(id: GraphQLID) {
    self.id = id
  }

  public var variables: GraphQLMap? {
    return ["id": id]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getReview", arguments: ["id": GraphQLVariable("id")], type: .object(GetReview.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getReview: GetReview? = nil) {
      self.init(snapshot: ["__typename": "Query", "getReview": getReview.flatMap { $0.snapshot }])
    }

    public var getReview: GetReview? {
      get {
        return (snapshot["getReview"] as? Snapshot).flatMap { GetReview(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getReview")
      }
    }

    public struct GetReview: GraphQLSelectionSet {
      public static let possibleTypes = ["Review"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venue", type: .object(Venue.selections)),
        GraphQLField("userID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("user", type: .object(User.selections)),
        GraphQLField("rating", type: .nonNull(.scalar(Double.self))),
        GraphQLField("comment", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, venueId: GraphQLID, venue: Venue? = nil, userId: GraphQLID, user: User? = nil, rating: Double, comment: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "Review", "id": id, "venueID": venueId, "venue": venue.flatMap { $0.snapshot }, "userID": userId, "user": user.flatMap { $0.snapshot }, "rating": rating, "comment": comment, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var venueId: GraphQLID {
        get {
          return snapshot["venueID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "venueID")
        }
      }

      public var venue: Venue? {
        get {
          return (snapshot["venue"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venue")
        }
      }

      public var userId: GraphQLID {
        get {
          return snapshot["userID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "userID")
        }
      }

      public var user: User? {
        get {
          return (snapshot["user"] as? Snapshot).flatMap { User(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "user")
        }
      }

      public var rating: Double {
        get {
          return snapshot["rating"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "rating")
        }
      }

      public var comment: String {
        get {
          return snapshot["comment"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "comment")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["Venue"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("address", type: .nonNull(.scalar(String.self))),
          GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("rating", type: .scalar(Double.self)),
          GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
          GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("maxCapacity", type: .scalar(Int.self)),
          GraphQLField("currentUsers", type: .scalar(Int.self)),
          GraphQLField("revenue", type: .scalar(Double.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var description: String {
          get {
            return snapshot["description"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var address: String {
          get {
            return snapshot["address"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "address")
          }
        }

        public var latitude: Double {
          get {
            return snapshot["latitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "latitude")
          }
        }

        public var longitude: Double {
          get {
            return snapshot["longitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "longitude")
          }
        }

        public var rating: Double? {
          get {
            return snapshot["rating"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var imageKey: [String]? {
          get {
            return snapshot["imageKey"] as? [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "imageKey")
          }
        }

        public var ownerId: GraphQLID {
          get {
            return snapshot["ownerID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "ownerID")
          }
        }

        public var maxCapacity: Int? {
          get {
            return snapshot["maxCapacity"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxCapacity")
          }
        }

        public var currentUsers: Int? {
          get {
            return snapshot["currentUsers"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "currentUsers")
          }
        }

        public var revenue: Double? {
          get {
            return snapshot["revenue"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "revenue")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct User: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class ListReviewsQuery: GraphQLQuery {
  public static let operationString =
    "query ListReviews($filter: ModelReviewFilterInput, $limit: Int, $nextToken: String) {\n  listReviews(filter: $filter, limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      id\n      venueID\n      userID\n      rating\n      comment\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var filter: ModelReviewFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(filter: ModelReviewFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listReviews", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(ListReview.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listReviews: ListReview? = nil) {
      self.init(snapshot: ["__typename": "Query", "listReviews": listReviews.flatMap { $0.snapshot }])
    }

    public var listReviews: ListReview? {
      get {
        return (snapshot["listReviews"] as? Snapshot).flatMap { ListReview(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "listReviews")
      }
    }

    public struct ListReview: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelReviewConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelReviewConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["Review"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("userID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("rating", type: .nonNull(.scalar(Double.self))),
          GraphQLField("comment", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, venueId: GraphQLID, userId: GraphQLID, rating: Double, comment: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Review", "id": id, "venueID": venueId, "userID": userId, "rating": rating, "comment": comment, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var venueId: GraphQLID {
          get {
            return snapshot["venueID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "venueID")
          }
        }

        public var userId: GraphQLID {
          get {
            return snapshot["userID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "userID")
          }
        }

        public var rating: Double {
          get {
            return snapshot["rating"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var comment: String {
          get {
            return snapshot["comment"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "comment")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class SyncReviewsQuery: GraphQLQuery {
  public static let operationString =
    "query SyncReviews($filter: ModelReviewFilterInput, $limit: Int, $nextToken: String, $lastSync: AWSTimestamp) {\n  syncReviews(\n    filter: $filter\n    limit: $limit\n    nextToken: $nextToken\n    lastSync: $lastSync\n  ) {\n    __typename\n    items {\n      __typename\n      id\n      venueID\n      userID\n      rating\n      comment\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var filter: ModelReviewFilterInput?
  public var limit: Int?
  public var nextToken: String?
  public var lastSync: Int?

  public init(filter: ModelReviewFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil, lastSync: Int? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
    self.lastSync = lastSync
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken, "lastSync": lastSync]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("syncReviews", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken"), "lastSync": GraphQLVariable("lastSync")], type: .object(SyncReview.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(syncReviews: SyncReview? = nil) {
      self.init(snapshot: ["__typename": "Query", "syncReviews": syncReviews.flatMap { $0.snapshot }])
    }

    public var syncReviews: SyncReview? {
      get {
        return (snapshot["syncReviews"] as? Snapshot).flatMap { SyncReview(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "syncReviews")
      }
    }

    public struct SyncReview: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelReviewConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelReviewConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["Review"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("userID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("rating", type: .nonNull(.scalar(Double.self))),
          GraphQLField("comment", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, venueId: GraphQLID, userId: GraphQLID, rating: Double, comment: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Review", "id": id, "venueID": venueId, "userID": userId, "rating": rating, "comment": comment, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var venueId: GraphQLID {
          get {
            return snapshot["venueID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "venueID")
          }
        }

        public var userId: GraphQLID {
          get {
            return snapshot["userID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "userID")
          }
        }

        public var rating: Double {
          get {
            return snapshot["rating"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var comment: String {
          get {
            return snapshot["comment"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "comment")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class GetChatRoomQuery: GraphQLQuery {
  public static let operationString =
    "query GetChatRoom($id: ID!) {\n  getChatRoom(id: $id) {\n    __typename\n    id\n    name\n    createdAt\n    updatedAt\n    participants {\n      __typename\n      nextToken\n      startedAt\n    }\n    messages {\n      __typename\n      nextToken\n      startedAt\n    }\n    lastMessage\n    lastMessageTimestamp\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var id: GraphQLID

  public init(id: GraphQLID) {
    self.id = id
  }

  public var variables: GraphQLMap? {
    return ["id": id]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getChatRoom", arguments: ["id": GraphQLVariable("id")], type: .object(GetChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getChatRoom: GetChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Query", "getChatRoom": getChatRoom.flatMap { $0.snapshot }])
    }

    public var getChatRoom: GetChatRoom? {
      get {
        return (snapshot["getChatRoom"] as? Snapshot).flatMap { GetChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getChatRoom")
      }
    }

    public struct GetChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["ChatRoom"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("participants", type: .object(Participant.selections)),
        GraphQLField("messages", type: .object(Message.selections)),
        GraphQLField("lastMessage", type: .scalar(String.self)),
        GraphQLField("lastMessageTimestamp", type: .scalar(String.self)),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String, createdAt: String, updatedAt: String, participants: Participant? = nil, messages: Message? = nil, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "ChatRoom", "id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "participants": participants.flatMap { $0.snapshot }, "messages": messages.flatMap { $0.snapshot }, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var participants: Participant? {
        get {
          return (snapshot["participants"] as? Snapshot).flatMap { Participant(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "participants")
        }
      }

      public var messages: Message? {
        get {
          return (snapshot["messages"] as? Snapshot).flatMap { Message(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "messages")
        }
      }

      public var lastMessage: String? {
        get {
          return snapshot["lastMessage"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "lastMessage")
        }
      }

      public var lastMessageTimestamp: String? {
        get {
          return snapshot["lastMessageTimestamp"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "lastMessageTimestamp")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Participant: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelUserChatRoomsConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Message: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelMessageConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelMessageConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class ListChatRoomsQuery: GraphQLQuery {
  public static let operationString =
    "query ListChatRooms($filter: ModelChatRoomFilterInput, $limit: Int, $nextToken: String) {\n  listChatRooms(filter: $filter, limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      id\n      name\n      createdAt\n      updatedAt\n      lastMessage\n      lastMessageTimestamp\n      _version\n      _deleted\n      _lastChangedAt\n      owner\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var filter: ModelChatRoomFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(filter: ModelChatRoomFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listChatRooms", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(ListChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listChatRooms: ListChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Query", "listChatRooms": listChatRooms.flatMap { $0.snapshot }])
    }

    public var listChatRooms: ListChatRoom? {
      get {
        return (snapshot["listChatRooms"] as? Snapshot).flatMap { ListChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "listChatRooms")
      }
    }

    public struct ListChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelChatRoomConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelChatRoomConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["ChatRoom"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("lastMessage", type: .scalar(String.self)),
          GraphQLField("lastMessageTimestamp", type: .scalar(String.self)),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, createdAt: String, updatedAt: String, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
          self.init(snapshot: ["__typename": "ChatRoom", "id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var lastMessage: String? {
          get {
            return snapshot["lastMessage"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessage")
          }
        }

        public var lastMessageTimestamp: String? {
          get {
            return snapshot["lastMessageTimestamp"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessageTimestamp")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class SyncChatRoomsQuery: GraphQLQuery {
  public static let operationString =
    "query SyncChatRooms($filter: ModelChatRoomFilterInput, $limit: Int, $nextToken: String, $lastSync: AWSTimestamp) {\n  syncChatRooms(\n    filter: $filter\n    limit: $limit\n    nextToken: $nextToken\n    lastSync: $lastSync\n  ) {\n    __typename\n    items {\n      __typename\n      id\n      name\n      createdAt\n      updatedAt\n      lastMessage\n      lastMessageTimestamp\n      _version\n      _deleted\n      _lastChangedAt\n      owner\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var filter: ModelChatRoomFilterInput?
  public var limit: Int?
  public var nextToken: String?
  public var lastSync: Int?

  public init(filter: ModelChatRoomFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil, lastSync: Int? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
    self.lastSync = lastSync
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken, "lastSync": lastSync]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("syncChatRooms", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken"), "lastSync": GraphQLVariable("lastSync")], type: .object(SyncChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(syncChatRooms: SyncChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Query", "syncChatRooms": syncChatRooms.flatMap { $0.snapshot }])
    }

    public var syncChatRooms: SyncChatRoom? {
      get {
        return (snapshot["syncChatRooms"] as? Snapshot).flatMap { SyncChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "syncChatRooms")
      }
    }

    public struct SyncChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelChatRoomConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelChatRoomConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["ChatRoom"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("lastMessage", type: .scalar(String.self)),
          GraphQLField("lastMessageTimestamp", type: .scalar(String.self)),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, createdAt: String, updatedAt: String, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
          self.init(snapshot: ["__typename": "ChatRoom", "id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var lastMessage: String? {
          get {
            return snapshot["lastMessage"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessage")
          }
        }

        public var lastMessageTimestamp: String? {
          get {
            return snapshot["lastMessageTimestamp"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessageTimestamp")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class GetMessageQuery: GraphQLQuery {
  public static let operationString =
    "query GetMessage($id: ID!) {\n  getMessage(id: $id) {\n    __typename\n    id\n    senderID\n    sender {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    chatRoomID\n    content\n    timestamp\n    isRead\n    readBy\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var id: GraphQLID

  public init(id: GraphQLID) {
    self.id = id
  }

  public var variables: GraphQLMap? {
    return ["id": id]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getMessage", arguments: ["id": GraphQLVariable("id")], type: .object(GetMessage.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getMessage: GetMessage? = nil) {
      self.init(snapshot: ["__typename": "Query", "getMessage": getMessage.flatMap { $0.snapshot }])
    }

    public var getMessage: GetMessage? {
      get {
        return (snapshot["getMessage"] as? Snapshot).flatMap { GetMessage(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getMessage")
      }
    }

    public struct GetMessage: GraphQLSelectionSet {
      public static let possibleTypes = ["Message"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("senderID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("sender", type: .object(Sender.selections)),
        GraphQLField("chatRoomID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("timestamp", type: .nonNull(.scalar(String.self))),
        GraphQLField("isRead", type: .nonNull(.scalar(Bool.self))),
        GraphQLField("readBy", type: .list(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, senderId: GraphQLID, sender: Sender? = nil, chatRoomId: GraphQLID, content: String, timestamp: String, isRead: Bool, readBy: [String?]? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Message", "id": id, "senderID": senderId, "sender": sender.flatMap { $0.snapshot }, "chatRoomID": chatRoomId, "content": content, "timestamp": timestamp, "isRead": isRead, "readBy": readBy, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var senderId: GraphQLID {
        get {
          return snapshot["senderID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "senderID")
        }
      }

      public var sender: Sender? {
        get {
          return (snapshot["sender"] as? Snapshot).flatMap { Sender(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "sender")
        }
      }

      public var chatRoomId: GraphQLID {
        get {
          return snapshot["chatRoomID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "chatRoomID")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var timestamp: String {
        get {
          return snapshot["timestamp"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "timestamp")
        }
      }

      public var isRead: Bool {
        get {
          return snapshot["isRead"]! as! Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "isRead")
        }
      }

      public var readBy: [String?]? {
        get {
          return snapshot["readBy"] as? [String?]
        }
        set {
          snapshot.updateValue(newValue, forKey: "readBy")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Sender: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class ListMessagesQuery: GraphQLQuery {
  public static let operationString =
    "query ListMessages($filter: ModelMessageFilterInput, $limit: Int, $nextToken: String) {\n  listMessages(filter: $filter, limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      id\n      senderID\n      chatRoomID\n      content\n      timestamp\n      isRead\n      readBy\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n      owner\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var filter: ModelMessageFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(filter: ModelMessageFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listMessages", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(ListMessage.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listMessages: ListMessage? = nil) {
      self.init(snapshot: ["__typename": "Query", "listMessages": listMessages.flatMap { $0.snapshot }])
    }

    public var listMessages: ListMessage? {
      get {
        return (snapshot["listMessages"] as? Snapshot).flatMap { ListMessage(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "listMessages")
      }
    }

    public struct ListMessage: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelMessageConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelMessageConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["Message"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("senderID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("chatRoomID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("content", type: .nonNull(.scalar(String.self))),
          GraphQLField("timestamp", type: .nonNull(.scalar(String.self))),
          GraphQLField("isRead", type: .nonNull(.scalar(Bool.self))),
          GraphQLField("readBy", type: .list(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, senderId: GraphQLID, chatRoomId: GraphQLID, content: String, timestamp: String, isRead: Bool, readBy: [String?]? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
          self.init(snapshot: ["__typename": "Message", "id": id, "senderID": senderId, "chatRoomID": chatRoomId, "content": content, "timestamp": timestamp, "isRead": isRead, "readBy": readBy, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var senderId: GraphQLID {
          get {
            return snapshot["senderID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "senderID")
          }
        }

        public var chatRoomId: GraphQLID {
          get {
            return snapshot["chatRoomID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "chatRoomID")
          }
        }

        public var content: String {
          get {
            return snapshot["content"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "content")
          }
        }

        public var timestamp: String {
          get {
            return snapshot["timestamp"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "timestamp")
          }
        }

        public var isRead: Bool {
          get {
            return snapshot["isRead"]! as! Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "isRead")
          }
        }

        public var readBy: [String?]? {
          get {
            return snapshot["readBy"] as? [String?]
          }
          set {
            snapshot.updateValue(newValue, forKey: "readBy")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class SyncMessagesQuery: GraphQLQuery {
  public static let operationString =
    "query SyncMessages($filter: ModelMessageFilterInput, $limit: Int, $nextToken: String, $lastSync: AWSTimestamp) {\n  syncMessages(\n    filter: $filter\n    limit: $limit\n    nextToken: $nextToken\n    lastSync: $lastSync\n  ) {\n    __typename\n    items {\n      __typename\n      id\n      senderID\n      chatRoomID\n      content\n      timestamp\n      isRead\n      readBy\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n      owner\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var filter: ModelMessageFilterInput?
  public var limit: Int?
  public var nextToken: String?
  public var lastSync: Int?

  public init(filter: ModelMessageFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil, lastSync: Int? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
    self.lastSync = lastSync
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken, "lastSync": lastSync]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("syncMessages", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken"), "lastSync": GraphQLVariable("lastSync")], type: .object(SyncMessage.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(syncMessages: SyncMessage? = nil) {
      self.init(snapshot: ["__typename": "Query", "syncMessages": syncMessages.flatMap { $0.snapshot }])
    }

    public var syncMessages: SyncMessage? {
      get {
        return (snapshot["syncMessages"] as? Snapshot).flatMap { SyncMessage(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "syncMessages")
      }
    }

    public struct SyncMessage: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelMessageConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelMessageConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["Message"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("senderID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("chatRoomID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("content", type: .nonNull(.scalar(String.self))),
          GraphQLField("timestamp", type: .nonNull(.scalar(String.self))),
          GraphQLField("isRead", type: .nonNull(.scalar(Bool.self))),
          GraphQLField("readBy", type: .list(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, senderId: GraphQLID, chatRoomId: GraphQLID, content: String, timestamp: String, isRead: Bool, readBy: [String?]? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
          self.init(snapshot: ["__typename": "Message", "id": id, "senderID": senderId, "chatRoomID": chatRoomId, "content": content, "timestamp": timestamp, "isRead": isRead, "readBy": readBy, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var senderId: GraphQLID {
          get {
            return snapshot["senderID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "senderID")
          }
        }

        public var chatRoomId: GraphQLID {
          get {
            return snapshot["chatRoomID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "chatRoomID")
          }
        }

        public var content: String {
          get {
            return snapshot["content"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "content")
          }
        }

        public var timestamp: String {
          get {
            return snapshot["timestamp"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "timestamp")
          }
        }

        public var isRead: Bool {
          get {
            return snapshot["isRead"]! as! Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "isRead")
          }
        }

        public var readBy: [String?]? {
          get {
            return snapshot["readBy"] as? [String?]
          }
          set {
            snapshot.updateValue(newValue, forKey: "readBy")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class GetUserChatRoomsQuery: GraphQLQuery {
  public static let operationString =
    "query GetUserChatRooms($id: ID!) {\n  getUserChatRooms(id: $id) {\n    __typename\n    id\n    userId\n    chatRoomId\n    user {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    chatRoom {\n      __typename\n      id\n      name\n      createdAt\n      updatedAt\n      lastMessage\n      lastMessageTimestamp\n      _version\n      _deleted\n      _lastChangedAt\n      owner\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var id: GraphQLID

  public init(id: GraphQLID) {
    self.id = id
  }

  public var variables: GraphQLMap? {
    return ["id": id]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getUserChatRooms", arguments: ["id": GraphQLVariable("id")], type: .object(GetUserChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getUserChatRooms: GetUserChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Query", "getUserChatRooms": getUserChatRooms.flatMap { $0.snapshot }])
    }

    public var getUserChatRooms: GetUserChatRoom? {
      get {
        return (snapshot["getUserChatRooms"] as? Snapshot).flatMap { GetUserChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getUserChatRooms")
      }
    }

    public struct GetUserChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["UserChatRooms"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("userId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("chatRoomId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("user", type: .nonNull(.object(User.selections))),
        GraphQLField("chatRoom", type: .nonNull(.object(ChatRoom.selections))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, userId: GraphQLID, chatRoomId: GraphQLID, user: User, chatRoom: ChatRoom, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "UserChatRooms", "id": id, "userId": userId, "chatRoomId": chatRoomId, "user": user.snapshot, "chatRoom": chatRoom.snapshot, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var userId: GraphQLID {
        get {
          return snapshot["userId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "userId")
        }
      }

      public var chatRoomId: GraphQLID {
        get {
          return snapshot["chatRoomId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "chatRoomId")
        }
      }

      public var user: User {
        get {
          return User(snapshot: snapshot["user"]! as! Snapshot)
        }
        set {
          snapshot.updateValue(newValue.snapshot, forKey: "user")
        }
      }

      public var chatRoom: ChatRoom {
        get {
          return ChatRoom(snapshot: snapshot["chatRoom"]! as! Snapshot)
        }
        set {
          snapshot.updateValue(newValue.snapshot, forKey: "chatRoom")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct User: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct ChatRoom: GraphQLSelectionSet {
        public static let possibleTypes = ["ChatRoom"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("lastMessage", type: .scalar(String.self)),
          GraphQLField("lastMessageTimestamp", type: .scalar(String.self)),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, createdAt: String, updatedAt: String, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
          self.init(snapshot: ["__typename": "ChatRoom", "id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var lastMessage: String? {
          get {
            return snapshot["lastMessage"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessage")
          }
        }

        public var lastMessageTimestamp: String? {
          get {
            return snapshot["lastMessageTimestamp"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessageTimestamp")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class ListUserChatRoomsQuery: GraphQLQuery {
  public static let operationString =
    "query ListUserChatRooms($filter: ModelUserChatRoomsFilterInput, $limit: Int, $nextToken: String) {\n  listUserChatRooms(filter: $filter, limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      id\n      userId\n      chatRoomId\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n      owner\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var filter: ModelUserChatRoomsFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(filter: ModelUserChatRoomsFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listUserChatRooms", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(ListUserChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listUserChatRooms: ListUserChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Query", "listUserChatRooms": listUserChatRooms.flatMap { $0.snapshot }])
    }

    public var listUserChatRooms: ListUserChatRoom? {
      get {
        return (snapshot["listUserChatRooms"] as? Snapshot).flatMap { ListUserChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "listUserChatRooms")
      }
    }

    public struct ListUserChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelUserChatRoomsConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["UserChatRooms"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("userId", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("chatRoomId", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, userId: GraphQLID, chatRoomId: GraphQLID, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
          self.init(snapshot: ["__typename": "UserChatRooms", "id": id, "userId": userId, "chatRoomId": chatRoomId, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var userId: GraphQLID {
          get {
            return snapshot["userId"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "userId")
          }
        }

        public var chatRoomId: GraphQLID {
          get {
            return snapshot["chatRoomId"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "chatRoomId")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class SyncUserChatRoomsQuery: GraphQLQuery {
  public static let operationString =
    "query SyncUserChatRooms($filter: ModelUserChatRoomsFilterInput, $limit: Int, $nextToken: String, $lastSync: AWSTimestamp) {\n  syncUserChatRooms(\n    filter: $filter\n    limit: $limit\n    nextToken: $nextToken\n    lastSync: $lastSync\n  ) {\n    __typename\n    items {\n      __typename\n      id\n      userId\n      chatRoomId\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n      owner\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var filter: ModelUserChatRoomsFilterInput?
  public var limit: Int?
  public var nextToken: String?
  public var lastSync: Int?

  public init(filter: ModelUserChatRoomsFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil, lastSync: Int? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
    self.lastSync = lastSync
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken, "lastSync": lastSync]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("syncUserChatRooms", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken"), "lastSync": GraphQLVariable("lastSync")], type: .object(SyncUserChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(syncUserChatRooms: SyncUserChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Query", "syncUserChatRooms": syncUserChatRooms.flatMap { $0.snapshot }])
    }

    public var syncUserChatRooms: SyncUserChatRoom? {
      get {
        return (snapshot["syncUserChatRooms"] as? Snapshot).flatMap { SyncUserChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "syncUserChatRooms")
      }
    }

    public struct SyncUserChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelUserChatRoomsConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["UserChatRooms"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("userId", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("chatRoomId", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, userId: GraphQLID, chatRoomId: GraphQLID, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
          self.init(snapshot: ["__typename": "UserChatRooms", "id": id, "userId": userId, "chatRoomId": chatRoomId, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var userId: GraphQLID {
          get {
            return snapshot["userId"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "userId")
          }
        }

        public var chatRoomId: GraphQLID {
          get {
            return snapshot["chatRoomId"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "chatRoomId")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class DailyUserCountsByVenueIdAndDateQuery: GraphQLQuery {
  public static let operationString =
    "query DailyUserCountsByVenueIDAndDate($venueID: ID!, $date: ModelStringKeyConditionInput, $sortDirection: ModelSortDirection, $filter: ModelDailyUserCountFilterInput, $limit: Int, $nextToken: String) {\n  dailyUserCountsByVenueIDAndDate(\n    venueID: $venueID\n    date: $date\n    sortDirection: $sortDirection\n    filter: $filter\n    limit: $limit\n    nextToken: $nextToken\n  ) {\n    __typename\n    items {\n      __typename\n      id\n      venueID\n      date\n      userCount\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var venueID: GraphQLID
  public var date: ModelStringKeyConditionInput?
  public var sortDirection: ModelSortDirection?
  public var filter: ModelDailyUserCountFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(venueID: GraphQLID, date: ModelStringKeyConditionInput? = nil, sortDirection: ModelSortDirection? = nil, filter: ModelDailyUserCountFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.venueID = venueID
    self.date = date
    self.sortDirection = sortDirection
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["venueID": venueID, "date": date, "sortDirection": sortDirection, "filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("dailyUserCountsByVenueIDAndDate", arguments: ["venueID": GraphQLVariable("venueID"), "date": GraphQLVariable("date"), "sortDirection": GraphQLVariable("sortDirection"), "filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(DailyUserCountsByVenueIdAndDate.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(dailyUserCountsByVenueIdAndDate: DailyUserCountsByVenueIdAndDate? = nil) {
      self.init(snapshot: ["__typename": "Query", "dailyUserCountsByVenueIDAndDate": dailyUserCountsByVenueIdAndDate.flatMap { $0.snapshot }])
    }

    public var dailyUserCountsByVenueIdAndDate: DailyUserCountsByVenueIdAndDate? {
      get {
        return (snapshot["dailyUserCountsByVenueIDAndDate"] as? Snapshot).flatMap { DailyUserCountsByVenueIdAndDate(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "dailyUserCountsByVenueIDAndDate")
      }
    }

    public struct DailyUserCountsByVenueIdAndDate: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelDailyUserCountConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelDailyUserCountConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["DailyUserCount"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("date", type: .nonNull(.scalar(String.self))),
          GraphQLField("userCount", type: .scalar(Int.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, venueId: GraphQLID, date: String, userCount: Int? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "DailyUserCount", "id": id, "venueID": venueId, "date": date, "userCount": userCount, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var venueId: GraphQLID {
          get {
            return snapshot["venueID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "venueID")
          }
        }

        public var date: String {
          get {
            return snapshot["date"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "date")
          }
        }

        public var userCount: Int? {
          get {
            return snapshot["userCount"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "userCount")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class MessagesByChatRoomIdAndTimestampQuery: GraphQLQuery {
  public static let operationString =
    "query MessagesByChatRoomIDAndTimestamp($chatRoomID: ID!, $timestamp: ModelStringKeyConditionInput, $sortDirection: ModelSortDirection, $filter: ModelMessageFilterInput, $limit: Int, $nextToken: String) {\n  messagesByChatRoomIDAndTimestamp(\n    chatRoomID: $chatRoomID\n    timestamp: $timestamp\n    sortDirection: $sortDirection\n    filter: $filter\n    limit: $limit\n    nextToken: $nextToken\n  ) {\n    __typename\n    items {\n      __typename\n      id\n      senderID\n      chatRoomID\n      content\n      timestamp\n      isRead\n      readBy\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n      owner\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var chatRoomID: GraphQLID
  public var timestamp: ModelStringKeyConditionInput?
  public var sortDirection: ModelSortDirection?
  public var filter: ModelMessageFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(chatRoomID: GraphQLID, timestamp: ModelStringKeyConditionInput? = nil, sortDirection: ModelSortDirection? = nil, filter: ModelMessageFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.chatRoomID = chatRoomID
    self.timestamp = timestamp
    self.sortDirection = sortDirection
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["chatRoomID": chatRoomID, "timestamp": timestamp, "sortDirection": sortDirection, "filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("messagesByChatRoomIDAndTimestamp", arguments: ["chatRoomID": GraphQLVariable("chatRoomID"), "timestamp": GraphQLVariable("timestamp"), "sortDirection": GraphQLVariable("sortDirection"), "filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(MessagesByChatRoomIdAndTimestamp.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(messagesByChatRoomIdAndTimestamp: MessagesByChatRoomIdAndTimestamp? = nil) {
      self.init(snapshot: ["__typename": "Query", "messagesByChatRoomIDAndTimestamp": messagesByChatRoomIdAndTimestamp.flatMap { $0.snapshot }])
    }

    public var messagesByChatRoomIdAndTimestamp: MessagesByChatRoomIdAndTimestamp? {
      get {
        return (snapshot["messagesByChatRoomIDAndTimestamp"] as? Snapshot).flatMap { MessagesByChatRoomIdAndTimestamp(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "messagesByChatRoomIDAndTimestamp")
      }
    }

    public struct MessagesByChatRoomIdAndTimestamp: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelMessageConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelMessageConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["Message"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("senderID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("chatRoomID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("content", type: .nonNull(.scalar(String.self))),
          GraphQLField("timestamp", type: .nonNull(.scalar(String.self))),
          GraphQLField("isRead", type: .nonNull(.scalar(Bool.self))),
          GraphQLField("readBy", type: .list(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, senderId: GraphQLID, chatRoomId: GraphQLID, content: String, timestamp: String, isRead: Bool, readBy: [String?]? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
          self.init(snapshot: ["__typename": "Message", "id": id, "senderID": senderId, "chatRoomID": chatRoomId, "content": content, "timestamp": timestamp, "isRead": isRead, "readBy": readBy, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var senderId: GraphQLID {
          get {
            return snapshot["senderID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "senderID")
          }
        }

        public var chatRoomId: GraphQLID {
          get {
            return snapshot["chatRoomID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "chatRoomID")
          }
        }

        public var content: String {
          get {
            return snapshot["content"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "content")
          }
        }

        public var timestamp: String {
          get {
            return snapshot["timestamp"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "timestamp")
          }
        }

        public var isRead: Bool {
          get {
            return snapshot["isRead"]! as! Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "isRead")
          }
        }

        public var readBy: [String?]? {
          get {
            return snapshot["readBy"] as? [String?]
          }
          set {
            snapshot.updateValue(newValue, forKey: "readBy")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class UserChatRoomsByUserIdQuery: GraphQLQuery {
  public static let operationString =
    "query UserChatRoomsByUserId($userId: ID!, $sortDirection: ModelSortDirection, $filter: ModelUserChatRoomsFilterInput, $limit: Int, $nextToken: String) {\n  userChatRoomsByUserId(\n    userId: $userId\n    sortDirection: $sortDirection\n    filter: $filter\n    limit: $limit\n    nextToken: $nextToken\n  ) {\n    __typename\n    items {\n      __typename\n      id\n      userId\n      chatRoomId\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n      owner\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var userId: GraphQLID
  public var sortDirection: ModelSortDirection?
  public var filter: ModelUserChatRoomsFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(userId: GraphQLID, sortDirection: ModelSortDirection? = nil, filter: ModelUserChatRoomsFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.userId = userId
    self.sortDirection = sortDirection
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["userId": userId, "sortDirection": sortDirection, "filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("userChatRoomsByUserId", arguments: ["userId": GraphQLVariable("userId"), "sortDirection": GraphQLVariable("sortDirection"), "filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(UserChatRoomsByUserId.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(userChatRoomsByUserId: UserChatRoomsByUserId? = nil) {
      self.init(snapshot: ["__typename": "Query", "userChatRoomsByUserId": userChatRoomsByUserId.flatMap { $0.snapshot }])
    }

    public var userChatRoomsByUserId: UserChatRoomsByUserId? {
      get {
        return (snapshot["userChatRoomsByUserId"] as? Snapshot).flatMap { UserChatRoomsByUserId(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "userChatRoomsByUserId")
      }
    }

    public struct UserChatRoomsByUserId: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelUserChatRoomsConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["UserChatRooms"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("userId", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("chatRoomId", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, userId: GraphQLID, chatRoomId: GraphQLID, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
          self.init(snapshot: ["__typename": "UserChatRooms", "id": id, "userId": userId, "chatRoomId": chatRoomId, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var userId: GraphQLID {
          get {
            return snapshot["userId"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "userId")
          }
        }

        public var chatRoomId: GraphQLID {
          get {
            return snapshot["chatRoomId"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "chatRoomId")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class UserChatRoomsByChatRoomIdQuery: GraphQLQuery {
  public static let operationString =
    "query UserChatRoomsByChatRoomId($chatRoomId: ID!, $sortDirection: ModelSortDirection, $filter: ModelUserChatRoomsFilterInput, $limit: Int, $nextToken: String) {\n  userChatRoomsByChatRoomId(\n    chatRoomId: $chatRoomId\n    sortDirection: $sortDirection\n    filter: $filter\n    limit: $limit\n    nextToken: $nextToken\n  ) {\n    __typename\n    items {\n      __typename\n      id\n      userId\n      chatRoomId\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n      owner\n    }\n    nextToken\n    startedAt\n  }\n}"

  public var chatRoomId: GraphQLID
  public var sortDirection: ModelSortDirection?
  public var filter: ModelUserChatRoomsFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(chatRoomId: GraphQLID, sortDirection: ModelSortDirection? = nil, filter: ModelUserChatRoomsFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.chatRoomId = chatRoomId
    self.sortDirection = sortDirection
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["chatRoomId": chatRoomId, "sortDirection": sortDirection, "filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("userChatRoomsByChatRoomId", arguments: ["chatRoomId": GraphQLVariable("chatRoomId"), "sortDirection": GraphQLVariable("sortDirection"), "filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(UserChatRoomsByChatRoomId.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(userChatRoomsByChatRoomId: UserChatRoomsByChatRoomId? = nil) {
      self.init(snapshot: ["__typename": "Query", "userChatRoomsByChatRoomId": userChatRoomsByChatRoomId.flatMap { $0.snapshot }])
    }

    public var userChatRoomsByChatRoomId: UserChatRoomsByChatRoomId? {
      get {
        return (snapshot["userChatRoomsByChatRoomId"] as? Snapshot).flatMap { UserChatRoomsByChatRoomId(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "userChatRoomsByChatRoomId")
      }
    }

    public struct UserChatRoomsByChatRoomId: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelUserChatRoomsConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
        GraphQLField("startedAt", type: .scalar(Int.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil, startedAt: Int? = nil) {
        self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken, "startedAt": startedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public var startedAt: Int? {
        get {
          return snapshot["startedAt"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "startedAt")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["UserChatRooms"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("userId", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("chatRoomId", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, userId: GraphQLID, chatRoomId: GraphQLID, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
          self.init(snapshot: ["__typename": "UserChatRooms", "id": id, "userId": userId, "chatRoomId": chatRoomId, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var userId: GraphQLID {
          get {
            return snapshot["userId"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "userId")
          }
        }

        public var chatRoomId: GraphQLID {
          get {
            return snapshot["chatRoomId"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "chatRoomId")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class OnCreateUserSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnCreateUser($filter: ModelSubscriptionUserFilterInput) {\n  onCreateUser(filter: $filter) {\n    __typename\n    id\n    username\n    messages {\n      __typename\n      nextToken\n      startedAt\n    }\n    chatRoom {\n      __typename\n      nextToken\n      startedAt\n    }\n    venues {\n      __typename\n      nextToken\n      startedAt\n    }\n    review {\n      __typename\n      nextToken\n      startedAt\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var filter: ModelSubscriptionUserFilterInput?

  public init(filter: ModelSubscriptionUserFilterInput? = nil) {
    self.filter = filter
  }

  public var variables: GraphQLMap? {
    return ["filter": filter]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onCreateUser", arguments: ["filter": GraphQLVariable("filter")], type: .object(OnCreateUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onCreateUser: OnCreateUser? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onCreateUser": onCreateUser.flatMap { $0.snapshot }])
    }

    public var onCreateUser: OnCreateUser? {
      get {
        return (snapshot["onCreateUser"] as? Snapshot).flatMap { OnCreateUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onCreateUser")
      }
    }

    public struct OnCreateUser: GraphQLSelectionSet {
      public static let possibleTypes = ["User"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("messages", type: .object(Message.selections)),
        GraphQLField("chatRoom", type: .object(ChatRoom.selections)),
        GraphQLField("venues", type: .object(Venue.selections)),
        GraphQLField("review", type: .object(Review.selections)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, username: String, messages: Message? = nil, chatRoom: ChatRoom? = nil, venues: Venue? = nil, review: Review? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "User", "id": id, "username": username, "messages": messages.flatMap { $0.snapshot }, "chatRoom": chatRoom.flatMap { $0.snapshot }, "venues": venues.flatMap { $0.snapshot }, "review": review.flatMap { $0.snapshot }, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var messages: Message? {
        get {
          return (snapshot["messages"] as? Snapshot).flatMap { Message(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "messages")
        }
      }

      public var chatRoom: ChatRoom? {
        get {
          return (snapshot["chatRoom"] as? Snapshot).flatMap { ChatRoom(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "chatRoom")
        }
      }

      public var venues: Venue? {
        get {
          return (snapshot["venues"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venues")
        }
      }

      public var review: Review? {
        get {
          return (snapshot["review"] as? Snapshot).flatMap { Review(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "review")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Message: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelMessageConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelMessageConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct ChatRoom: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelUserChatRoomsConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelVenueConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelVenueConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Review: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelReviewConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelReviewConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class OnUpdateUserSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnUpdateUser($filter: ModelSubscriptionUserFilterInput) {\n  onUpdateUser(filter: $filter) {\n    __typename\n    id\n    username\n    messages {\n      __typename\n      nextToken\n      startedAt\n    }\n    chatRoom {\n      __typename\n      nextToken\n      startedAt\n    }\n    venues {\n      __typename\n      nextToken\n      startedAt\n    }\n    review {\n      __typename\n      nextToken\n      startedAt\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var filter: ModelSubscriptionUserFilterInput?

  public init(filter: ModelSubscriptionUserFilterInput? = nil) {
    self.filter = filter
  }

  public var variables: GraphQLMap? {
    return ["filter": filter]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onUpdateUser", arguments: ["filter": GraphQLVariable("filter")], type: .object(OnUpdateUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onUpdateUser: OnUpdateUser? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onUpdateUser": onUpdateUser.flatMap { $0.snapshot }])
    }

    public var onUpdateUser: OnUpdateUser? {
      get {
        return (snapshot["onUpdateUser"] as? Snapshot).flatMap { OnUpdateUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onUpdateUser")
      }
    }

    public struct OnUpdateUser: GraphQLSelectionSet {
      public static let possibleTypes = ["User"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("messages", type: .object(Message.selections)),
        GraphQLField("chatRoom", type: .object(ChatRoom.selections)),
        GraphQLField("venues", type: .object(Venue.selections)),
        GraphQLField("review", type: .object(Review.selections)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, username: String, messages: Message? = nil, chatRoom: ChatRoom? = nil, venues: Venue? = nil, review: Review? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "User", "id": id, "username": username, "messages": messages.flatMap { $0.snapshot }, "chatRoom": chatRoom.flatMap { $0.snapshot }, "venues": venues.flatMap { $0.snapshot }, "review": review.flatMap { $0.snapshot }, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var messages: Message? {
        get {
          return (snapshot["messages"] as? Snapshot).flatMap { Message(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "messages")
        }
      }

      public var chatRoom: ChatRoom? {
        get {
          return (snapshot["chatRoom"] as? Snapshot).flatMap { ChatRoom(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "chatRoom")
        }
      }

      public var venues: Venue? {
        get {
          return (snapshot["venues"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venues")
        }
      }

      public var review: Review? {
        get {
          return (snapshot["review"] as? Snapshot).flatMap { Review(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "review")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Message: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelMessageConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelMessageConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct ChatRoom: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelUserChatRoomsConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelVenueConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelVenueConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Review: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelReviewConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelReviewConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class OnDeleteUserSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnDeleteUser($filter: ModelSubscriptionUserFilterInput) {\n  onDeleteUser(filter: $filter) {\n    __typename\n    id\n    username\n    messages {\n      __typename\n      nextToken\n      startedAt\n    }\n    chatRoom {\n      __typename\n      nextToken\n      startedAt\n    }\n    venues {\n      __typename\n      nextToken\n      startedAt\n    }\n    review {\n      __typename\n      nextToken\n      startedAt\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var filter: ModelSubscriptionUserFilterInput?

  public init(filter: ModelSubscriptionUserFilterInput? = nil) {
    self.filter = filter
  }

  public var variables: GraphQLMap? {
    return ["filter": filter]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onDeleteUser", arguments: ["filter": GraphQLVariable("filter")], type: .object(OnDeleteUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onDeleteUser: OnDeleteUser? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onDeleteUser": onDeleteUser.flatMap { $0.snapshot }])
    }

    public var onDeleteUser: OnDeleteUser? {
      get {
        return (snapshot["onDeleteUser"] as? Snapshot).flatMap { OnDeleteUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onDeleteUser")
      }
    }

    public struct OnDeleteUser: GraphQLSelectionSet {
      public static let possibleTypes = ["User"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("messages", type: .object(Message.selections)),
        GraphQLField("chatRoom", type: .object(ChatRoom.selections)),
        GraphQLField("venues", type: .object(Venue.selections)),
        GraphQLField("review", type: .object(Review.selections)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, username: String, messages: Message? = nil, chatRoom: ChatRoom? = nil, venues: Venue? = nil, review: Review? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "User", "id": id, "username": username, "messages": messages.flatMap { $0.snapshot }, "chatRoom": chatRoom.flatMap { $0.snapshot }, "venues": venues.flatMap { $0.snapshot }, "review": review.flatMap { $0.snapshot }, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var messages: Message? {
        get {
          return (snapshot["messages"] as? Snapshot).flatMap { Message(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "messages")
        }
      }

      public var chatRoom: ChatRoom? {
        get {
          return (snapshot["chatRoom"] as? Snapshot).flatMap { ChatRoom(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "chatRoom")
        }
      }

      public var venues: Venue? {
        get {
          return (snapshot["venues"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venues")
        }
      }

      public var review: Review? {
        get {
          return (snapshot["review"] as? Snapshot).flatMap { Review(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "review")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Message: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelMessageConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelMessageConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct ChatRoom: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelUserChatRoomsConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelVenueConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelVenueConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Review: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelReviewConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelReviewConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class OnCreateVenueSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnCreateVenue($filter: ModelSubscriptionVenueFilterInput) {\n  onCreateVenue(filter: $filter) {\n    __typename\n    id\n    name\n    description\n    address\n    latitude\n    longitude\n    rating\n    imageKey\n    ownerID\n    owner {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    maxCapacity\n    currentUsers\n    revenue\n    dailyUserCounts {\n      __typename\n      nextToken\n      startedAt\n    }\n    reviews {\n      __typename\n      nextToken\n      startedAt\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var filter: ModelSubscriptionVenueFilterInput?

  public init(filter: ModelSubscriptionVenueFilterInput? = nil) {
    self.filter = filter
  }

  public var variables: GraphQLMap? {
    return ["filter": filter]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onCreateVenue", arguments: ["filter": GraphQLVariable("filter")], type: .object(OnCreateVenue.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onCreateVenue: OnCreateVenue? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onCreateVenue": onCreateVenue.flatMap { $0.snapshot }])
    }

    public var onCreateVenue: OnCreateVenue? {
      get {
        return (snapshot["onCreateVenue"] as? Snapshot).flatMap { OnCreateVenue(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onCreateVenue")
      }
    }

    public struct OnCreateVenue: GraphQLSelectionSet {
      public static let possibleTypes = ["Venue"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("description", type: .nonNull(.scalar(String.self))),
        GraphQLField("address", type: .nonNull(.scalar(String.self))),
        GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
        GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
        GraphQLField("rating", type: .scalar(Double.self)),
        GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
        GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("owner", type: .object(Owner.selections)),
        GraphQLField("maxCapacity", type: .scalar(Int.self)),
        GraphQLField("currentUsers", type: .scalar(Int.self)),
        GraphQLField("revenue", type: .scalar(Double.self)),
        GraphQLField("dailyUserCounts", type: .object(DailyUserCount.selections)),
        GraphQLField("reviews", type: .object(Review.selections)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, owner: Owner? = nil, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, dailyUserCounts: DailyUserCount? = nil, reviews: Review? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "owner": owner.flatMap { $0.snapshot }, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "dailyUserCounts": dailyUserCounts.flatMap { $0.snapshot }, "reviews": reviews.flatMap { $0.snapshot }, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var description: String {
        get {
          return snapshot["description"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "description")
        }
      }

      public var address: String {
        get {
          return snapshot["address"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "address")
        }
      }

      public var latitude: Double {
        get {
          return snapshot["latitude"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "latitude")
        }
      }

      public var longitude: Double {
        get {
          return snapshot["longitude"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "longitude")
        }
      }

      public var rating: Double? {
        get {
          return snapshot["rating"] as? Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "rating")
        }
      }

      public var imageKey: [String]? {
        get {
          return snapshot["imageKey"] as? [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "imageKey")
        }
      }

      public var ownerId: GraphQLID {
        get {
          return snapshot["ownerID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "ownerID")
        }
      }

      public var owner: Owner? {
        get {
          return (snapshot["owner"] as? Snapshot).flatMap { Owner(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "owner")
        }
      }

      public var maxCapacity: Int? {
        get {
          return snapshot["maxCapacity"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxCapacity")
        }
      }

      public var currentUsers: Int? {
        get {
          return snapshot["currentUsers"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "currentUsers")
        }
      }

      public var revenue: Double? {
        get {
          return snapshot["revenue"] as? Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "revenue")
        }
      }

      public var dailyUserCounts: DailyUserCount? {
        get {
          return (snapshot["dailyUserCounts"] as? Snapshot).flatMap { DailyUserCount(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "dailyUserCounts")
        }
      }

      public var reviews: Review? {
        get {
          return (snapshot["reviews"] as? Snapshot).flatMap { Review(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "reviews")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Owner: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct DailyUserCount: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelDailyUserCountConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelDailyUserCountConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Review: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelReviewConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelReviewConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class OnUpdateVenueSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnUpdateVenue($filter: ModelSubscriptionVenueFilterInput) {\n  onUpdateVenue(filter: $filter) {\n    __typename\n    id\n    name\n    description\n    address\n    latitude\n    longitude\n    rating\n    imageKey\n    ownerID\n    owner {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    maxCapacity\n    currentUsers\n    revenue\n    dailyUserCounts {\n      __typename\n      nextToken\n      startedAt\n    }\n    reviews {\n      __typename\n      nextToken\n      startedAt\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var filter: ModelSubscriptionVenueFilterInput?

  public init(filter: ModelSubscriptionVenueFilterInput? = nil) {
    self.filter = filter
  }

  public var variables: GraphQLMap? {
    return ["filter": filter]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onUpdateVenue", arguments: ["filter": GraphQLVariable("filter")], type: .object(OnUpdateVenue.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onUpdateVenue: OnUpdateVenue? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onUpdateVenue": onUpdateVenue.flatMap { $0.snapshot }])
    }

    public var onUpdateVenue: OnUpdateVenue? {
      get {
        return (snapshot["onUpdateVenue"] as? Snapshot).flatMap { OnUpdateVenue(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onUpdateVenue")
      }
    }

    public struct OnUpdateVenue: GraphQLSelectionSet {
      public static let possibleTypes = ["Venue"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("description", type: .nonNull(.scalar(String.self))),
        GraphQLField("address", type: .nonNull(.scalar(String.self))),
        GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
        GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
        GraphQLField("rating", type: .scalar(Double.self)),
        GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
        GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("owner", type: .object(Owner.selections)),
        GraphQLField("maxCapacity", type: .scalar(Int.self)),
        GraphQLField("currentUsers", type: .scalar(Int.self)),
        GraphQLField("revenue", type: .scalar(Double.self)),
        GraphQLField("dailyUserCounts", type: .object(DailyUserCount.selections)),
        GraphQLField("reviews", type: .object(Review.selections)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, owner: Owner? = nil, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, dailyUserCounts: DailyUserCount? = nil, reviews: Review? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "owner": owner.flatMap { $0.snapshot }, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "dailyUserCounts": dailyUserCounts.flatMap { $0.snapshot }, "reviews": reviews.flatMap { $0.snapshot }, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var description: String {
        get {
          return snapshot["description"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "description")
        }
      }

      public var address: String {
        get {
          return snapshot["address"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "address")
        }
      }

      public var latitude: Double {
        get {
          return snapshot["latitude"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "latitude")
        }
      }

      public var longitude: Double {
        get {
          return snapshot["longitude"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "longitude")
        }
      }

      public var rating: Double? {
        get {
          return snapshot["rating"] as? Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "rating")
        }
      }

      public var imageKey: [String]? {
        get {
          return snapshot["imageKey"] as? [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "imageKey")
        }
      }

      public var ownerId: GraphQLID {
        get {
          return snapshot["ownerID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "ownerID")
        }
      }

      public var owner: Owner? {
        get {
          return (snapshot["owner"] as? Snapshot).flatMap { Owner(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "owner")
        }
      }

      public var maxCapacity: Int? {
        get {
          return snapshot["maxCapacity"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxCapacity")
        }
      }

      public var currentUsers: Int? {
        get {
          return snapshot["currentUsers"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "currentUsers")
        }
      }

      public var revenue: Double? {
        get {
          return snapshot["revenue"] as? Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "revenue")
        }
      }

      public var dailyUserCounts: DailyUserCount? {
        get {
          return (snapshot["dailyUserCounts"] as? Snapshot).flatMap { DailyUserCount(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "dailyUserCounts")
        }
      }

      public var reviews: Review? {
        get {
          return (snapshot["reviews"] as? Snapshot).flatMap { Review(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "reviews")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Owner: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct DailyUserCount: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelDailyUserCountConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelDailyUserCountConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Review: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelReviewConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelReviewConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class OnDeleteVenueSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnDeleteVenue($filter: ModelSubscriptionVenueFilterInput) {\n  onDeleteVenue(filter: $filter) {\n    __typename\n    id\n    name\n    description\n    address\n    latitude\n    longitude\n    rating\n    imageKey\n    ownerID\n    owner {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    maxCapacity\n    currentUsers\n    revenue\n    dailyUserCounts {\n      __typename\n      nextToken\n      startedAt\n    }\n    reviews {\n      __typename\n      nextToken\n      startedAt\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var filter: ModelSubscriptionVenueFilterInput?

  public init(filter: ModelSubscriptionVenueFilterInput? = nil) {
    self.filter = filter
  }

  public var variables: GraphQLMap? {
    return ["filter": filter]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onDeleteVenue", arguments: ["filter": GraphQLVariable("filter")], type: .object(OnDeleteVenue.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onDeleteVenue: OnDeleteVenue? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onDeleteVenue": onDeleteVenue.flatMap { $0.snapshot }])
    }

    public var onDeleteVenue: OnDeleteVenue? {
      get {
        return (snapshot["onDeleteVenue"] as? Snapshot).flatMap { OnDeleteVenue(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onDeleteVenue")
      }
    }

    public struct OnDeleteVenue: GraphQLSelectionSet {
      public static let possibleTypes = ["Venue"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("description", type: .nonNull(.scalar(String.self))),
        GraphQLField("address", type: .nonNull(.scalar(String.self))),
        GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
        GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
        GraphQLField("rating", type: .scalar(Double.self)),
        GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
        GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("owner", type: .object(Owner.selections)),
        GraphQLField("maxCapacity", type: .scalar(Int.self)),
        GraphQLField("currentUsers", type: .scalar(Int.self)),
        GraphQLField("revenue", type: .scalar(Double.self)),
        GraphQLField("dailyUserCounts", type: .object(DailyUserCount.selections)),
        GraphQLField("reviews", type: .object(Review.selections)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, owner: Owner? = nil, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, dailyUserCounts: DailyUserCount? = nil, reviews: Review? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "owner": owner.flatMap { $0.snapshot }, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "dailyUserCounts": dailyUserCounts.flatMap { $0.snapshot }, "reviews": reviews.flatMap { $0.snapshot }, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var description: String {
        get {
          return snapshot["description"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "description")
        }
      }

      public var address: String {
        get {
          return snapshot["address"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "address")
        }
      }

      public var latitude: Double {
        get {
          return snapshot["latitude"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "latitude")
        }
      }

      public var longitude: Double {
        get {
          return snapshot["longitude"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "longitude")
        }
      }

      public var rating: Double? {
        get {
          return snapshot["rating"] as? Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "rating")
        }
      }

      public var imageKey: [String]? {
        get {
          return snapshot["imageKey"] as? [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "imageKey")
        }
      }

      public var ownerId: GraphQLID {
        get {
          return snapshot["ownerID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "ownerID")
        }
      }

      public var owner: Owner? {
        get {
          return (snapshot["owner"] as? Snapshot).flatMap { Owner(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "owner")
        }
      }

      public var maxCapacity: Int? {
        get {
          return snapshot["maxCapacity"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxCapacity")
        }
      }

      public var currentUsers: Int? {
        get {
          return snapshot["currentUsers"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "currentUsers")
        }
      }

      public var revenue: Double? {
        get {
          return snapshot["revenue"] as? Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "revenue")
        }
      }

      public var dailyUserCounts: DailyUserCount? {
        get {
          return (snapshot["dailyUserCounts"] as? Snapshot).flatMap { DailyUserCount(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "dailyUserCounts")
        }
      }

      public var reviews: Review? {
        get {
          return (snapshot["reviews"] as? Snapshot).flatMap { Review(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "reviews")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Owner: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct DailyUserCount: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelDailyUserCountConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelDailyUserCountConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Review: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelReviewConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelReviewConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class OnCreateDailyUserCountSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnCreateDailyUserCount($filter: ModelSubscriptionDailyUserCountFilterInput) {\n  onCreateDailyUserCount(filter: $filter) {\n    __typename\n    id\n    venueID\n    venue {\n      __typename\n      id\n      name\n      description\n      address\n      latitude\n      longitude\n      rating\n      imageKey\n      ownerID\n      maxCapacity\n      currentUsers\n      revenue\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    date\n    userCount\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var filter: ModelSubscriptionDailyUserCountFilterInput?

  public init(filter: ModelSubscriptionDailyUserCountFilterInput? = nil) {
    self.filter = filter
  }

  public var variables: GraphQLMap? {
    return ["filter": filter]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onCreateDailyUserCount", arguments: ["filter": GraphQLVariable("filter")], type: .object(OnCreateDailyUserCount.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onCreateDailyUserCount: OnCreateDailyUserCount? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onCreateDailyUserCount": onCreateDailyUserCount.flatMap { $0.snapshot }])
    }

    public var onCreateDailyUserCount: OnCreateDailyUserCount? {
      get {
        return (snapshot["onCreateDailyUserCount"] as? Snapshot).flatMap { OnCreateDailyUserCount(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onCreateDailyUserCount")
      }
    }

    public struct OnCreateDailyUserCount: GraphQLSelectionSet {
      public static let possibleTypes = ["DailyUserCount"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venue", type: .object(Venue.selections)),
        GraphQLField("date", type: .nonNull(.scalar(String.self))),
        GraphQLField("userCount", type: .scalar(Int.self)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, venueId: GraphQLID, venue: Venue? = nil, date: String, userCount: Int? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "DailyUserCount", "id": id, "venueID": venueId, "venue": venue.flatMap { $0.snapshot }, "date": date, "userCount": userCount, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var venueId: GraphQLID {
        get {
          return snapshot["venueID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "venueID")
        }
      }

      public var venue: Venue? {
        get {
          return (snapshot["venue"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venue")
        }
      }

      public var date: String {
        get {
          return snapshot["date"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "date")
        }
      }

      public var userCount: Int? {
        get {
          return snapshot["userCount"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "userCount")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["Venue"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("address", type: .nonNull(.scalar(String.self))),
          GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("rating", type: .scalar(Double.self)),
          GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
          GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("maxCapacity", type: .scalar(Int.self)),
          GraphQLField("currentUsers", type: .scalar(Int.self)),
          GraphQLField("revenue", type: .scalar(Double.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var description: String {
          get {
            return snapshot["description"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var address: String {
          get {
            return snapshot["address"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "address")
          }
        }

        public var latitude: Double {
          get {
            return snapshot["latitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "latitude")
          }
        }

        public var longitude: Double {
          get {
            return snapshot["longitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "longitude")
          }
        }

        public var rating: Double? {
          get {
            return snapshot["rating"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var imageKey: [String]? {
          get {
            return snapshot["imageKey"] as? [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "imageKey")
          }
        }

        public var ownerId: GraphQLID {
          get {
            return snapshot["ownerID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "ownerID")
          }
        }

        public var maxCapacity: Int? {
          get {
            return snapshot["maxCapacity"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxCapacity")
          }
        }

        public var currentUsers: Int? {
          get {
            return snapshot["currentUsers"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "currentUsers")
          }
        }

        public var revenue: Double? {
          get {
            return snapshot["revenue"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "revenue")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class OnUpdateDailyUserCountSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnUpdateDailyUserCount($filter: ModelSubscriptionDailyUserCountFilterInput) {\n  onUpdateDailyUserCount(filter: $filter) {\n    __typename\n    id\n    venueID\n    venue {\n      __typename\n      id\n      name\n      description\n      address\n      latitude\n      longitude\n      rating\n      imageKey\n      ownerID\n      maxCapacity\n      currentUsers\n      revenue\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    date\n    userCount\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var filter: ModelSubscriptionDailyUserCountFilterInput?

  public init(filter: ModelSubscriptionDailyUserCountFilterInput? = nil) {
    self.filter = filter
  }

  public var variables: GraphQLMap? {
    return ["filter": filter]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onUpdateDailyUserCount", arguments: ["filter": GraphQLVariable("filter")], type: .object(OnUpdateDailyUserCount.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onUpdateDailyUserCount: OnUpdateDailyUserCount? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onUpdateDailyUserCount": onUpdateDailyUserCount.flatMap { $0.snapshot }])
    }

    public var onUpdateDailyUserCount: OnUpdateDailyUserCount? {
      get {
        return (snapshot["onUpdateDailyUserCount"] as? Snapshot).flatMap { OnUpdateDailyUserCount(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onUpdateDailyUserCount")
      }
    }

    public struct OnUpdateDailyUserCount: GraphQLSelectionSet {
      public static let possibleTypes = ["DailyUserCount"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venue", type: .object(Venue.selections)),
        GraphQLField("date", type: .nonNull(.scalar(String.self))),
        GraphQLField("userCount", type: .scalar(Int.self)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, venueId: GraphQLID, venue: Venue? = nil, date: String, userCount: Int? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "DailyUserCount", "id": id, "venueID": venueId, "venue": venue.flatMap { $0.snapshot }, "date": date, "userCount": userCount, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var venueId: GraphQLID {
        get {
          return snapshot["venueID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "venueID")
        }
      }

      public var venue: Venue? {
        get {
          return (snapshot["venue"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venue")
        }
      }

      public var date: String {
        get {
          return snapshot["date"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "date")
        }
      }

      public var userCount: Int? {
        get {
          return snapshot["userCount"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "userCount")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["Venue"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("address", type: .nonNull(.scalar(String.self))),
          GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("rating", type: .scalar(Double.self)),
          GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
          GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("maxCapacity", type: .scalar(Int.self)),
          GraphQLField("currentUsers", type: .scalar(Int.self)),
          GraphQLField("revenue", type: .scalar(Double.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var description: String {
          get {
            return snapshot["description"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var address: String {
          get {
            return snapshot["address"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "address")
          }
        }

        public var latitude: Double {
          get {
            return snapshot["latitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "latitude")
          }
        }

        public var longitude: Double {
          get {
            return snapshot["longitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "longitude")
          }
        }

        public var rating: Double? {
          get {
            return snapshot["rating"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var imageKey: [String]? {
          get {
            return snapshot["imageKey"] as? [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "imageKey")
          }
        }

        public var ownerId: GraphQLID {
          get {
            return snapshot["ownerID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "ownerID")
          }
        }

        public var maxCapacity: Int? {
          get {
            return snapshot["maxCapacity"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxCapacity")
          }
        }

        public var currentUsers: Int? {
          get {
            return snapshot["currentUsers"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "currentUsers")
          }
        }

        public var revenue: Double? {
          get {
            return snapshot["revenue"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "revenue")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class OnDeleteDailyUserCountSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnDeleteDailyUserCount($filter: ModelSubscriptionDailyUserCountFilterInput) {\n  onDeleteDailyUserCount(filter: $filter) {\n    __typename\n    id\n    venueID\n    venue {\n      __typename\n      id\n      name\n      description\n      address\n      latitude\n      longitude\n      rating\n      imageKey\n      ownerID\n      maxCapacity\n      currentUsers\n      revenue\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    date\n    userCount\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var filter: ModelSubscriptionDailyUserCountFilterInput?

  public init(filter: ModelSubscriptionDailyUserCountFilterInput? = nil) {
    self.filter = filter
  }

  public var variables: GraphQLMap? {
    return ["filter": filter]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onDeleteDailyUserCount", arguments: ["filter": GraphQLVariable("filter")], type: .object(OnDeleteDailyUserCount.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onDeleteDailyUserCount: OnDeleteDailyUserCount? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onDeleteDailyUserCount": onDeleteDailyUserCount.flatMap { $0.snapshot }])
    }

    public var onDeleteDailyUserCount: OnDeleteDailyUserCount? {
      get {
        return (snapshot["onDeleteDailyUserCount"] as? Snapshot).flatMap { OnDeleteDailyUserCount(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onDeleteDailyUserCount")
      }
    }

    public struct OnDeleteDailyUserCount: GraphQLSelectionSet {
      public static let possibleTypes = ["DailyUserCount"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venue", type: .object(Venue.selections)),
        GraphQLField("date", type: .nonNull(.scalar(String.self))),
        GraphQLField("userCount", type: .scalar(Int.self)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, venueId: GraphQLID, venue: Venue? = nil, date: String, userCount: Int? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "DailyUserCount", "id": id, "venueID": venueId, "venue": venue.flatMap { $0.snapshot }, "date": date, "userCount": userCount, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var venueId: GraphQLID {
        get {
          return snapshot["venueID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "venueID")
        }
      }

      public var venue: Venue? {
        get {
          return (snapshot["venue"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venue")
        }
      }

      public var date: String {
        get {
          return snapshot["date"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "date")
        }
      }

      public var userCount: Int? {
        get {
          return snapshot["userCount"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "userCount")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["Venue"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("address", type: .nonNull(.scalar(String.self))),
          GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("rating", type: .scalar(Double.self)),
          GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
          GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("maxCapacity", type: .scalar(Int.self)),
          GraphQLField("currentUsers", type: .scalar(Int.self)),
          GraphQLField("revenue", type: .scalar(Double.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var description: String {
          get {
            return snapshot["description"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var address: String {
          get {
            return snapshot["address"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "address")
          }
        }

        public var latitude: Double {
          get {
            return snapshot["latitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "latitude")
          }
        }

        public var longitude: Double {
          get {
            return snapshot["longitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "longitude")
          }
        }

        public var rating: Double? {
          get {
            return snapshot["rating"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var imageKey: [String]? {
          get {
            return snapshot["imageKey"] as? [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "imageKey")
          }
        }

        public var ownerId: GraphQLID {
          get {
            return snapshot["ownerID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "ownerID")
          }
        }

        public var maxCapacity: Int? {
          get {
            return snapshot["maxCapacity"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxCapacity")
          }
        }

        public var currentUsers: Int? {
          get {
            return snapshot["currentUsers"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "currentUsers")
          }
        }

        public var revenue: Double? {
          get {
            return snapshot["revenue"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "revenue")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class OnCreateReviewSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnCreateReview($filter: ModelSubscriptionReviewFilterInput) {\n  onCreateReview(filter: $filter) {\n    __typename\n    id\n    venueID\n    venue {\n      __typename\n      id\n      name\n      description\n      address\n      latitude\n      longitude\n      rating\n      imageKey\n      ownerID\n      maxCapacity\n      currentUsers\n      revenue\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    userID\n    user {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    rating\n    comment\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var filter: ModelSubscriptionReviewFilterInput?

  public init(filter: ModelSubscriptionReviewFilterInput? = nil) {
    self.filter = filter
  }

  public var variables: GraphQLMap? {
    return ["filter": filter]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onCreateReview", arguments: ["filter": GraphQLVariable("filter")], type: .object(OnCreateReview.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onCreateReview: OnCreateReview? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onCreateReview": onCreateReview.flatMap { $0.snapshot }])
    }

    public var onCreateReview: OnCreateReview? {
      get {
        return (snapshot["onCreateReview"] as? Snapshot).flatMap { OnCreateReview(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onCreateReview")
      }
    }

    public struct OnCreateReview: GraphQLSelectionSet {
      public static let possibleTypes = ["Review"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venue", type: .object(Venue.selections)),
        GraphQLField("userID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("user", type: .object(User.selections)),
        GraphQLField("rating", type: .nonNull(.scalar(Double.self))),
        GraphQLField("comment", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, venueId: GraphQLID, venue: Venue? = nil, userId: GraphQLID, user: User? = nil, rating: Double, comment: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "Review", "id": id, "venueID": venueId, "venue": venue.flatMap { $0.snapshot }, "userID": userId, "user": user.flatMap { $0.snapshot }, "rating": rating, "comment": comment, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var venueId: GraphQLID {
        get {
          return snapshot["venueID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "venueID")
        }
      }

      public var venue: Venue? {
        get {
          return (snapshot["venue"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venue")
        }
      }

      public var userId: GraphQLID {
        get {
          return snapshot["userID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "userID")
        }
      }

      public var user: User? {
        get {
          return (snapshot["user"] as? Snapshot).flatMap { User(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "user")
        }
      }

      public var rating: Double {
        get {
          return snapshot["rating"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "rating")
        }
      }

      public var comment: String {
        get {
          return snapshot["comment"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "comment")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["Venue"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("address", type: .nonNull(.scalar(String.self))),
          GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("rating", type: .scalar(Double.self)),
          GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
          GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("maxCapacity", type: .scalar(Int.self)),
          GraphQLField("currentUsers", type: .scalar(Int.self)),
          GraphQLField("revenue", type: .scalar(Double.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var description: String {
          get {
            return snapshot["description"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var address: String {
          get {
            return snapshot["address"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "address")
          }
        }

        public var latitude: Double {
          get {
            return snapshot["latitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "latitude")
          }
        }

        public var longitude: Double {
          get {
            return snapshot["longitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "longitude")
          }
        }

        public var rating: Double? {
          get {
            return snapshot["rating"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var imageKey: [String]? {
          get {
            return snapshot["imageKey"] as? [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "imageKey")
          }
        }

        public var ownerId: GraphQLID {
          get {
            return snapshot["ownerID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "ownerID")
          }
        }

        public var maxCapacity: Int? {
          get {
            return snapshot["maxCapacity"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxCapacity")
          }
        }

        public var currentUsers: Int? {
          get {
            return snapshot["currentUsers"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "currentUsers")
          }
        }

        public var revenue: Double? {
          get {
            return snapshot["revenue"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "revenue")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct User: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class OnUpdateReviewSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnUpdateReview($filter: ModelSubscriptionReviewFilterInput) {\n  onUpdateReview(filter: $filter) {\n    __typename\n    id\n    venueID\n    venue {\n      __typename\n      id\n      name\n      description\n      address\n      latitude\n      longitude\n      rating\n      imageKey\n      ownerID\n      maxCapacity\n      currentUsers\n      revenue\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    userID\n    user {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    rating\n    comment\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var filter: ModelSubscriptionReviewFilterInput?

  public init(filter: ModelSubscriptionReviewFilterInput? = nil) {
    self.filter = filter
  }

  public var variables: GraphQLMap? {
    return ["filter": filter]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onUpdateReview", arguments: ["filter": GraphQLVariable("filter")], type: .object(OnUpdateReview.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onUpdateReview: OnUpdateReview? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onUpdateReview": onUpdateReview.flatMap { $0.snapshot }])
    }

    public var onUpdateReview: OnUpdateReview? {
      get {
        return (snapshot["onUpdateReview"] as? Snapshot).flatMap { OnUpdateReview(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onUpdateReview")
      }
    }

    public struct OnUpdateReview: GraphQLSelectionSet {
      public static let possibleTypes = ["Review"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venue", type: .object(Venue.selections)),
        GraphQLField("userID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("user", type: .object(User.selections)),
        GraphQLField("rating", type: .nonNull(.scalar(Double.self))),
        GraphQLField("comment", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, venueId: GraphQLID, venue: Venue? = nil, userId: GraphQLID, user: User? = nil, rating: Double, comment: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "Review", "id": id, "venueID": venueId, "venue": venue.flatMap { $0.snapshot }, "userID": userId, "user": user.flatMap { $0.snapshot }, "rating": rating, "comment": comment, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var venueId: GraphQLID {
        get {
          return snapshot["venueID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "venueID")
        }
      }

      public var venue: Venue? {
        get {
          return (snapshot["venue"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venue")
        }
      }

      public var userId: GraphQLID {
        get {
          return snapshot["userID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "userID")
        }
      }

      public var user: User? {
        get {
          return (snapshot["user"] as? Snapshot).flatMap { User(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "user")
        }
      }

      public var rating: Double {
        get {
          return snapshot["rating"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "rating")
        }
      }

      public var comment: String {
        get {
          return snapshot["comment"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "comment")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["Venue"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("address", type: .nonNull(.scalar(String.self))),
          GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("rating", type: .scalar(Double.self)),
          GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
          GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("maxCapacity", type: .scalar(Int.self)),
          GraphQLField("currentUsers", type: .scalar(Int.self)),
          GraphQLField("revenue", type: .scalar(Double.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var description: String {
          get {
            return snapshot["description"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var address: String {
          get {
            return snapshot["address"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "address")
          }
        }

        public var latitude: Double {
          get {
            return snapshot["latitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "latitude")
          }
        }

        public var longitude: Double {
          get {
            return snapshot["longitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "longitude")
          }
        }

        public var rating: Double? {
          get {
            return snapshot["rating"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var imageKey: [String]? {
          get {
            return snapshot["imageKey"] as? [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "imageKey")
          }
        }

        public var ownerId: GraphQLID {
          get {
            return snapshot["ownerID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "ownerID")
          }
        }

        public var maxCapacity: Int? {
          get {
            return snapshot["maxCapacity"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxCapacity")
          }
        }

        public var currentUsers: Int? {
          get {
            return snapshot["currentUsers"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "currentUsers")
          }
        }

        public var revenue: Double? {
          get {
            return snapshot["revenue"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "revenue")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct User: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class OnDeleteReviewSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnDeleteReview($filter: ModelSubscriptionReviewFilterInput) {\n  onDeleteReview(filter: $filter) {\n    __typename\n    id\n    venueID\n    venue {\n      __typename\n      id\n      name\n      description\n      address\n      latitude\n      longitude\n      rating\n      imageKey\n      ownerID\n      maxCapacity\n      currentUsers\n      revenue\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    userID\n    user {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    rating\n    comment\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n  }\n}"

  public var filter: ModelSubscriptionReviewFilterInput?

  public init(filter: ModelSubscriptionReviewFilterInput? = nil) {
    self.filter = filter
  }

  public var variables: GraphQLMap? {
    return ["filter": filter]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onDeleteReview", arguments: ["filter": GraphQLVariable("filter")], type: .object(OnDeleteReview.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onDeleteReview: OnDeleteReview? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onDeleteReview": onDeleteReview.flatMap { $0.snapshot }])
    }

    public var onDeleteReview: OnDeleteReview? {
      get {
        return (snapshot["onDeleteReview"] as? Snapshot).flatMap { OnDeleteReview(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onDeleteReview")
      }
    }

    public struct OnDeleteReview: GraphQLSelectionSet {
      public static let possibleTypes = ["Review"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venueID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("venue", type: .object(Venue.selections)),
        GraphQLField("userID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("user", type: .object(User.selections)),
        GraphQLField("rating", type: .nonNull(.scalar(Double.self))),
        GraphQLField("comment", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, venueId: GraphQLID, venue: Venue? = nil, userId: GraphQLID, user: User? = nil, rating: Double, comment: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
        self.init(snapshot: ["__typename": "Review", "id": id, "venueID": venueId, "venue": venue.flatMap { $0.snapshot }, "userID": userId, "user": user.flatMap { $0.snapshot }, "rating": rating, "comment": comment, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var venueId: GraphQLID {
        get {
          return snapshot["venueID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "venueID")
        }
      }

      public var venue: Venue? {
        get {
          return (snapshot["venue"] as? Snapshot).flatMap { Venue(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "venue")
        }
      }

      public var userId: GraphQLID {
        get {
          return snapshot["userID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "userID")
        }
      }

      public var user: User? {
        get {
          return (snapshot["user"] as? Snapshot).flatMap { User(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "user")
        }
      }

      public var rating: Double {
        get {
          return snapshot["rating"]! as! Double
        }
        set {
          snapshot.updateValue(newValue, forKey: "rating")
        }
      }

      public var comment: String {
        get {
          return snapshot["comment"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "comment")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public struct Venue: GraphQLSelectionSet {
        public static let possibleTypes = ["Venue"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("description", type: .nonNull(.scalar(String.self))),
          GraphQLField("address", type: .nonNull(.scalar(String.self))),
          GraphQLField("latitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("longitude", type: .nonNull(.scalar(Double.self))),
          GraphQLField("rating", type: .scalar(Double.self)),
          GraphQLField("imageKey", type: .list(.nonNull(.scalar(String.self)))),
          GraphQLField("ownerID", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("maxCapacity", type: .scalar(Int.self)),
          GraphQLField("currentUsers", type: .scalar(Int.self)),
          GraphQLField("revenue", type: .scalar(Double.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, description: String, address: String, latitude: Double, longitude: Double, rating: Double? = nil, imageKey: [String]? = nil, ownerId: GraphQLID, maxCapacity: Int? = nil, currentUsers: Int? = nil, revenue: Double? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "Venue", "id": id, "name": name, "description": description, "address": address, "latitude": latitude, "longitude": longitude, "rating": rating, "imageKey": imageKey, "ownerID": ownerId, "maxCapacity": maxCapacity, "currentUsers": currentUsers, "revenue": revenue, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var description: String {
          get {
            return snapshot["description"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "description")
          }
        }

        public var address: String {
          get {
            return snapshot["address"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "address")
          }
        }

        public var latitude: Double {
          get {
            return snapshot["latitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "latitude")
          }
        }

        public var longitude: Double {
          get {
            return snapshot["longitude"]! as! Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "longitude")
          }
        }

        public var rating: Double? {
          get {
            return snapshot["rating"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "rating")
          }
        }

        public var imageKey: [String]? {
          get {
            return snapshot["imageKey"] as? [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "imageKey")
          }
        }

        public var ownerId: GraphQLID {
          get {
            return snapshot["ownerID"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "ownerID")
          }
        }

        public var maxCapacity: Int? {
          get {
            return snapshot["maxCapacity"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxCapacity")
          }
        }

        public var currentUsers: Int? {
          get {
            return snapshot["currentUsers"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "currentUsers")
          }
        }

        public var revenue: Double? {
          get {
            return snapshot["revenue"] as? Double
          }
          set {
            snapshot.updateValue(newValue, forKey: "revenue")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct User: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class OnCreateChatRoomSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnCreateChatRoom($filter: ModelSubscriptionChatRoomFilterInput, $owner: String) {\n  onCreateChatRoom(filter: $filter, owner: $owner) {\n    __typename\n    id\n    name\n    createdAt\n    updatedAt\n    participants {\n      __typename\n      nextToken\n      startedAt\n    }\n    messages {\n      __typename\n      nextToken\n      startedAt\n    }\n    lastMessage\n    lastMessageTimestamp\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionChatRoomFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionChatRoomFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onCreateChatRoom", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnCreateChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onCreateChatRoom: OnCreateChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onCreateChatRoom": onCreateChatRoom.flatMap { $0.snapshot }])
    }

    public var onCreateChatRoom: OnCreateChatRoom? {
      get {
        return (snapshot["onCreateChatRoom"] as? Snapshot).flatMap { OnCreateChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onCreateChatRoom")
      }
    }

    public struct OnCreateChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["ChatRoom"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("participants", type: .object(Participant.selections)),
        GraphQLField("messages", type: .object(Message.selections)),
        GraphQLField("lastMessage", type: .scalar(String.self)),
        GraphQLField("lastMessageTimestamp", type: .scalar(String.self)),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String, createdAt: String, updatedAt: String, participants: Participant? = nil, messages: Message? = nil, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "ChatRoom", "id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "participants": participants.flatMap { $0.snapshot }, "messages": messages.flatMap { $0.snapshot }, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var participants: Participant? {
        get {
          return (snapshot["participants"] as? Snapshot).flatMap { Participant(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "participants")
        }
      }

      public var messages: Message? {
        get {
          return (snapshot["messages"] as? Snapshot).flatMap { Message(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "messages")
        }
      }

      public var lastMessage: String? {
        get {
          return snapshot["lastMessage"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "lastMessage")
        }
      }

      public var lastMessageTimestamp: String? {
        get {
          return snapshot["lastMessageTimestamp"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "lastMessageTimestamp")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Participant: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelUserChatRoomsConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Message: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelMessageConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelMessageConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class OnUpdateChatRoomSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnUpdateChatRoom($filter: ModelSubscriptionChatRoomFilterInput, $owner: String) {\n  onUpdateChatRoom(filter: $filter, owner: $owner) {\n    __typename\n    id\n    name\n    createdAt\n    updatedAt\n    participants {\n      __typename\n      nextToken\n      startedAt\n    }\n    messages {\n      __typename\n      nextToken\n      startedAt\n    }\n    lastMessage\n    lastMessageTimestamp\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionChatRoomFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionChatRoomFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onUpdateChatRoom", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnUpdateChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onUpdateChatRoom: OnUpdateChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onUpdateChatRoom": onUpdateChatRoom.flatMap { $0.snapshot }])
    }

    public var onUpdateChatRoom: OnUpdateChatRoom? {
      get {
        return (snapshot["onUpdateChatRoom"] as? Snapshot).flatMap { OnUpdateChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onUpdateChatRoom")
      }
    }

    public struct OnUpdateChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["ChatRoom"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("participants", type: .object(Participant.selections)),
        GraphQLField("messages", type: .object(Message.selections)),
        GraphQLField("lastMessage", type: .scalar(String.self)),
        GraphQLField("lastMessageTimestamp", type: .scalar(String.self)),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String, createdAt: String, updatedAt: String, participants: Participant? = nil, messages: Message? = nil, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "ChatRoom", "id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "participants": participants.flatMap { $0.snapshot }, "messages": messages.flatMap { $0.snapshot }, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var participants: Participant? {
        get {
          return (snapshot["participants"] as? Snapshot).flatMap { Participant(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "participants")
        }
      }

      public var messages: Message? {
        get {
          return (snapshot["messages"] as? Snapshot).flatMap { Message(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "messages")
        }
      }

      public var lastMessage: String? {
        get {
          return snapshot["lastMessage"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "lastMessage")
        }
      }

      public var lastMessageTimestamp: String? {
        get {
          return snapshot["lastMessageTimestamp"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "lastMessageTimestamp")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Participant: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelUserChatRoomsConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Message: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelMessageConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelMessageConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class OnDeleteChatRoomSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnDeleteChatRoom($filter: ModelSubscriptionChatRoomFilterInput, $owner: String) {\n  onDeleteChatRoom(filter: $filter, owner: $owner) {\n    __typename\n    id\n    name\n    createdAt\n    updatedAt\n    participants {\n      __typename\n      nextToken\n      startedAt\n    }\n    messages {\n      __typename\n      nextToken\n      startedAt\n    }\n    lastMessage\n    lastMessageTimestamp\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionChatRoomFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionChatRoomFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onDeleteChatRoom", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnDeleteChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onDeleteChatRoom: OnDeleteChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onDeleteChatRoom": onDeleteChatRoom.flatMap { $0.snapshot }])
    }

    public var onDeleteChatRoom: OnDeleteChatRoom? {
      get {
        return (snapshot["onDeleteChatRoom"] as? Snapshot).flatMap { OnDeleteChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onDeleteChatRoom")
      }
    }

    public struct OnDeleteChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["ChatRoom"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("name", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("participants", type: .object(Participant.selections)),
        GraphQLField("messages", type: .object(Message.selections)),
        GraphQLField("lastMessage", type: .scalar(String.self)),
        GraphQLField("lastMessageTimestamp", type: .scalar(String.self)),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, name: String, createdAt: String, updatedAt: String, participants: Participant? = nil, messages: Message? = nil, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "ChatRoom", "id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "participants": participants.flatMap { $0.snapshot }, "messages": messages.flatMap { $0.snapshot }, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String {
        get {
          return snapshot["name"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "name")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var participants: Participant? {
        get {
          return (snapshot["participants"] as? Snapshot).flatMap { Participant(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "participants")
        }
      }

      public var messages: Message? {
        get {
          return (snapshot["messages"] as? Snapshot).flatMap { Message(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "messages")
        }
      }

      public var lastMessage: String? {
        get {
          return snapshot["lastMessage"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "lastMessage")
        }
      }

      public var lastMessageTimestamp: String? {
        get {
          return snapshot["lastMessageTimestamp"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "lastMessageTimestamp")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Participant: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelUserChatRoomsConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelUserChatRoomsConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }

      public struct Message: GraphQLSelectionSet {
        public static let possibleTypes = ["ModelMessageConnection"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("nextToken", type: .scalar(String.self)),
          GraphQLField("startedAt", type: .scalar(Int.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(nextToken: String? = nil, startedAt: Int? = nil) {
          self.init(snapshot: ["__typename": "ModelMessageConnection", "nextToken": nextToken, "startedAt": startedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var nextToken: String? {
          get {
            return snapshot["nextToken"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "nextToken")
          }
        }

        public var startedAt: Int? {
          get {
            return snapshot["startedAt"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "startedAt")
          }
        }
      }
    }
  }
}

public final class OnCreateMessageSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnCreateMessage($filter: ModelSubscriptionMessageFilterInput) {\n  onCreateMessage(filter: $filter) {\n    __typename\n    id\n    senderID\n    sender {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    chatRoomID\n    content\n    timestamp\n    isRead\n    readBy\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionMessageFilterInput?

  public init(filter: ModelSubscriptionMessageFilterInput? = nil) {
    self.filter = filter
  }

  public var variables: GraphQLMap? {
    return ["filter": filter]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onCreateMessage", arguments: ["filter": GraphQLVariable("filter")], type: .object(OnCreateMessage.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onCreateMessage: OnCreateMessage? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onCreateMessage": onCreateMessage.flatMap { $0.snapshot }])
    }

    public var onCreateMessage: OnCreateMessage? {
      get {
        return (snapshot["onCreateMessage"] as? Snapshot).flatMap { OnCreateMessage(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onCreateMessage")
      }
    }

    public struct OnCreateMessage: GraphQLSelectionSet {
      public static let possibleTypes = ["Message"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("senderID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("sender", type: .object(Sender.selections)),
        GraphQLField("chatRoomID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("timestamp", type: .nonNull(.scalar(String.self))),
        GraphQLField("isRead", type: .nonNull(.scalar(Bool.self))),
        GraphQLField("readBy", type: .list(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, senderId: GraphQLID, sender: Sender? = nil, chatRoomId: GraphQLID, content: String, timestamp: String, isRead: Bool, readBy: [String?]? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Message", "id": id, "senderID": senderId, "sender": sender.flatMap { $0.snapshot }, "chatRoomID": chatRoomId, "content": content, "timestamp": timestamp, "isRead": isRead, "readBy": readBy, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var senderId: GraphQLID {
        get {
          return snapshot["senderID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "senderID")
        }
      }

      public var sender: Sender? {
        get {
          return (snapshot["sender"] as? Snapshot).flatMap { Sender(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "sender")
        }
      }

      public var chatRoomId: GraphQLID {
        get {
          return snapshot["chatRoomID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "chatRoomID")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var timestamp: String {
        get {
          return snapshot["timestamp"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "timestamp")
        }
      }

      public var isRead: Bool {
        get {
          return snapshot["isRead"]! as! Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "isRead")
        }
      }

      public var readBy: [String?]? {
        get {
          return snapshot["readBy"] as? [String?]
        }
        set {
          snapshot.updateValue(newValue, forKey: "readBy")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Sender: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class OnUpdateMessageSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnUpdateMessage($filter: ModelSubscriptionMessageFilterInput) {\n  onUpdateMessage(filter: $filter) {\n    __typename\n    id\n    senderID\n    sender {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    chatRoomID\n    content\n    timestamp\n    isRead\n    readBy\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionMessageFilterInput?

  public init(filter: ModelSubscriptionMessageFilterInput? = nil) {
    self.filter = filter
  }

  public var variables: GraphQLMap? {
    return ["filter": filter]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onUpdateMessage", arguments: ["filter": GraphQLVariable("filter")], type: .object(OnUpdateMessage.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onUpdateMessage: OnUpdateMessage? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onUpdateMessage": onUpdateMessage.flatMap { $0.snapshot }])
    }

    public var onUpdateMessage: OnUpdateMessage? {
      get {
        return (snapshot["onUpdateMessage"] as? Snapshot).flatMap { OnUpdateMessage(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onUpdateMessage")
      }
    }

    public struct OnUpdateMessage: GraphQLSelectionSet {
      public static let possibleTypes = ["Message"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("senderID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("sender", type: .object(Sender.selections)),
        GraphQLField("chatRoomID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("timestamp", type: .nonNull(.scalar(String.self))),
        GraphQLField("isRead", type: .nonNull(.scalar(Bool.self))),
        GraphQLField("readBy", type: .list(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, senderId: GraphQLID, sender: Sender? = nil, chatRoomId: GraphQLID, content: String, timestamp: String, isRead: Bool, readBy: [String?]? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Message", "id": id, "senderID": senderId, "sender": sender.flatMap { $0.snapshot }, "chatRoomID": chatRoomId, "content": content, "timestamp": timestamp, "isRead": isRead, "readBy": readBy, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var senderId: GraphQLID {
        get {
          return snapshot["senderID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "senderID")
        }
      }

      public var sender: Sender? {
        get {
          return (snapshot["sender"] as? Snapshot).flatMap { Sender(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "sender")
        }
      }

      public var chatRoomId: GraphQLID {
        get {
          return snapshot["chatRoomID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "chatRoomID")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var timestamp: String {
        get {
          return snapshot["timestamp"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "timestamp")
        }
      }

      public var isRead: Bool {
        get {
          return snapshot["isRead"]! as! Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "isRead")
        }
      }

      public var readBy: [String?]? {
        get {
          return snapshot["readBy"] as? [String?]
        }
        set {
          snapshot.updateValue(newValue, forKey: "readBy")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Sender: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class OnDeleteMessageSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnDeleteMessage($filter: ModelSubscriptionMessageFilterInput) {\n  onDeleteMessage(filter: $filter) {\n    __typename\n    id\n    senderID\n    sender {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    chatRoomID\n    content\n    timestamp\n    isRead\n    readBy\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionMessageFilterInput?

  public init(filter: ModelSubscriptionMessageFilterInput? = nil) {
    self.filter = filter
  }

  public var variables: GraphQLMap? {
    return ["filter": filter]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onDeleteMessage", arguments: ["filter": GraphQLVariable("filter")], type: .object(OnDeleteMessage.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onDeleteMessage: OnDeleteMessage? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onDeleteMessage": onDeleteMessage.flatMap { $0.snapshot }])
    }

    public var onDeleteMessage: OnDeleteMessage? {
      get {
        return (snapshot["onDeleteMessage"] as? Snapshot).flatMap { OnDeleteMessage(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onDeleteMessage")
      }
    }

    public struct OnDeleteMessage: GraphQLSelectionSet {
      public static let possibleTypes = ["Message"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("senderID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("sender", type: .object(Sender.selections)),
        GraphQLField("chatRoomID", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("content", type: .nonNull(.scalar(String.self))),
        GraphQLField("timestamp", type: .nonNull(.scalar(String.self))),
        GraphQLField("isRead", type: .nonNull(.scalar(Bool.self))),
        GraphQLField("readBy", type: .list(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, senderId: GraphQLID, sender: Sender? = nil, chatRoomId: GraphQLID, content: String, timestamp: String, isRead: Bool, readBy: [String?]? = nil, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Message", "id": id, "senderID": senderId, "sender": sender.flatMap { $0.snapshot }, "chatRoomID": chatRoomId, "content": content, "timestamp": timestamp, "isRead": isRead, "readBy": readBy, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var senderId: GraphQLID {
        get {
          return snapshot["senderID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "senderID")
        }
      }

      public var sender: Sender? {
        get {
          return (snapshot["sender"] as? Snapshot).flatMap { Sender(snapshot: $0) }
        }
        set {
          snapshot.updateValue(newValue?.snapshot, forKey: "sender")
        }
      }

      public var chatRoomId: GraphQLID {
        get {
          return snapshot["chatRoomID"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "chatRoomID")
        }
      }

      public var content: String {
        get {
          return snapshot["content"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "content")
        }
      }

      public var timestamp: String {
        get {
          return snapshot["timestamp"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "timestamp")
        }
      }

      public var isRead: Bool {
        get {
          return snapshot["isRead"]! as! Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "isRead")
        }
      }

      public var readBy: [String?]? {
        get {
          return snapshot["readBy"] as? [String?]
        }
        set {
          snapshot.updateValue(newValue, forKey: "readBy")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct Sender: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }
    }
  }
}

public final class OnCreateUserChatRoomsSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnCreateUserChatRooms($filter: ModelSubscriptionUserChatRoomsFilterInput, $owner: String) {\n  onCreateUserChatRooms(filter: $filter, owner: $owner) {\n    __typename\n    id\n    userId\n    chatRoomId\n    user {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    chatRoom {\n      __typename\n      id\n      name\n      createdAt\n      updatedAt\n      lastMessage\n      lastMessageTimestamp\n      _version\n      _deleted\n      _lastChangedAt\n      owner\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionUserChatRoomsFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionUserChatRoomsFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onCreateUserChatRooms", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnCreateUserChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onCreateUserChatRooms: OnCreateUserChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onCreateUserChatRooms": onCreateUserChatRooms.flatMap { $0.snapshot }])
    }

    public var onCreateUserChatRooms: OnCreateUserChatRoom? {
      get {
        return (snapshot["onCreateUserChatRooms"] as? Snapshot).flatMap { OnCreateUserChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onCreateUserChatRooms")
      }
    }

    public struct OnCreateUserChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["UserChatRooms"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("userId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("chatRoomId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("user", type: .nonNull(.object(User.selections))),
        GraphQLField("chatRoom", type: .nonNull(.object(ChatRoom.selections))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, userId: GraphQLID, chatRoomId: GraphQLID, user: User, chatRoom: ChatRoom, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "UserChatRooms", "id": id, "userId": userId, "chatRoomId": chatRoomId, "user": user.snapshot, "chatRoom": chatRoom.snapshot, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var userId: GraphQLID {
        get {
          return snapshot["userId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "userId")
        }
      }

      public var chatRoomId: GraphQLID {
        get {
          return snapshot["chatRoomId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "chatRoomId")
        }
      }

      public var user: User {
        get {
          return User(snapshot: snapshot["user"]! as! Snapshot)
        }
        set {
          snapshot.updateValue(newValue.snapshot, forKey: "user")
        }
      }

      public var chatRoom: ChatRoom {
        get {
          return ChatRoom(snapshot: snapshot["chatRoom"]! as! Snapshot)
        }
        set {
          snapshot.updateValue(newValue.snapshot, forKey: "chatRoom")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct User: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct ChatRoom: GraphQLSelectionSet {
        public static let possibleTypes = ["ChatRoom"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("lastMessage", type: .scalar(String.self)),
          GraphQLField("lastMessageTimestamp", type: .scalar(String.self)),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, createdAt: String, updatedAt: String, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
          self.init(snapshot: ["__typename": "ChatRoom", "id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var lastMessage: String? {
          get {
            return snapshot["lastMessage"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessage")
          }
        }

        public var lastMessageTimestamp: String? {
          get {
            return snapshot["lastMessageTimestamp"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessageTimestamp")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class OnUpdateUserChatRoomsSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnUpdateUserChatRooms($filter: ModelSubscriptionUserChatRoomsFilterInput, $owner: String) {\n  onUpdateUserChatRooms(filter: $filter, owner: $owner) {\n    __typename\n    id\n    userId\n    chatRoomId\n    user {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    chatRoom {\n      __typename\n      id\n      name\n      createdAt\n      updatedAt\n      lastMessage\n      lastMessageTimestamp\n      _version\n      _deleted\n      _lastChangedAt\n      owner\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionUserChatRoomsFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionUserChatRoomsFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onUpdateUserChatRooms", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnUpdateUserChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onUpdateUserChatRooms: OnUpdateUserChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onUpdateUserChatRooms": onUpdateUserChatRooms.flatMap { $0.snapshot }])
    }

    public var onUpdateUserChatRooms: OnUpdateUserChatRoom? {
      get {
        return (snapshot["onUpdateUserChatRooms"] as? Snapshot).flatMap { OnUpdateUserChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onUpdateUserChatRooms")
      }
    }

    public struct OnUpdateUserChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["UserChatRooms"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("userId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("chatRoomId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("user", type: .nonNull(.object(User.selections))),
        GraphQLField("chatRoom", type: .nonNull(.object(ChatRoom.selections))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, userId: GraphQLID, chatRoomId: GraphQLID, user: User, chatRoom: ChatRoom, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "UserChatRooms", "id": id, "userId": userId, "chatRoomId": chatRoomId, "user": user.snapshot, "chatRoom": chatRoom.snapshot, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var userId: GraphQLID {
        get {
          return snapshot["userId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "userId")
        }
      }

      public var chatRoomId: GraphQLID {
        get {
          return snapshot["chatRoomId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "chatRoomId")
        }
      }

      public var user: User {
        get {
          return User(snapshot: snapshot["user"]! as! Snapshot)
        }
        set {
          snapshot.updateValue(newValue.snapshot, forKey: "user")
        }
      }

      public var chatRoom: ChatRoom {
        get {
          return ChatRoom(snapshot: snapshot["chatRoom"]! as! Snapshot)
        }
        set {
          snapshot.updateValue(newValue.snapshot, forKey: "chatRoom")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct User: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct ChatRoom: GraphQLSelectionSet {
        public static let possibleTypes = ["ChatRoom"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("lastMessage", type: .scalar(String.self)),
          GraphQLField("lastMessageTimestamp", type: .scalar(String.self)),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, createdAt: String, updatedAt: String, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
          self.init(snapshot: ["__typename": "ChatRoom", "id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var lastMessage: String? {
          get {
            return snapshot["lastMessage"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessage")
          }
        }

        public var lastMessageTimestamp: String? {
          get {
            return snapshot["lastMessageTimestamp"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessageTimestamp")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class OnDeleteUserChatRoomsSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnDeleteUserChatRooms($filter: ModelSubscriptionUserChatRoomsFilterInput, $owner: String) {\n  onDeleteUserChatRooms(filter: $filter, owner: $owner) {\n    __typename\n    id\n    userId\n    chatRoomId\n    user {\n      __typename\n      id\n      username\n      createdAt\n      updatedAt\n      _version\n      _deleted\n      _lastChangedAt\n    }\n    chatRoom {\n      __typename\n      id\n      name\n      createdAt\n      updatedAt\n      lastMessage\n      lastMessageTimestamp\n      _version\n      _deleted\n      _lastChangedAt\n      owner\n    }\n    createdAt\n    updatedAt\n    _version\n    _deleted\n    _lastChangedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionUserChatRoomsFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionUserChatRoomsFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onDeleteUserChatRooms", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnDeleteUserChatRoom.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onDeleteUserChatRooms: OnDeleteUserChatRoom? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onDeleteUserChatRooms": onDeleteUserChatRooms.flatMap { $0.snapshot }])
    }

    public var onDeleteUserChatRooms: OnDeleteUserChatRoom? {
      get {
        return (snapshot["onDeleteUserChatRooms"] as? Snapshot).flatMap { OnDeleteUserChatRoom(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onDeleteUserChatRooms")
      }
    }

    public struct OnDeleteUserChatRoom: GraphQLSelectionSet {
      public static let possibleTypes = ["UserChatRooms"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("userId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("chatRoomId", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("user", type: .nonNull(.object(User.selections))),
        GraphQLField("chatRoom", type: .nonNull(.object(ChatRoom.selections))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
        GraphQLField("_deleted", type: .scalar(Bool.self)),
        GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, userId: GraphQLID, chatRoomId: GraphQLID, user: User, chatRoom: ChatRoom, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
        self.init(snapshot: ["__typename": "UserChatRooms", "id": id, "userId": userId, "chatRoomId": chatRoomId, "user": user.snapshot, "chatRoom": chatRoom.snapshot, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var userId: GraphQLID {
        get {
          return snapshot["userId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "userId")
        }
      }

      public var chatRoomId: GraphQLID {
        get {
          return snapshot["chatRoomId"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "chatRoomId")
        }
      }

      public var user: User {
        get {
          return User(snapshot: snapshot["user"]! as! Snapshot)
        }
        set {
          snapshot.updateValue(newValue.snapshot, forKey: "user")
        }
      }

      public var chatRoom: ChatRoom {
        get {
          return ChatRoom(snapshot: snapshot["chatRoom"]! as! Snapshot)
        }
        set {
          snapshot.updateValue(newValue.snapshot, forKey: "chatRoom")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var version: Int {
        get {
          return snapshot["_version"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_version")
        }
      }

      public var deleted: Bool? {
        get {
          return snapshot["_deleted"] as? Bool
        }
        set {
          snapshot.updateValue(newValue, forKey: "_deleted")
        }
      }

      public var lastChangedAt: Int {
        get {
          return snapshot["_lastChangedAt"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "_lastChangedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }

      public struct User: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, createdAt: String, updatedAt: String, version: Int, deleted: Bool? = nil, lastChangedAt: Int) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "createdAt": createdAt, "updatedAt": updatedAt, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }
      }

      public struct ChatRoom: GraphQLSelectionSet {
        public static let possibleTypes = ["ChatRoom"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("name", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("lastMessage", type: .scalar(String.self)),
          GraphQLField("lastMessageTimestamp", type: .scalar(String.self)),
          GraphQLField("_version", type: .nonNull(.scalar(Int.self))),
          GraphQLField("_deleted", type: .scalar(Bool.self)),
          GraphQLField("_lastChangedAt", type: .nonNull(.scalar(Int.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, name: String, createdAt: String, updatedAt: String, lastMessage: String? = nil, lastMessageTimestamp: String? = nil, version: Int, deleted: Bool? = nil, lastChangedAt: Int, owner: String? = nil) {
          self.init(snapshot: ["__typename": "ChatRoom", "id": id, "name": name, "createdAt": createdAt, "updatedAt": updatedAt, "lastMessage": lastMessage, "lastMessageTimestamp": lastMessageTimestamp, "_version": version, "_deleted": deleted, "_lastChangedAt": lastChangedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var name: String {
          get {
            return snapshot["name"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "name")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var lastMessage: String? {
          get {
            return snapshot["lastMessage"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessage")
          }
        }

        public var lastMessageTimestamp: String? {
          get {
            return snapshot["lastMessageTimestamp"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "lastMessageTimestamp")
          }
        }

        public var version: Int {
          get {
            return snapshot["_version"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_version")
          }
        }

        public var deleted: Bool? {
          get {
            return snapshot["_deleted"] as? Bool
          }
          set {
            snapshot.updateValue(newValue, forKey: "_deleted")
          }
        }

        public var lastChangedAt: Int {
          get {
            return snapshot["_lastChangedAt"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "_lastChangedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}