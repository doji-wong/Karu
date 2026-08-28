import Foundation

/// Represents the current physical transit state of the focus vehicle.
public enum TransitState: String, Codable, Sendable, CaseIterable {
    /// Vehicle is parked; no active trip running.
    case idle
    /// Frontmost app is in approved focus workspace; cruising at top velocity (100 km/h).
    case cruising
    /// Frontmost app is blacklisted distraction hazard; speed stalled at 0 km/h.
    case trafficStalled
    /// User explicitly paused the trip for a pit stop.
    case pitStop
    /// Destination reached / trip successfully completed.
    case completed

    /// Display title for HUD readouts.
    public var displayTitle: String {
        switch self {
        case .idle:
            return "Parked"
        case .cruising:
            return "Cruising"
        case .trafficStalled:
            return "Traffic Gridlock"
        case .pitStop:
            return "Pit Stop"
        case .completed:
            return "Arrived"
        }
    }

    /// Symbol icon name (SF Symbol or custom glyph identifier).
    public var iconSymbolName: String {
        switch self {
        case .idle:
            return "car"
        case .cruising:
            return "bolt.car.fill"
        case .trafficStalled:
            return "exclamationmark.triangle.fill"
        case .pitStop:
            return "cup.and.saucer.fill"
        case .completed:
            return "flag.checkered"
        }
    }

    /// Standard velocity in km/h for the current state.
    public var targetVelocity: Double {
        switch self {
        case .cruising:
            return 100.0
        case .idle, .trafficStalled, .pitStop, .completed:
            return 0.0
        }
    }
}
