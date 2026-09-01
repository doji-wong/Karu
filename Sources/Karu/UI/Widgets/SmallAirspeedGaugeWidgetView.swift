import SwiftUI
import KaruCore

/// Direction A Monochrome Avionics Small Widget (`systemSmall` — 158x158 pt).
/// Minimalist cockpit flight computer showing daily focus quota progress ring, current airspeed velocity (540 kts), and streak.
public struct SmallAirspeedGaugeWidgetView: View {
    public let snapshot: WidgetTelemetrySnapshot

    public init(snapshot: WidgetTelemetrySnapshot = .previewMock) {
        self.snapshot = snapshot
    }

    public var body: some View {
        VStack(spacing: 7) {
            // Header: Section label & status dot & quota fraction
            HStack(spacing: 4) {
                Circle()
                    .fill(statusIndicatorColor)
                    .frame(width: 4.5, height: 4.5)
                    .shadow(color: statusIndicatorColor.opacity(0.8), radius: 3)
                
                Text("DAILY FLIGHT")
                    .font(KaruTheme.statLabel)
                    .foregroundColor(KaruTheme.textMuted)
                    .tracking(1.0)
                
                Spacer()
                
                Text("\(snapshot.formattedCompletedHours) / \(snapshot.formattedGoalHours)")
                    .font(KaruTheme.captionMono)
                    .foregroundColor(KaruTheme.textSecondary)
            }
            .padding(.horizontal, 2)

            // Center: Circular Progress Gauge & Airspeed Readout
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 4.5)
                
                // Active Quota Progress Arc
                Circle()
                    .trim(from: 0, to: CGFloat(snapshot.dailyProgressFraction))
                    .stroke(
                        Color.white,
                        style: StrokeStyle(lineWidth: 4.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: Color.white.opacity(snapshot.dailyProgressFraction > 0 ? 0.35 : 0.0), radius: 3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: snapshot.dailyProgressFraction)

                // Internal Airspeed Telemetry
                VStack(spacing: 1) {
                    Text("\(snapshot.currentAirspeedKts)")
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .tracking(-0.5)

                    Text(velocityUnitText)
                        .font(KaruTheme.badgeText)
                        .foregroundColor(velocitySubtextColor)
                        .tracking(0.9)
                }
            }
            .frame(width: 76, height: 76)

            // Footer: Streak & Fleet Badges
            HStack(spacing: 6) {
                // Streak Badge
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(.white)
                    Text("\(snapshot.currentStreakDays)D")
                        .font(KaruTheme.captionMono)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(KaruTheme.recessedTray)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5, antialiased: true)
                )
                .clipShape(Capsule(), style: FillStyle(antialiased: true))

                Spacer()

                // Aircraft Fleet Badge
                HStack(spacing: 3) {
                    Image(systemName: "airplane")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(KaruTheme.textMuted)
                    Text(snapshot.activeAircraftName)
                        .font(KaruTheme.captionMono)
                        .foregroundColor(KaruTheme.textSecondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(KaruTheme.recessedTray)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5, antialiased: true)
                )
                .clipShape(Capsule(), style: FillStyle(antialiased: true))
            }
            .padding(.horizontal, 2)
        }
        .padding(13)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KaruTheme.carbonMatte)
        .overlay(
            RoundedRectangle(cornerRadius: KaruTheme.radiusCardSmall, style: .continuous)
                .strokeBorder(KaruTheme.cardBorder, lineWidth: 0.5, antialiased: true)
        )
        .clipShape(RoundedRectangle(cornerRadius: KaruTheme.radiusCardSmall, style: .continuous), style: FillStyle(antialiased: true))
    }

    // MARK: - Visual Helpers

    private var statusIndicatorColor: Color {
        switch snapshot.state {
        case .cruising:
            return Color.white
        case .trafficStalled:
            return Color(hex: 0xF59E0B) // Amber caution
        case .pitStop:
            return Color(hex: 0x3B82F6) // Hold blue
        case .completed:
            return Color.white
        case .idle:
            return Color.white.opacity(0.3)
        }
    }

    private var velocityUnitText: String {
        switch snapshot.state {
        case .cruising:
            return "KTS CRUISE"
        case .trafficStalled:
            return "TURBULENCE"
        case .pitStop:
            return "GATE HOLD"
        case .completed:
            return "TOUCHDOWN"
        case .idle:
            return "STANDBY"
        }
    }

    private var velocitySubtextColor: Color {
        switch snapshot.state {
        case .cruising:
            return KaruTheme.textSecondary
        case .trafficStalled:
            return Color(hex: 0xF59E0B)
        case .pitStop:
            return Color(hex: 0x3B82F6)
        case .completed, .idle:
            return KaruTheme.textMuted
        }
    }
}
