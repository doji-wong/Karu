import Foundation

/// Centralized, high-performance cached formatters for Karu.
/// Eliminates per-frame/per-tick DateFormatter and NumberFormatter heap allocations.
@MainActor
public enum KaruFormatters {
    
    // MARK: - Internal Cached Formatters
    
    private static let _flightTimestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, h:mm a"
        return f
    }()

    private static let _etaFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private static let _logbookFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return f
    }()

    private static let _ticketDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        return f
    }()

    public static let distanceFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.groupingSeparator = " "
        nf.numberStyle = .decimal
        return nf
    }()

    // MARK: - Fast Formatter Helpers

    /// Formats departure or arrival timestamps (e.g., "SUN, 3:15 PM").
    public static func formatFlightTimestamp(_ date: Date, timeZoneIdentifier: String? = nil) -> String {
        if let tzId = timeZoneIdentifier, let tz = TimeZone(identifier: tzId) {
            _flightTimestampFormatter.timeZone = tz
        } else {
            _flightTimestampFormatter.timeZone = .current
        }
        return _flightTimestampFormatter.string(from: date).uppercased()
    }

    /// Formats ETA time string (e.g., "ETA 2:15 PM").
    public static func formatETA(_ date: Date, timeZoneIdentifier: String? = nil) -> String {
        if let tzId = timeZoneIdentifier, let tz = TimeZone(identifier: tzId) {
            _etaFormatter.timeZone = tz
        } else {
            _etaFormatter.timeZone = .current
        }
        return "ETA \(_etaFormatter.string(from: date))"
    }

    /// Formats a historical flight date for the pilot's logbook (e.g., "Oct 24, 4:30 PM").
    public static func formatLogbookDate(_ date: Date) -> String {
        return _logbookFormatter.string(from: date)
    }

    /// Formats a flight ticket date (e.g., "2026/09/06").
    public static func formatTicketDate(_ date: Date = Date()) -> String {
        return _ticketDateFormatter.string(from: date)
    }

    /// Formats route distance in kilometers with grouping separator (e.g., "10 342 km").
    public static func formatDistanceKm(_ km: Int) -> String {
        let formatted = distanceFormatter.string(from: NSNumber(value: km)) ?? "\(km)"
        return "\(formatted) km"
    }
}
