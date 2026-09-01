import SwiftUI
import KaruCore

/// Tactile Modular Avionics Flight & Pure High-Contrast Monochrome Design System for Karu.
/// Baseline visual identity: Direction A (Jet Black, Obsidian Charcoal, Crisp White, Platinum Slate).
public enum KaruTheme {
    // MARK: - Core Jet Black & Obsidian Surfaces
    public static let background = Color(hex: 0x08080A)
    public static let carbonMatte = Color(hex: 0x08080A)
    public static let surface = Color(hex: 0x0F0F12)
    public static let recessedTray = Color(hex: 0x151518)
    public static let surfaceElevated = Color(hex: 0x1C1C21)
    public static let surfaceHighlight = Color(hex: 0x27272A)
    public static let surfaceHover = Color(hex: 0x323238)
    public static let cardBorder = Color.white.opacity(0.04)
    public static let cardBorderSubtle = Color.white.opacity(0.02)
    public static let cardBorderActive = Color.white.opacity(0.5)
    
    // MARK: - Monochrome High-Contrast Highlights (Direction A)
    public static let luminousLime = Color.white                  // Crisp White Active Slider Fill & Accents
    public static let luminousLimeBright = Color.white
    public static let luminousLimeDark = Color(hex: 0xE4E4E7)     // Platinum Slate for smooth pill depth
    public static let luminousLimeGlow = Color.white.opacity(0.35)
    
    public static let alertAmber = Color.white                    // Crisp White Route Arrow & Badges
    public static let alertAmberBright = Color.white
    public static let alertAmberDark = Color(hex: 0xE4E4E7)
    
    public static let gridlockRed = Color(hex: 0x71717A)          // Muted Slate for Stall / Turbulence
    
    // MARK: - Legacy / Cross-System Aliases
    public static let solarOrange = Color.white
    public static let solarOrangeBright = Color.white
    public static let solarOrangeDark = Color(hex: 0xE4E4E7)
    public static let electricBlue = Color.white
    public static let telemetryCyan = Color.white
    public static let cyberCyan = Color.white
    public static let racingTeal = Color.white
    public static let telemetryGreen = Color.white
    public static let cruiseEmerald = Color.white
    public static let cruiseNeon = Color.white
    public static let telemetryAmber = Color.white
    public static let hazardAmber = Color(hex: 0xA1A1AA)
    public static let telemetryRed = Color(hex: 0x71717A)
    public static let cyberOrange = Color.white
    public static let hotCoral = Color(hex: 0x71717A)
    public static let hazardRed = Color(hex: 0x71717A)
    public static let navCyan = Color.white
    
    // MARK: - Dot-Matrix Monochrome Grid Palette
    public static let dotMatrixActive = Color.white
    public static let dotMatrixPassive = Color(hex: 0x222226)
    public static let dotMatrixBackground = Color(hex: 0x08080A)
    
    // MARK: - High-Contrast Slate Typography Colors
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: 0xE4E4E7)        // Platinum Slate for cities / ETA
    public static let textMuted = Color(hex: 0x71717A)            // Muted Neutral Slate for timestamps & timezone
    public static let textDimmed = Color(hex: 0x3F3F46)           // Dimmed slate for icons & lines

    // MARK: - Scaled Down Avionics & Monospaced Typography for Breathable Margins
    public static let velocityDisplay = Font.system(size: 32, weight: .black, design: .rounded)
    public static let metricLarge = Font.system(size: 24, weight: .heavy, design: .rounded)
    public static let telemetryDigits = Font.system(size: 20, weight: .heavy, design: .monospaced)
    public static let metricMedium = Font.system(size: 15, weight: .bold, design: .rounded)
    public static let telemetryGauge = Font.system(size: 13, weight: .bold, design: .monospaced)
    public static let headerTitle = Font.system(size: 12, weight: .bold, design: .rounded)
    public static let subheadline = Font.system(size: 10.5, weight: .semibold, design: .default)
    public static let captionMono = Font.system(size: 9.5, weight: .bold, design: .monospaced)
    public static let statValue = Font.system(size: 12, weight: .heavy, design: .monospaced)
    public static let statLabel = Font.system(size: 8, weight: .black, design: .monospaced)
    public static let badgeText = Font.system(size: 7.5, weight: .heavy, design: .monospaced)
    
    // Flight Card Scaled Typography Tokens
    public static let cityTitle = Font.system(size: 12, weight: .bold, design: .default)
    public static let flightTimestamp = Font.system(size: 8.5, weight: .semibold, design: .monospaced)
    public static let etaValue = Font.system(size: 11.5, weight: .bold, design: .default)
    public static let etaSubtext = Font.system(size: 9, weight: .medium, design: .default)
    public static let mealBadge = Font.system(size: 8.5, weight: .heavy, design: .monospaced)
    public static let sliderCountdown = Font.system(size: 9.5, weight: .bold, design: .monospaced)

    // MARK: - Squircle & Shape Constants (Corner Smoothing)
    public static let radiusCard: CGFloat = 20
    public static let radiusCardSmall: CGFloat = 14
    public static let radiusPod: CGFloat = 12
    public static let radiusPill: CGFloat = 999

    // MARK: - State-Driven Resolvers

    /// Primary glow color for a given transit state.
    public static func statusGlow(for state: TransitState) -> Color {
        switch state {
        case .cruising, .completed:
            return Color.white.opacity(0.35)
        case .trafficStalled:
            return Color(hex: 0x71717A).opacity(0.3)
        case .pitStop:
            return Color.white.opacity(0.25)
        case .idle:
            return Color.white.opacity(0.2)
        }
    }

    /// Flight stage status label.
    public static func flightStage(for state: TransitState) -> String {
        switch state {
        case .idle: return "STANDBY"
        case .cruising: return "CRUISING"
        case .pitStop: return "PIT STOP"
        case .trafficStalled: return "GRIDLOCK"
        case .completed: return "ARRIVED"
        }
    }

    /// Accent border/glow color.
    public static func stripeAccent(for state: TransitState) -> Color {
        switch state {
        case .cruising: return Color.white
        case .trafficStalled: return Color(hex: 0x71717A)
        case .pitStop: return Color(hex: 0xA1A1AA)
        case .idle: return cardBorder
        case .completed: return Color.white
        }
    }

    /// Linear gradient for pure white monochrome components.
    public static var limeGradient: LinearGradient {
        LinearGradient(
            colors: [luminousLimeBright, luminousLimeDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Linear gradient for Solar Orange components (backwards alias).
    public static var solarGradient: LinearGradient {
        LinearGradient(
            colors: [Color.white, Color(hex: 0xE4E4E7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Tactile Card View Modifier with Anti-Aliased Corner Smoothing
public struct TactileCardStyle: ViewModifier {
    public var isElevated: Bool
    public var cornerRadius: CGFloat

    public init(isElevated: Bool = false, cornerRadius: CGFloat = KaruTheme.radiusCard) {
        self.isElevated = isElevated
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isElevated ? KaruTheme.surfaceElevated : KaruTheme.carbonMatte)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(KaruTheme.cardBorder, lineWidth: 0.5, antialiased: true)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), style: FillStyle(antialiased: true))
            .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

extension View {
    public func tactileCard(elevated: Bool = false, cornerRadius: CGFloat = KaruTheme.radiusCard) -> some View {
        self.modifier(TactileCardStyle(isElevated: elevated, cornerRadius: cornerRadius))
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
