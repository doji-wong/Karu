import Foundation

/// Vehicle profiles available in the Karu Garage.
public enum VehicleType: String, Codable, Sendable, CaseIterable, Identifiable {
    case midnightEV
    case classicSarao
    case nightRainHatchback
    case shinkansenExpress
    case coastalBus

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .midnightEV: return "The Midnight EV"
        case .classicSarao: return "The Classic Sarao"
        case .nightRainHatchback: return "Night Rain Hatchback"
        case .shinkansenExpress: return "Shinkansen Express"
        case .coastalBus: return "The Coastal Cruiser"
        }
    }

    public var subtitle: String {
        switch self {
        case .midnightEV: return "Cyber Cruiser · Electric Hum"
        case .classicSarao: return "Heritage Jeepney · Chrome & Engine Purr"
        case .nightRainHatchback: return "Lo-Fi Commuter · Rain on Windshield"
        case .shinkansenExpress: return "Bullet Train · Rail White Noise"
        case .coastalBus: return "Scenic Transit · Ocean Highway Breeze"
        }
    }

    public var description: String {
        switch self {
        case .midnightEV:
            return "Aerodynamic electric coupe with neon teal telemetry lines and smooth low-frequency resonance."
        case .classicSarao:
            return "Vibrant chrome details and warm rhythmic acoustic pulses inspired by provincial road transit."
        case .nightRainHatchback:
            return "Cozy interior with gentle rain-on-roof soundscape and rhythmic wiper cadence for reading."
        case .shinkansenExpress:
            return "High-momentum bullet train with aerodynamic wind tunnel white noise for maximum sprint velocity."
        case .coastalBus:
            return "Relaxed long-haul highway cruiser with rhythmic tire-clicks and ocean wind for deep sessions."
        }
    }

    public var themeColorHex: String {
        switch self {
        case .midnightEV: return "#06B6D4" // Neon Cyan
        case .classicSarao: return "#F59E0B" // Chrome Amber
        case .nightRainHatchback: return "#8B5CF6" // Lo-Fi Violet
        case .shinkansenExpress: return "#10B981" // Electric Emerald
        case .coastalBus: return "#3B82F6" // Highway Blue
        }
    }

    public var soundProfileId: String {
        switch self {
        case .midnightEV: return "audio_ev_cruise"
        case .classicSarao: return "audio_sarao_cruise"
        case .nightRainHatchback: return "audio_rain_cruise"
        case .shinkansenExpress: return "audio_train_cruise"
        case .coastalBus: return "audio_coastal_cruise"
        }
    }

    public var stallSoundProfileId: String {
        switch self {
        case .midnightEV: return "audio_ev_idle"
        case .classicSarao: return "audio_sarao_idle"
        case .nightRainHatchback: return "audio_rain_idle"
        case .shinkansenExpress: return "audio_train_idle"
        case .coastalBus: return "audio_coastal_idle"
        }
    }
}

/// User's vehicle preference and active skin.
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
