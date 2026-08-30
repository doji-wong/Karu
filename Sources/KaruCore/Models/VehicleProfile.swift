import Foundation

/// Aircraft models available in the Karu Fleet Hangar.
public enum AircraftType: String, Codable, Sendable, CaseIterable, Identifiable {
    case a350F = "a350F"
    case b787Dreamliner = "b787Dreamliner"
    case concordeSST = "concordeSST"
    case gulfstreamG650 = "gulfstreamG650"
    case cessna172 = "cessna172"

    public var id: String { rawValue }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "a350F", "midnightEV":
            self = .a350F
        case "b787Dreamliner", "classicSarao":
            self = .b787Dreamliner
        case "concordeSST", "nightRainHatchback":
            self = .concordeSST
        case "gulfstreamG650", "shinkansenExpress":
            self = .gulfstreamG650
        case "cessna172", "coastalBus":
            self = .cessna172
        default:
            if let matched = AircraftType(rawValue: raw) {
                self = matched
            } else {
                self = .a350F
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    public var name: String {
        switch self {
        case .a350F: return "Airbus A350F"
        case .b787Dreamliner: return "Boeing 787-9 Dreamliner"
        case .concordeSST: return "Concorde SST"
        case .gulfstreamG650: return "Gulfstream G650"
        case .cessna172: return "Cessna 172 Skyhawk"
        }
    }

    public var subtitle: String {
        switch self {
        case .a350F: return "Flagship Widebody · Rolls-Royce Trent Hum"
        case .b787Dreamliner: return "Dreamliner · Serene Cabin Airflow Atmosphere"
        case .concordeSST: return "Supersonic SST · Mach 2.0 Sprint"
        case .gulfstreamG650: return "Executive Jet · FL 450 Deep Focus"
        case .cessna172: return "VFR Propeller · Scenic Coastal Cruise"
        }
    }

    public var aircraftCode: String {
        switch self {
        case .a350F: return "A350F"
        case .b787Dreamliner: return "B787-9"
        case .concordeSST: return "CONCORDE"
        case .gulfstreamG650: return "G650"
        case .cessna172: return "C172"
        }
    }

    public var description: String {
        switch self {
        case .a350F:
            return "Ultra-long-range flagship freighter with modern carbon-fiber wings and deep Rolls-Royce Trent cabin acoustics."
        case .b787Dreamliner:
            return "Next-generation composite passenger jet with soothing acoustic cabin dampening for prolonged study flights."
        case .concordeSST:
            return "Iconic delta-wing supersonic transport designed for high-intensity 25m focus dashes at Mach 2.0."
        case .gulfstreamG650:
            return "Whisper-quiet twin-engine private jet cruising at 45,000 feet above weather and distractions."
        case .cessna172:
            return "Classic high-wing commuter plane for relaxing visual flight sessions along the coastline."
        }
    }

    public var themeColorHex: String {
        switch self {
        case .a350F: return "#FF5C00" // Aviation Coral/Orange
        case .b787Dreamliner: return "#0EA5E9" // Sky Cyan
        case .concordeSST: return "#EAB308" // Gold Supersonic
        case .gulfstreamG650: return "#10B981" // Emerald Jet
        case .cessna172: return "#3B82F6" // Horizon Blue
        }
    }

    public var soundProfileId: String {
        switch self {
        case .a350F: return "audio_a350_cruise"
        case .b787Dreamliner: return "audio_b787_cruise"
        case .concordeSST: return "audio_concorde_cruise"
        case .gulfstreamG650: return "audio_g650_cruise"
        case .cessna172: return "audio_c172_cruise"
        }
    }

    public var stallSoundProfileId: String {
        switch self {
        case .a350F: return "audio_a350_turbulence"
        case .b787Dreamliner: return "audio_b787_turbulence"
        case .concordeSST: return "audio_concorde_turbulence"
        case .gulfstreamG650: return "audio_g650_turbulence"
        case .cessna172: return "audio_c172_turbulence"
        }
    }
}

// Backward compatibility aliases
public typealias VehicleType = AircraftType
public extension AircraftType {
    static var midnightEV: AircraftType { .a350F }
    static var classicSarao: AircraftType { .b787Dreamliner }
    static var nightRainHatchback: AircraftType { .concordeSST }
    static var shinkansenExpress: AircraftType { .gulfstreamG650 }
    static var coastalBus: AircraftType { .cessna172 }
}

/// User's active aircraft preference and audio settings.
public struct AircraftProfile: Identifiable, Codable, Sendable, Equatable {
    public var id: String { type.rawValue }
    public var type: AircraftType
    public var isSoundEnabled: Bool
    public var ambientVolume: Double

    public init(
        type: AircraftType = .a350F,
        isSoundEnabled: Bool = true,
        ambientVolume: Double = 0.6
    ) {
        self.type = type
        self.isSoundEnabled = isSoundEnabled
        self.ambientVolume = ambientVolume
    }
}

public typealias VehicleProfile = AircraftProfile
