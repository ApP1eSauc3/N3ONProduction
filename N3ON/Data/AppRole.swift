// AppRole.swift
// N3ON — Data layer
// Pure enum mapping Cognito group strings to app roles.
// AccessControlService (the async resolver) lives in Task/AccessControlService.swift.

import Foundation

enum AppRole: String {
    case dj      = "DJUser"
    case venue   = "VenueOwnerUser"
    case regular = "UserGroup"
}
