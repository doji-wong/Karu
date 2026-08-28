import SwiftUI
import KaruCore

/// Aerospace-inspired OLED Dark Mode Design System for Karu.
public enum KaruTheme {
    // MARK: - Core Palette Tokens
    public static let background = Color(hex: 0x0B0D13)
    public static let surface = Color(hex: 0x121620)
    public static let surfaceElevated = Color(hex: 0x181E2C)
    public static let cardBorder = Color(hex: 0x2A344A).opacity(0.6)
    
    // Telemetry Accents
    public static let cruiseEmerald = Color(hex: 0x10B981)
    public static let cruiseNeon = Color(hex: 0x34D399)
    public static let hazardAmber = Color(hex: 0xF59E0B)
    public static let hazardRed = Color(hex: 0xEF4444)
    public static let navCyan = Color(hex: 0x06B6D4)
    public static let navIndigo = Color(hex: 0x6366F1)
    
    // Typography Colors
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: 0x94A3B8)
    public static let textMuted = Color(hex: 0x64748B)

    // MARK: - Fonts
    public static let telemetryDigits = Font.system(size: 32, weight: .black, design: .monospaced)
    public static let telemetryGauge = Font.system(size: 20, weight: .bold, design: .monospaced)
    public static let headerTitle = Font.system(size: 15, weight: .semibold, design: .rounded)
    public static let subheadline = Font.system(size: 12, weight: .medium, design: .default)
    public static let captionMono = Font.system(size: 10, weight: .regular, design: .monospaced)

    // MARK: - Visual Modifiers
    public static func statusGlow(for state: TransitState) -> Color {
        switch state {
        case .cruising:
            return cruiseEmerald
        case .trafficStalled:
            return hazardAmber
        case .idle, .pitStop, .completed:
            return navCyan
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
