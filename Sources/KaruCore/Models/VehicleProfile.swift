import Foundation

/// Vehicle/Aircraft profiles available in the Karu Hangar.
public enum VehicleType: String, Codable, Sendable, CaseIterable, Identifiable {
    case midnightEV
    case classicSarao
    case nightRainHatchback
    case shinkansenExpress
    case coastalBus

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .midnightEV: return "Airbus A350F"
        case .classicSarao: return "Boeing 787-9 Dreamliner"
        case .nightRainHatchback: return "Concorde SST"
        case .shinkansenExpress: return "Gulfstream G650"
        case .coastalBus: return "Cessna 172 Skyhawk"
        }
    }

    public var subtitle: String {
        switch self {
        case .midnightEV: return "Flagship Widebody · Rolls-Royce Trent Hum"
        case .classicSarao: return "Dreamliner · Serene Cabin Rain Atmosphere"
        case .nightRainHatchback: return "Supersonic SST · Mach 2.0 Sprint"
        case .shinkansenExpress: return "Executive Jet · FL 450 Deep Focus"
        case .coastalBus: return "VFR Propeller · Scenic Coastal Cruise"
        }
    }

    public var aircraftCode: String {
        switch self {
        case .midnightEV: return "A350F"
        case .classicSarao: return "B787-9"
        case .nightRainHatchback: return "CONCORDE"
        case .shinkansenExpress: return "G650"
        case .coastalBus: return "C172"
        }
    }

    public var description: String {
        switch self {
        case .midnightEV:
            return "Ultra-long-range flagship freighter with modern carbon-fiber wings and deep Rolls-Royce Trent cabin acoustics."
        case .classicSarao:
            return "Next-generation composite passenger jet with soothing acoustic cabin dampening for prolonged study flights."
        case .nightRainHatchback:
            return "Iconic delta-wing supersonic transport designed for high-intensity 25m focus dashes at Mach 2.0."
        case .shinkansenExpress:
            return "Whisper-quiet twin-engine private jet cruising at 45,000 feet above weather and distractions."
        case .coastalBus:
            return "Classic high-wing commuter plane for relaxing visual flight sessions along the coastline."
        }
    }

    public var themeColorHex: String {
        switch self {
        case .midnightEV: return "#FF5C00" // Vibrant Aviation Coral/Orange
        case .classicSarao: return "#0EA5E9" // Sky Cyan
        case .nightRainHatchback: return "#EAB308" // Gold Supersonic
        case .shinkansenExpress: return "#10B981" // Emerald Jet
        case .coastalBus: return "#3B82F6" // Horizon Blue
        }
    }

    public var soundProfileId: String {
        switch self {
        case .midnightEV: return "audio_a350_cruise"
        case .classicSarao: return "audio_b787_cruise"
        case .nightRainHatchback: return "audio_concorde_cruise"
        case .shinkansenExpress: return "audio_g650_cruise"
        case .coastalBus: return "audio_c172_cruise"
        }
    }

    public var stallSoundProfileId: String {
        switch self {
        case .midnightEV: return "audio_a350_turbulence"
        case .classicSarao: return "audio_b787_turbulence"
        case .nightRainHatchback: return "audio_concorde_turbulence"
        case .shinkansenExpress: return "audio_g650_turbulence"
        case .coastalBus: return "audio_c172_turbulence"
        }
    }
}

/// User's vehicle/aircraft preference and active skin.
public struct VehicleProfile: Identifiable, Codable, Sendable, Equatable {
    public var id: String { type.rawValue }
    public var type: VehicleType
    public var isSoundEnabled: Bool
    public var ambientVolume: Double

    public init(
        type: VehicleType = .midnightEV,
        isSoundEnabled: Bool = true,
        ambientVolume: Double = 0.6
    ) {
        self.type = type
        self.isSoundEnabled = isSoundEnabled
        self.ambientVolume = ambientVolume
    }
}

