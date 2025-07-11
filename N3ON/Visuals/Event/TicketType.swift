//
//  TicketType.swift
//  N3ON
//
//  Created by liam howe on 11/7/2025.
//

import Foundation

public struct TicketType: Codable, Identifiable {
    public let id: String
    public var name: String
    public var price: Double
    public var description: String?
    public var remainingStock: Int
}
