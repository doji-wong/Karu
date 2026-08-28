import SwiftUI
import KaruCore

/// SpaceX Crew Dragon & Starship inspired Aerospace Telemetry Design System for Karu.
public enum KaruTheme {
    // MARK: - Core Palette Tokens (SpaceX Pure Black OLED)
    public static let background = Color(hex: 0x000000)
    public static let surface = Color(hex: 0x08080A)
    public static let surfaceElevated = Color(hex: 0x121216)
    public static let surfaceHover = Color(hex: 0x1C1C24)
    public static let cardBorder = Color.white.opacity(0.12)
    public static let cardBorderActive = Color(hex: 0x00E5FF).opacity(0.5)
    
    // MARK: - Aerospace Telemetry Accents
    public static let telemetryCyan = Color(hex: 0x00E5FF)       // Nominal Flight / Active Trajectory
    public static let cyberCyan = Color(hex: 0x00E5FF)          // Backwards alias
    public static let racingTeal = Color(hex: 0x00E5FF)         // Backwards alias
    public static let telemetryGreen = Color(hex: 0x30D158)      // Mission Docked / Complete
    public static let cruiseEmerald = Color(hex: 0x30D158)      // Backwards alias
    public static let cruiseNeon = Color(hex: 0x30D158)         // Backwards alias
    public static let telemetryAmber = Color(hex: 0xFF9500)      // Mission Hold / Pit Stop
    public static let hazardAmber = Color(hex: 0xFF9500)        // Backwards alias
    public static let telemetryRed = Color(hex: 0xFF3B30)        // Flight Anomaly / Gridlock
    public static let cyberOrange = Color(hex: 0xFF3B30)        // Backwards alias
    public static let hotCoral = Color(hex: 0xFF3B30)           // Backwards alias
    public static let hazardRed = Color(hex: 0xFF3B30)          // Backwards alias
    public static let navCyan = Color(hex: 0x00E5FF)            // Navigation Cyan
    
    // MARK: - Typography Colors
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: 0xA1A1AA)      // Aerospace silver
    public static let textMuted = Color(hex: 0x52525B)          // Muted telemetry slate
    public static let textDimmed = Color(hex: 0x27272A)

    // MARK: - Monospaced Aerospace Fonts
    public static let velocityDisplay = Font.system(size: 38, weight: .black, design: .monospaced)
    public static let telemetryDigits = Font.system(size: 28, weight: .heavy, design: .monospaced)
    public static let telemetryGauge = Font.system(size: 16, weight: .bold, design: .monospaced)
    public static let headerTitle = Font.system(size: 13, weight: .bold, design: .monospaced)
    public static let subheadline = Font.system(size: 11, weight: .medium, design: .monospaced)
    public static let captionMono = Font.system(size: 10, weight: .semibold, design: .monospaced)
    public static let statValue = Font.system(size: 13, weight: .bold, design: .monospaced)
    public static let statLabel = Font.system(size: 9, weight: .bold, design: .monospaced)

    // MARK: - State-Driven Resolvers

    /// Primary glow color for a given transit state.
    public static func statusGlow(for state: TransitState) -> Color {
        switch state {
        case .cruising:
            return telemetryCyan
        case .trafficStalled:
            return telemetryRed
        case .pitStop:
            return telemetryAmber
        case .idle:
            return textSecondary
        case .completed:
            return telemetryGreen
        }
    }

    /// Flight stage status label.
    public static func flightStage(for state: TransitState) -> String {
        switch state {
        case .idle: return "STANDBY"
        case .cruising: return "NOMINAL"
        case .pitStop: return "MISSION HOLD"
        case .trafficStalled: return "ANOMALY"
        case .completed: return "MISSION COMPLETE"
        }
    }

    /// Accent border/glow color.
    public static func stripeAccent(for state: TransitState) -> Color {
        switch state {
        case .cruising: return telemetryCyan
        case .trafficStalled: return telemetryRed
        case .pitStop: return telemetryAmber
        case .idle: return cardBorder
        case .completed: return telemetryGreen
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
