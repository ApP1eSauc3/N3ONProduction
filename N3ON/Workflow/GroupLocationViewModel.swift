//
//  Workflow/GroupLocationViewModel.swift
//  N3ON
//

import Foundation
import CoreLocation

@MainActor
final class GroupLocationViewModel: ObservableObject {
    @Published var members: [GroupMemberLocation] = []
}
