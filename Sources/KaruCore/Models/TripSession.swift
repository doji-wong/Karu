import Foundation

/// Standard presets for focus trips.
public enum TripPreset: String, Codable, Sendable, CaseIterable, Identifiable {
    case cityDash25
    case expressway50
    case interstate90
    case openHighway

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cityDash25: return "City Dash (25m)"
        case .expressway50: return "Expressway Transit (50m)"
        case .interstate90: return "Interstate Run (90m)"
        case .openHighway: return "Open Highway (Stopwatch)"
        }
    }

    /// Target duration in seconds (nil for open highway stopwatch).
    public var targetDuration: TimeInterval? {
        switch self {
        case .cityDash25: return 25 * 60
        case .expressway50: return 50 * 60
        case .interstate90: return 90 * 60
        case .openHighway: return nil
        }
    }

    /// Expected target distance in kilometers assuming 100 km/h cruising.
    public var targetDistanceKm: Double? {
        guard let duration = targetDuration else { return nil }
        return (duration / 3600.0) * 100.0
    }
}

/// A recorded distraction stall incident during a trip.
public struct TrafficIncident: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let timestamp: Date
    public let appName: String
    public let bundleIdentifier: String
    public var duration: TimeInterval

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        appName: String,
        bundleIdentifier: String,
        duration: TimeInterval = 0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.duration = duration
    }
}

/// A complete log of an active or historical focus session.
public struct TripSession: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var habitId: UUID?
    public var habitName: String?
    public var preset: TripPreset
    public var targetDuration: TimeInterval?
    public var startDate: Date
    public var endDate: Date?
    public var cruisingDuration: TimeInterval
    public var stalledDuration: TimeInterval
    public var pausedDuration: TimeInterval
    public var distanceTraveledKm: Double
    public var incidents: [TrafficIncident]
    public var scratchpadNotes: String
    public var isCompleted: Bool

    public init(
        id: UUID = UUID(),
        habitId: UUID? = nil,
        habitName: String? = nil,
        preset: TripPreset = .cityDash25,
        targetDuration: TimeInterval? = 25 * 60,
        startDate: Date = Date(),
        endDate: Date? = nil,
        cruisingDuration: TimeInterval = 0,
        stalledDuration: TimeInterval = 0,
        pausedDuration: TimeInterval = 0,
        distanceTraveledKm: Double = 0,
        incidents: [TrafficIncident] = [],
        scratchpadNotes: String = "",
        isCompleted: Bool = false
    ) {
        self.id = id
        self.habitId = habitId
        self.habitName = habitName
        self.preset = preset
        self.targetDuration = targetDuration ?? preset.targetDuration
        self.startDate = startDate
        self.endDate = endDate
        self.cruisingDuration = cruisingDuration
        self.stalledDuration = stalledDuration
        self.pausedDuration = pausedDuration
        self.distanceTraveledKm = distanceTraveledKm
        self.incidents = incidents
        self.scratchpadNotes = scratchpadNotes
        self.isCompleted = isCompleted
    }

    /// Total active transit time (cruising + stalled), excluding manual pauses.
    public var activeTransitDuration: TimeInterval {
        cruisingDuration + stalledDuration
    }

    /// Total elapsed wall-clock duration from start to finish (or now).
    public var totalElapsedDuration: TimeInterval {
        cruisingDuration + stalledDuration + pausedDuration
    }

    /// Cruising efficiency percentage (0% to 100%).
    public var cruiseEfficiency: Double {
        guard activeTransitDuration > 0 else { return 100.0 }
        return min(100.0, max(0.0, (cruisingDuration / activeTransitDuration) * 100.0))
    }

    /// Completion progress percentage (0.0 to 1.0) based on target duration.
    public var progressFraction: Double {
        guard let target = targetDuration, target > 0 else { return 0.0 }
        return min(1.0, cruisingDuration / target)
    }
}
