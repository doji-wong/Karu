import Foundation

/// A lightweight, immutable telemetry snapshot for macOS Desktop and Notification Center widgets.
/// Curated for glanceable < 2 second scannability adhering to Direction A Monochrome Avionics.
public struct WidgetTelemetrySnapshot: Codable, Sendable, Equatable {
    // MARK: - 1. Current Flight State & Velocity
    public let state: TransitState
    public let currentAirspeedKts: Int

    // MARK: - 2. Active Route & Navigation
    public let originIATA: String
    public let originCity: String
    public let destinationIATA: String
    public let destinationCity: String
    public let statusBadgeText: String

    // MARK: - 3. Daily Performance & Habit Telemetry
    public let dailyCompletedMinutes: Int
    public let dailyGoalMinutes: Int
    public let dailyDistanceNM: Double
    public let dailyEfficiencyPercentage: Double
    public let currentStreakDays: Int
    public let activeAircraftName: String
    public let lastUpdated: Date

    public init(
        state: TransitState = .idle,
        currentAirspeedKts: Int = 0,
        originIATA: String = "SFO",
        originCity: String = "San Francisco",
        destinationIATA: String = "HND",
        destinationCity: String = "Tokyo",
        statusBadgeText: String = "GATE STANDBY",
        dailyCompletedMinutes: Int = 0,
        dailyGoalMinutes: Int = 300,
        dailyDistanceNM: Double = 0.0,
        dailyEfficiencyPercentage: Double = 100.0,
        currentStreakDays: Int = 0,
        activeAircraftName: String = "A350F",
        lastUpdated: Date = Date()
    ) {
        self.state = state
        self.currentAirspeedKts = currentAirspeedKts
        self.originIATA = originIATA
        self.originCity = originCity
        self.destinationIATA = destinationIATA
        self.destinationCity = destinationCity
        self.statusBadgeText = statusBadgeText
        self.dailyCompletedMinutes = dailyCompletedMinutes
        self.dailyGoalMinutes = max(1, dailyGoalMinutes)
        self.dailyDistanceNM = dailyDistanceNM
        self.dailyEfficiencyPercentage = dailyEfficiencyPercentage
        self.currentStreakDays = currentStreakDays
        self.activeAircraftName = activeAircraftName
        self.lastUpdated = lastUpdated
    }

    // MARK: - Computed Properties for Presentation

    /// Progress fraction towards daily goal (0.0 to 1.0+).
    public var dailyProgressFraction: Double {
        return min(1.0, max(0.0, Double(dailyCompletedMinutes) / Double(dailyGoalMinutes)))
    }

    /// Formatted daily completed hours (e.g. "3.5h" or "45m").
    public var formattedCompletedHours: String {
        if dailyCompletedMinutes >= 60 {
            let hours = Double(dailyCompletedMinutes) / 60.0
            return String(format: "%.1fh", hours)
        } else {
            return "\(dailyCompletedMinutes)m"
        }
    }

    /// Formatted daily goal hours (e.g. "5.0h").
    public var formattedGoalHours: String {
        let hours = Double(dailyGoalMinutes) / 60.0
        return String(format: "%.1fh", hours)
    }

    /// Formatted nautical miles (e.g. "1 890 NM").
    public var formattedDistanceNM: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        let formattedNumber = formatter.string(from: NSNumber(value: Int(dailyDistanceNM))) ?? "\(Int(dailyDistanceNM))"
        return "\(formattedNumber) NM"
    }

    /// Formatted efficiency percentage (e.g. "94%").
    public var formattedEfficiency: String {
        return "\(Int(dailyEfficiencyPercentage.rounded()))%"
    }

    // MARK: - Mock Previews

    /// Realistic active cruising flight snapshot for widget previews and tests.
    public static var previewMock: WidgetTelemetrySnapshot {
        WidgetTelemetrySnapshot(
            state: .cruising,
            currentAirspeedKts: 540,
            originIATA: "SFO",
            originCity: "San Francisco",
            destinationIATA: "HND",
            destinationCity: "Tokyo",
            statusBadgeText: "CRUISING 540 KTS",
            dailyCompletedMinutes: 210,
            dailyGoalMinutes: 300,
            dailyDistanceNM: 1890.0,
            dailyEfficiencyPercentage: 94.2,
            currentStreakDays: 12,
            activeAircraftName: "A350F",
            lastUpdated: Date()
        )
    }

    /// Idle flight standby snapshot.
    public static var idleMock: WidgetTelemetrySnapshot {
        WidgetTelemetrySnapshot(
            state: .idle,
            currentAirspeedKts: 0,
            originIATA: "SFO",
            originCity: "San Francisco",
            destinationIATA: "HND",
            destinationCity: "Tokyo",
            statusBadgeText: "GATE STANDBY",
            dailyCompletedMinutes: 120,
            dailyGoalMinutes: 300,
            dailyDistanceNM: 1080.0,
            dailyEfficiencyPercentage: 98.0,
            currentStreakDays: 12,
            activeAircraftName: "A350F",
            lastUpdated: Date()
        )
    }

    /// In-turbulence encounter warning snapshot.
    public static var turbulenceMock: WidgetTelemetrySnapshot {
        WidgetTelemetrySnapshot(
            state: .trafficStalled,
            currentAirspeedKts: 0,
            originIATA: "SFO",
            originCity: "San Francisco",
            destinationIATA: "HND",
            destinationCity: "Tokyo",
            statusBadgeText: "TURBULENCE STALL",
            dailyCompletedMinutes: 140,
            dailyGoalMinutes: 300,
            dailyDistanceNM: 1260.0,
            dailyEfficiencyPercentage: 86.0,
            currentStreakDays: 12,
            activeAircraftName: "A350F",
            lastUpdated: Date()
        )
    }
}
