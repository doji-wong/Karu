import SwiftUI
import KaruCore

/// Karu Racing Livery Design System — Developer-first dark mode with horse mascot branding.
public enum KaruTheme {
    // MARK: - Core Palette Tokens (Midnight Asphalt)
    public static let background = Color(hex: 0x0B0D13)
    public static let surface = Color(hex: 0x11131A)
    public static let surfaceElevated = Color(hex: 0x1A1D28)
    public static let surfaceHover = Color(hex: 0x252836)
    public static let cardBorder = Color(hex: 0x2A2D3A).opacity(0.6)
    
    // MARK: - Racing Livery Accents
    public static let racingTeal = Color(hex: 0x06B6D4)      // Primary accent
    public static let cruiseEmerald = Color(hex: 0x10B981)    // Focus / success state
    public static let cruiseNeon = Color(hex: 0x34D399)       // Bright emerald variant
    public static let hotCoral = Color(hex: 0xFF6B6B)         // Danger / distraction
    public static let hazardAmber = Color(hex: 0xF59E0B)      // Warning / paused
    public static let hazardRed = Color(hex: 0xEF4444)        // Critical error
    public static let navCyan = Color(hex: 0x06B6D4)          // Navigation accent
    public static let navIndigo = Color(hex: 0x6366F1)        // Secondary accent
    
    // MARK: - Typography Colors
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: 0x94A3B8)    // Chrome Silver
    public static let textMuted = Color(hex: 0x64748B)

    // MARK: - Fonts
    public static let velocityDisplay = Font.system(size: 48, weight: .black, design: .rounded)
    public static let telemetryDigits = Font.system(size: 32, weight: .black, design: .monospaced)
    public static let telemetryGauge = Font.system(size: 20, weight: .bold, design: .monospaced)
    public static let headerTitle = Font.system(size: 15, weight: .semibold, design: .rounded)
    public static let subheadline = Font.system(size: 12, weight: .medium, design: .default)
    public static let captionMono = Font.system(size: 10, weight: .regular, design: .monospaced)
    public static let statValue = Font.system(size: 13, weight: .semibold, design: .monospaced)
    public static let statLabel = Font.system(size: 9, weight: .medium, design: .default)

    // MARK: - State-Driven Colors

    /// Primary glow color for a given transit state.
    public static func statusGlow(for state: TransitState) -> Color {
        switch state {
        case .cruising:
            return cruiseEmerald
        case .trafficStalled:
            return hotCoral
        case .pitStop:
            return hazardAmber
        case .idle:
            return navCyan
        case .completed:
            return cruiseNeon
        }
    }

    /// Mascot emoji for quick state representation.
    public static func mascotEmoji(for state: TransitState) -> String {
        switch state {
        case .cruising: return "🐴"   // Galloping
        case .trafficStalled: return "😤" // Frustrated
        case .pitStop: return "☕"     // Coffee break
        case .idle: return "😴"       // Sleeping
        case .completed: return "🏆"  // Winner
        }
    }

    /// Racing stripe accent color for current state.
    public static func stripeAccent(for state: TransitState) -> Color {
        switch state {
        case .cruising: return racingTeal
        case .trafficStalled: return hotCoral
        case .pitStop: return hazardAmber
        case .idle: return textMuted
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
