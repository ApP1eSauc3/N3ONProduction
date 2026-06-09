// EventCreationStep.swift
// N3ON — Data layer
// Drives the three-stage event creation flow in EventCreationFlowView.

enum EventCreationStep: Int, CaseIterable {
    case datePicker = 0
    case limbo      = 1
    case pricing    = 2

    var next: EventCreationStep? {
        switch self {
        case .datePicker: return .limbo
        case .limbo:      return .pricing
        case .pricing:    return nil
        }
    }

    var previous: EventCreationStep? {
        switch self {
        case .datePicker: return nil
        case .limbo:      return .datePicker
        case .pricing:    return .limbo
        }
    }

    var title: String {
        switch self {
        case .datePicker: return "Choose Date"
        case .limbo:      return "Build Lineup"
        case .pricing:    return "Go Live"
        }
    }
}
