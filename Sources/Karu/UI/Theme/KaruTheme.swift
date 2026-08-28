import SwiftUI
import KaruCore

/// Tesla & Cybertruck-inspired Brutalist Cockpit Design System for Karu.
public enum KaruTheme {
    // MARK: - Core Palette Tokens (Deep Obsidian / Matte Carbon)
    public static let background = Color(hex: 0x07090E)
    public static let surface = Color(hex: 0x0D111A)
    public static let surfaceElevated = Color(hex: 0x141A26)
    public static let surfaceHover = Color(hex: 0x1D2638)
    public static let cardBorder = Color(hex: 0x222C3E).opacity(0.8)
    public static let cardBorderActive = Color(hex: 0x00F0FF).opacity(0.4)
    
    // MARK: - Tesla Telemetry & FSD Energy Accents
    public static let cyberCyan = Color(hex: 0x00F0FF)       // Primary Autopilot / Cruising
    public static let racingTeal = Color(hex: 0x00F0FF)      // Backwards compatibility alias
    public static let cruiseEmerald = Color(hex: 0x10B981)   // Focus completion
    public static let cruiseNeon = Color(hex: 0x34D399)      // Bright emerald
    public static let cyberOrange = Color(hex: 0xFF5E00)     // Hazard / Gridlock / Reverse
    public static let hotCoral = Color(hex: 0xFF5E00)        // Distraction alert
    public static let hazardAmber = Color(hex: 0xF59E0B)     // Neutral / Pit Stop
    public static let hazardRed = Color(hex: 0xEF4444)       // Critical error
    public static let navCyan = Color(hex: 0x00F0FF)         // Telemetry cyan
    public static let navIndigo = Color(hex: 0x6366F1)       // Auxiliary
    
    // MARK: - Typography Colors
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: 0x94A3B8)   // High-contrast chrome silver
    public static let textMuted = Color(hex: 0x475569)       // Deep matte gray
    public static let textDimmed = Color(hex: 0x2C364A)      // Gear unselected

    // MARK: - Brutalist Cockpit Fonts
    public static let velocityDisplay = Font.system(size: 46, weight: .black, design: .rounded)
    public static let telemetryDigits = Font.system(size: 32, weight: .black, design: .monospaced)
    public static let telemetryGauge = Font.system(size: 20, weight: .bold, design: .monospaced)
    public static let gearSelector = Font.system(size: 15, weight: .heavy, design: .monospaced)
    public static let headerTitle = Font.system(size: 14, weight: .bold, design: .rounded)
    public static let subheadline = Font.system(size: 12, weight: .medium, design: .default)
    public static let captionMono = Font.system(size: 10, weight: .semibold, design: .monospaced)
    public static let statValue = Font.system(size: 13, weight: .bold, design: .monospaced)
    public static let statLabel = Font.system(size: 9, weight: .bold, design: .monospaced)

    // MARK: - State-Driven Colors

    /// Primary glow color for a given transit state.
    public static func statusGlow(for state: TransitState) -> Color {
        switch state {
        case .cruising:
            return cyberCyan
        case .trafficStalled:
            return cyberOrange
        case .pitStop:
            return hazardAmber
        case .idle:
            return textSecondary
        case .completed:
            return cruiseEmerald
        }
    }

    /// Gear indicator symbol for current transit state.
    public static func gearLetter(for state: TransitState) -> String {
        switch state {
        case .idle: return "P"
        case .cruising: return "D"
        case .pitStop: return "N"
        case .trafficStalled: return "R"
        case .completed: return "P"
        }
    }

    /// State telemetry subtitle.
    public static func stateSubtitle(for state: TransitState) -> String {
        switch state {
        case .idle: return "PARKED · READY"
        case .cruising: return "DRIVE · AUTOPILOT"
        case .pitStop: return "NEUTRAL · PIT STOP"
        case .trafficStalled: return "REVERSE · GRIDLOCK"
        case .completed: return "ARRIVED · GOAL MET"
        }
    }

    /// Racing stripe accent color for current state.
    public static func stripeAccent(for state: TransitState) -> Color {
        switch state {
        case .cruising: return cyberCyan
        case .trafficStalled: return cyberOrange
        case .pitStop: return hazardAmber
        case .idle: return cardBorder
        case .completed: return cruiseEmerald
        }
    }
}

// MARK: - Color Hex Extension
extension Color {
    public init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
