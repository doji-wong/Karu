import Foundation

/// Represents a recurring focus habit or track.
public struct Habit: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var targetDailyMinutes: Int
    public var defaultPreset: TripPreset
    public var colorHex: String
    public var currentStreakDays: Int
    public var longestStreakDays: Int
    public var totalCompletedTrips: Int
    public var totalFocusSeconds: TimeInterval
    public var lastCompletedDate: Date?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        targetDailyMinutes: Int = 50,
        defaultPreset: TripPreset = .expressway50,
        colorHex: String = "#10B981",
        currentStreakDays: Int = 0,
        longestStreakDays: Int = 0,
        totalCompletedTrips: Int = 0,
        totalFocusSeconds: TimeInterval = 0,
        lastCompletedDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.targetDailyMinutes = targetDailyMinutes
        self.defaultPreset = defaultPreset
        self.colorHex = colorHex
        self.currentStreakDays = currentStreakDays
        self.longestStreakDays = longestStreakDays
        self.totalCompletedTrips = totalCompletedTrips
        self.totalFocusSeconds = totalFocusSeconds
        self.lastCompletedDate = lastCompletedDate
        self.createdAt = createdAt
    }

    /// Record a completed trip against this habit and update streaks.
    public mutating func recordTripCompletion(duration: TimeInterval, calendar: Calendar = .current) {
        totalCompletedTrips += 1
        totalFocusSeconds += duration

        let now = Date()
        if let last = lastCompletedDate {
            if calendar.isDateInToday(last) {
                // Already completed today; streak stays maintained
            } else if calendar.isDateInYesterday(last) {
                // Streak incremented
                currentStreakDays += 1
            } else {
                // Streak reset
                currentStreakDays = 1
            }
        } else {
            currentStreakDays = 1
        }

        if currentStreakDays > longestStreakDays {
            longestStreakDays = currentStreakDays
        }
        lastCompletedDate = now
    }
}
