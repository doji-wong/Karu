import Foundation

/// Represents the current physical transit state of the focus flight.
public enum TransitState: String, Codable, Sendable, CaseIterable {
    /// Aircraft is parked at the gate; no active flight running.
    case idle
    /// Frontmost app is in approved focus workspace; cruising smoothly on time.
    case cruising
    /// Frontmost app is blacklisted distraction hazard; holding in turbulence.
    case trafficStalled
    /// User explicitly paused the flight for a gate hold / pit stop.
    case pitStop
    /// Destination reached / flight successfully landed.
    case completed

    /// Display title for HUD readouts.
    public var displayTitle: String {
        switch self {
        case .idle:
            return "Gate Standby"
        case .cruising:
            return "On Time"
        case .trafficStalled:
            return "In Turbulence"
        case .pitStop:
            return "Gate Hold"
        case .completed:
            return "Touchdown"
        }
    }

    /// Symbol icon name (SF Symbol or custom glyph identifier).
    public var iconSymbolName: String {
        switch self {
        case .idle:
            return "airplane"
        case .cruising:
            return "airplane.departure"
        case .trafficStalled:
            return "wind"
        case .pitStop:
            return "pause.circle.fill"
        case .completed:
            return "airplane.arrival"
        }
    }

    /// Standard cruising ground speed in Knots (kts) for the current state.
    public var targetVelocity: Double {
        switch self {
        case .cruising:
            return 540.0
        case .idle, .trafficStalled, .pitStop, .completed:
            return 0.0
        }
    }
}

// MARK: - Focus Seat Class & Task Mode

/// Focus Seat assignment categories for study and deep work flights.
public enum FocusSeatClass: String, Codable, Sendable, CaseIterable, Identifiable {
    case deepWork = "1A"
    case study = "2B"
    case research = "3C"
    case read = "4D"
    case code = "5F"

    public var id: String { rawValue }

    public var seatCode: String {
        return "Seat \(rawValue)"
    }

    public var title: String {
        switch self {
        case .deepWork: return "Deep Work"
        case .study: return "Study & Learn"
        case .research: return "Research & Write"
        case .read: return "Reading & Review"
        case .code: return "Coding & Ship"
        }
    }

    public var cabinClass: String {
        switch self {
        case .deepWork: return "FIRST CLASS SUITE"
        case .study: return "BUSINESS QUIET ZONE"
        case .research: return "SKY LIBRARY CABIN"
        case .read: return "WINDOW LOUNGE"
        case .code: return "FLIGHT DECK OPS"
        }
    }

    public var subtitle: String {
        switch self {
        case .deepWork: return "First Class Suite · Zero Distractions"
        case .study: return "Quiet Cabin · High-Retention Study"
        case .research: return "Sky Library · Deep Document Synthesis"
        case .read: return "Window Lounge · Calm Reading Immersion"
        case .code: return "Flight Deck · High Velocity Building"
        }
    }

    public var iconSymbol: String {
        switch self {
        case .deepWork: return "brain.head.profile"
        case .study: return "graduationcap.fill"
        case .research: return "books.vertical.fill"
        case .read: return "book.fill"
        case .code: return "curlybraces"
        }
    }

    public var shortTaskTitle: String {
        switch self {
        case .deepWork: return "DEEP WORK"
        case .study: return "STUDY"
        case .research: return "RESEARCH"
        case .read: return "READING"
        case .code: return "CODING"
        }
    }

    public static func find(code: String) -> FocusSeatClass? {
        let clean = code.replacingOccurrences(of: "Seat ", with: "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return FocusSeatClass(rawValue: clean)
    }

    public var themeColorHex: String {
        switch self {
        case .deepWork: return "#FF5C00"
        case .study: return "#2563EB"
        case .research: return "#7C3AED"
        case .read: return "#059669"
        case .code: return "#0284C7"
        }
    }
}

// MARK: - Destination Airport & Timezone Model

/// Global Destination Airport with time zone differential and country flag.
public struct DestinationAirport: Codable, Sendable, Identifiable, Hashable {
    public var id: String { code }
    public let code: String
    public let cityName: String
    public let countryName: String
    public let countryFlag: String
    public let timeZoneIdentifier: String
    public let timeZoneCode: String
    public let utcOffsetHours: Double
    public let latitude: Double
    public let longitude: Double

    public init(
        code: String,
        cityName: String,
        countryName: String,
        countryFlag: String,
        timeZoneIdentifier: String,
        timeZoneCode: String,
        utcOffsetHours: Double,
        latitude: Double = 0.0,
        longitude: Double = 0.0
    ) {
        self.code = code
        self.cityName = cityName
        self.countryName = countryName
        self.countryFlag = countryFlag
        self.timeZoneIdentifier = timeZoneIdentifier
        self.timeZoneCode = timeZoneCode
        self.utcOffsetHours = utcOffsetHours
        self.latitude = latitude
        self.longitude = longitude
    }

    public static let worldwideDestinations: [DestinationAirport] = [
        DestinationAirport(code: "YYZ", cityName: "Toronto", countryName: "Canada", countryFlag: "🇨🇦", timeZoneIdentifier: "America/Toronto", timeZoneCode: "EDT", utcOffsetHours: -4.0, latitude: 43.6777, longitude: -79.6248),
        DestinationAirport(code: "MNL", cityName: "Manila HQ", countryName: "Philippines", countryFlag: "🇵🇭", timeZoneIdentifier: "Asia/Manila", timeZoneCode: "PST", utcOffsetHours: 8.0, latitude: 14.5995, longitude: 120.9842),
        DestinationAirport(code: "VKO", cityName: "Moscow", countryName: "Russia", countryFlag: "🇷🇺", timeZoneIdentifier: "Europe/Moscow", timeZoneCode: "MSK", utcOffsetHours: 3.0, latitude: 55.5915, longitude: 37.2615),
        DestinationAirport(code: "MEX", cityName: "Mexico City", countryName: "Mexico", countryFlag: "🇲🇽", timeZoneIdentifier: "America/Mexico_City", timeZoneCode: "CST", utcOffsetHours: -6.0, latitude: 19.4361, longitude: -99.0719),
        DestinationAirport(code: "SIN", cityName: "Singapore", countryName: "Singapore", countryFlag: "🇸🇬", timeZoneIdentifier: "Asia/Singapore", timeZoneCode: "SGT", utcOffsetHours: 8.0, latitude: 1.3644, longitude: 103.9915),
        DestinationAirport(code: "HND", cityName: "Tokyo", countryName: "Japan", countryFlag: "🇯🇵", timeZoneIdentifier: "Asia/Tokyo", timeZoneCode: "JST", utcOffsetHours: 9.0, latitude: 35.5494, longitude: 139.7798),
        DestinationAirport(code: "LHR", cityName: "London", countryName: "United Kingdom", countryFlag: "🇬🇧", timeZoneIdentifier: "Europe/London", timeZoneCode: "BST", utcOffsetHours: 1.0, latitude: 51.4700, longitude: -0.4543),
        DestinationAirport(code: "JFK", cityName: "New York", countryName: "United States", countryFlag: "🇺🇸", timeZoneIdentifier: "America/New_York", timeZoneCode: "EDT", utcOffsetHours: -4.0, latitude: 40.6413, longitude: -73.7781),
        DestinationAirport(code: "SFO", cityName: "San Francisco", countryName: "United States", countryFlag: "🇺🇸", timeZoneIdentifier: "America/Los_Angeles", timeZoneCode: "PDT", utcOffsetHours: -7.0, latitude: 37.6213, longitude: -122.3790),
        DestinationAirport(code: "CDG", cityName: "Paris", countryName: "France", countryFlag: "🇫🇷", timeZoneIdentifier: "Europe/Paris", timeZoneCode: "CEST", utcOffsetHours: 2.0, latitude: 49.0097, longitude: 2.5479),
        DestinationAirport(code: "SYD", cityName: "Sydney", countryName: "Australia", countryFlag: "🇦🇺", timeZoneIdentifier: "Australia/Sydney", timeZoneCode: "AEST", utcOffsetHours: 10.0, latitude: -33.9399, longitude: 151.1753),
        DestinationAirport(code: "ICN", cityName: "Seoul", countryName: "South Korea", countryFlag: "🇰🇷", timeZoneIdentifier: "Asia/Seoul", timeZoneCode: "KST", utcOffsetHours: 9.0, latitude: 37.4602, longitude: 126.4407),
        DestinationAirport(code: "ZRH", cityName: "Zurich", countryName: "Switzerland", countryFlag: "🇨🇭", timeZoneIdentifier: "Europe/Zurich", timeZoneCode: "CEST", utcOffsetHours: 2.0, latitude: 47.4582, longitude: 8.5555),
        DestinationAirport(code: "KEF", cityName: "Reykjavik", countryName: "Iceland", countryFlag: "🇮🇸", timeZoneIdentifier: "Atlantic/Reykjavik", timeZoneCode: "GMT", utcOffsetHours: 0.0, latitude: 63.9850, longitude: -22.6056),
        DestinationAirport(code: "CTS", cityName: "Sapporo", countryName: "Japan", countryFlag: "🇯🇵", timeZoneIdentifier: "Asia/Tokyo", timeZoneCode: "JST", utcOffsetHours: 9.0, latitude: 42.7752, longitude: 141.6923),
        DestinationAirport(code: "AKL", cityName: "Auckland", countryName: "New Zealand", countryFlag: "🇳🇿", timeZoneIdentifier: "Pacific/Auckland", timeZoneCode: "NZST", utcOffsetHours: 12.0, latitude: -37.0082, longitude: 174.7850)
    ]

    public static func find(code: String) -> DestinationAirport {
        worldwideDestinations.first(where: { $0.code.uppercased() == code.uppercased() }) ??
        DestinationAirport(code: code, cityName: code, countryName: "Global", countryFlag: "✈️", timeZoneIdentifier: "UTC", timeZoneCode: "UTC", utcOffsetHours: 0.0, latitude: 0, longitude: 0)
    }

    /// Calculate Great Circle Distance in kilometers to another airport
    public func distanceKm(to other: DestinationAirport) -> Int {
        if self.latitude == 0.0 && self.longitude == 0.0 { return 10733 }
        let r = 6371.0 // Earth radius in km
        let dLat = (other.latitude - self.latitude) * .pi / 180.0
        let dLon = (other.longitude - self.longitude) * .pi / 180.0
        let lat1 = self.latitude * .pi / 180.0
        let lat2 = other.latitude * .pi / 180.0
        let a = sin(dLat / 2.0) * sin(dLat / 2.0) + sin(dLon / 2.0) * sin(dLon / 2.0) * cos(lat1) * cos(lat2)
        let c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a))
        return max(450, Int(r * c))
    }
}

// MARK: - Global Airport Flight Route Presets

public enum AirportRoutePreset: String, Codable, Sendable, CaseIterable, Identifiable {
    case vkoMex = "VKO ➔ MEX"
    case sinLhr = "SIN ➔ LHR"
    case sfoHnd = "SFO ➔ HND"
    case jfkLhr = "JFK ➔ LHR"
    case hndCts = "HND ➔ CTS"
    case lhrCdg = "LHR ➔ CDG"
    case sydAkl = "SYD ➔ AKL"

    public var id: String { rawValue }

    public var originAirport: DestinationAirport {
        switch self {
        case .vkoMex: return DestinationAirport.find(code: "VKO")
        case .sinLhr: return DestinationAirport.find(code: "SIN")
        case .sfoHnd: return DestinationAirport.find(code: "SFO")
        case .jfkLhr: return DestinationAirport.find(code: "JFK")
        case .hndCts: return DestinationAirport.find(code: "HND")
        case .lhrCdg: return DestinationAirport.find(code: "LHR")
        case .sydAkl: return DestinationAirport.find(code: "SYD")
        }
    }

    public var destinationAirport: DestinationAirport {
        switch self {
        case .vkoMex: return DestinationAirport.find(code: "MEX")
        case .sinLhr: return DestinationAirport.find(code: "LHR")
        case .sfoHnd: return DestinationAirport.find(code: "HND")
        case .jfkLhr: return DestinationAirport.find(code: "LHR")
        case .hndCts: return DestinationAirport.find(code: "CTS")
        case .lhrCdg: return DestinationAirport.find(code: "CDG")
        case .sydAkl: return DestinationAirport.find(code: "AKL")
        }
    }

    public var originCode: String { originAirport.code }
    public var destinationCode: String { destinationAirport.code }

    public var defaultFlightNumber: String {
        switch self {
        case .vkoMex: return "SU 150"
        case .sinLhr: return "FL 288"
        case .sfoHnd: return "NH 107"
        case .jfkLhr: return "BA 178"
        case .hndCts: return "JL 501"
        case .lhrCdg: return "AF 1681"
        case .sydAkl: return "NZ 102"
        }
    }

    public var defaultAircraft: String {
        switch self {
        case .vkoMex: return "B787-9"
        case .sinLhr: return "A350F"
        case .sfoHnd: return "B787-9"
        case .jfkLhr: return "CONCORDE"
        case .hndCts: return "A350F"
        case .lhrCdg: return "G650"
        case .sydAkl: return "B787-9"
        }
    }
}

// MARK: - Flight Boarding Info

/// Information displayed on the minimalist flight boarding pass card.
public struct FlightBoardingInfo: Codable, Sendable, Equatable {
    public var flightNumber: String
    public var seatClass: FocusSeatClass
    public var originAirport: DestinationAirport
    public var destinationAirport: DestinationAirport
    public var scheduledDeparture: String
    public var estimatedArrival: String
    public var aircraftType: String

    public init(
        flightNumber: String = "FL 288",
        seatClass: FocusSeatClass = .deepWork,
        originAirport: DestinationAirport = DestinationAirport.find(code: "SIN"),
        destinationAirport: DestinationAirport = DestinationAirport.find(code: "LHR"),
        scheduledDeparture: String = "11:30 PM",
        estimatedArrival: String = "05:55 AM",
        aircraftType: String = "A350F"
    ) {
        self.flightNumber = flightNumber
        self.seatClass = seatClass
        self.originAirport = originAirport
        self.destinationAirport = destinationAirport
        self.scheduledDeparture = scheduledDeparture
        self.estimatedArrival = estimatedArrival
        self.aircraftType = aircraftType
    }

    public var seatNumber: String { seatClass.seatCode }
}
