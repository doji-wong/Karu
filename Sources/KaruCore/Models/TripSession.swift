import Foundation

/// Standard presets for focus flights.
public enum FlightPreset: String, Codable, Sendable, CaseIterable, Identifiable {
    case sprint25 = "sprint25"
    case cruise50 = "cruise50"
    case longHaul90 = "longHaul90"
    case openFlight = "openFlight"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .sprint25: return "Short Haul Sprint (25m)"
        case .cruise50: return "Cruising Altitude (50m)"
        case .longHaul90: return "Transcontinental (90m)"
        case .openFlight: return "Open Flight Deck (Stopwatch)"
        }
    }

    /// Target duration in seconds (nil for open flight stopwatch).
    public var targetDuration: TimeInterval? {
        switch self {
        case .sprint25: return 25 * 60
        case .cruise50: return 50 * 60
        case .longHaul90: return 90 * 60
        case .openFlight: return nil
        }
    }

    /// Expected target distance in Nautical Miles assuming 540 kts cruising.
    public var targetDistanceNM: Double? {
        guard let duration = targetDuration else { return nil }
        return (duration / 3600.0) * 540.0
    }
    
    public var targetDistanceKm: Double? {
        guard let nm = targetDistanceNM else { return nil }
        return nm * 1.852
    }
}

// Backward compatibility alias
public typealias TripPreset = FlightPreset
public extension FlightPreset {
    static var cityDash25: FlightPreset { .sprint25 }
    static var expressway50: FlightPreset { .cruise50 }
    static var interstate90: FlightPreset { .longHaul90 }
    static var openHighway: FlightPreset { .openFlight }
}

/// A recorded distraction stall / turbulence encounter during a flight.
public struct TurbulenceEncounter: Identifiable, Codable, Sendable, Equatable, Hashable {
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

public typealias TrafficIncident = TurbulenceEncounter

/// A complete log of an active or historical focus flight session.
public struct TripSession: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var habitId: UUID?
    public var habitName: String?
    public var preset: FlightPreset
    public var targetDuration: TimeInterval?
    public var startDate: Date
    public var endDate: Date?
    public var cruisingDuration: TimeInterval
    public var stalledDuration: TimeInterval
    public var pausedDuration: TimeInterval
    public var distanceTraveledNM: Double
    public var turbulenceLogs: [TurbulenceEncounter]
    public var isCompleted: Bool

    // Backward compatibility bridges
    public var incidents: [TurbulenceEncounter] {
        get { turbulenceLogs }
        set { turbulenceLogs = newValue }
    }
    public var distanceTraveledKm: Double {
        get { distanceTraveledNM * 1.852 }
        set { distanceTraveledNM = newValue / 1.852 }
    }

    public init(
        id: UUID = UUID(),
        habitId: UUID? = nil,
        habitName: String? = nil,
        preset: FlightPreset = .sprint25,
        targetDuration: TimeInterval? = 25 * 60,
        startDate: Date = Date(),
        endDate: Date? = nil,
        cruisingDuration: TimeInterval = 0,
        stalledDuration: TimeInterval = 0,
        pausedDuration: TimeInterval = 0,
        distanceTraveledNM: Double = 0,
        turbulenceLogs: [TurbulenceEncounter] = [],
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
        self.distanceTraveledNM = distanceTraveledNM
        self.turbulenceLogs = turbulenceLogs
        self.isCompleted = isCompleted
    }

    /// Total active flight time (cruising + turbulence), excluding manual gate holds.
    public var activeFlightDuration: TimeInterval {
        cruisingDuration + stalledDuration
    }

    public var activeTransitDuration: TimeInterval {
        activeFlightDuration
    }

    /// Total elapsed wall-clock duration from departure to touchdown.
    public var totalElapsedDuration: TimeInterval {
        cruisingDuration + stalledDuration + pausedDuration
    }

    /// Cruising on-time efficiency percentage (0% to 100%).
    public var cruiseEfficiency: Double {
        guard activeFlightDuration > 0 else { return 100.0 }
        return min(100.0, max(0.0, (cruisingDuration / activeFlightDuration) * 100.0))
    }

    /// Completion progress percentage (0.0 to 1.0) based on target flight duration.
    public var progressFraction: Double {
        guard let target = targetDuration, target > 0 else { return 0.0 }
        return min(1.0, cruisingDuration / target)
    }
}
