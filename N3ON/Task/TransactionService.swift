// TransactionService.swift
// N3ON
//
// Read-only queries — all writes happen server-side via Lambda.
// Never write Transaction records directly from the client.

import Foundation
import Amplify

enum TransactionService {

    static func transactions(for userID: String) async throws -> [Transaction] {
        var results: [Transaction] = []

        try await withThrowingTaskGroup(of: [Transaction].self) { group in
            group.addTask {
                try await Amplify.DataStore.query(
                    Transaction.self,
                    where: Transaction.keys.fromUserID == userID
                )
            }
            group.addTask {
                try await Amplify.DataStore.query(
                    Transaction.self,
                    where: Transaction.keys.toUserID == userID
                )
            }
            for try await batch in group {
                results.append(contentsOf: batch)
            }
        }

        var seen = Set<String>()
        return results
            .filter { seen.insert($0.id).inserted }
            .sorted {
                $0.createdAt.foundationDate > $1.createdAt.foundationDate
            }
    }

    static func transactions(for eventID: String) async throws -> [Transaction] {
        try await Amplify.DataStore.query(
            Transaction.self,
            where: Transaction.keys.eventID == eventID
        )
    }

    static func totalEarned(by userID: String) async throws -> Int {
        let received = try await Amplify.DataStore.query(
            Transaction.self,
            where: Transaction.keys.toUserID == userID
        )
        return received
            .filter { TransactionType(rawValue: $0.type) != .refund }
            .reduce(0) { $0 + $1.amount }
    }
}
