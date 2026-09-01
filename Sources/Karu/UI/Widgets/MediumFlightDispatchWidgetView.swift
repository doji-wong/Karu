import SwiftUI
import KaruCore

/// Direction A Monochrome Avionics Medium Widget (`systemMedium` — 338x158 pt).
/// Split-pane Flight Dispatch Board: Left pane displays today's certified flight performance;
/// Right pane displays active flight route telemetry with procedural 5x7 LED dot matrix and 1-click takeoff control.
public struct MediumFlightDispatchWidgetView: View {
    public let snapshot: WidgetTelemetrySnapshot
    public var onTakeoffAction: (() -> Void)? = nil
    public var onHoldAction: (() -> Void)? = nil

    public init(
        snapshot: WidgetTelemetrySnapshot = .previewMock,
        onTakeoffAction: (() -> Void)? = nil,
        onHoldAction: (() -> Void)? = nil
    ) {
        self.snapshot = snapshot
        self.onTakeoffAction = onTakeoffAction
        self.onHoldAction = onHoldAction
    }

    public var body: some View {
        HStack(spacing: 12) {
            // MARK: - Left Column: Daily Performance Telemetry
            VStack(alignment: .leading, spacing: 6) {
                // Section Header & Streak
                HStack {
                    Text("TODAY'S FLIGHT LOG")
                        .font(KaruTheme.statLabel)
                        .foregroundColor(KaruTheme.textMuted)
                        .tracking(0.9)

                    Spacer()

                    HStack(spacing: 2.5) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(snapshot.currentStreakDays)D")
                            .font(KaruTheme.captionMono)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2.5)
                    .background(KaruTheme.recessedTray)
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5, antialiased: true)
                    )
                    .clipShape(Capsule(), style: FillStyle(antialiased: true))
                }

                // Primary Focus Hours & Linear Progress Bar
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(snapshot.formattedCompletedHours)
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(-0.5)
                        
                        Text("/ \(snapshot.formattedGoalHours)")
                            .font(KaruTheme.captionMono)
                            .foregroundColor(KaruTheme.textSecondary)
                    }

                    // Linear Quota Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 3.5)

                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(Color.white)
                                .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(snapshot.dailyProgressFraction))), height: 3.5)
                                .shadow(color: Color.white.opacity(snapshot.dailyProgressFraction > 0 ? 0.35 : 0.0), radius: 2)
                        }
                    }
                    .frame(height: 3.5)
                }

                Spacer(minLength: 2)

                // Secondary Metrics Grid
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1.5) {
                        Text("DISTANCE")
                            .font(KaruTheme.statLabel)
                            .foregroundColor(KaruTheme.textMuted)
                        Text(snapshot.formattedDistanceNM)
                            .font(KaruTheme.statValue)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 1.5) {
                        Text("EFFICIENCY")
                            .font(KaruTheme.statLabel)
                            .foregroundColor(KaruTheme.textMuted)
                        Text(snapshot.formattedEfficiency)
                            .font(KaruTheme.statValue)
                            .foregroundColor(.white)
                    }
                }
                .padding(6)
                .background(KaruTheme.recessedTray)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.04), lineWidth: 0.5, antialiased: true)
                )
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous), style: FillStyle(antialiased: true))

                // Fleet Tag
                HStack(spacing: 3) {
                    Image(systemName: "airplane")
                        .font(.system(size: 6.5, weight: .bold))
                        .foregroundColor(KaruTheme.textMuted)
                    Text("FLEET: \(snapshot.activeAircraftName)")
                        .font(KaruTheme.badgeText)
                        .foregroundColor(KaruTheme.textMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // MARK: - Center Divider Line
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1)
                .padding(.vertical, 4)

            // MARK: - Right Column: Active Flight Ops & 1-Click Action
            VStack(alignment: .leading, spacing: 6) {
                // Section Header
                Text("ACTIVE FLIGHT OPS")
                    .font(KaruTheme.statLabel)
                    .foregroundColor(KaruTheme.textMuted)
                    .tracking(0.9)

                // Route Display (Procedural Dot Matrix IATA Codes)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        DotMatrixTextView(
                            text: snapshot.originIATA,
                            dotSize: 1.6,
                            dotSpacing: 0.8,
                            activeColor: .white
                        )

                        Image(systemName: "airplane")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(KaruTheme.textMuted)

                        DotMatrixTextView(
                            text: snapshot.destinationIATA,
                            dotSize: 1.6,
                            dotSpacing: 0.8,
                            activeColor: .white
                        )
                    }

                    Text("\(snapshot.originCity.uppercased()) ➔ \(snapshot.destinationCity.uppercased())")
                        .font(KaruTheme.badgeText)
                        .foregroundColor(KaruTheme.textSecondary)
                        .lineLimit(1)
                }

                // Flight Status Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 4.5, height: 4.5)
                        .shadow(color: statusColor.opacity(0.8), radius: 3)

                    Text(snapshot.statusBadgeText)
                        .font(KaruTheme.badgeText)
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(KaruTheme.recessedTray)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5, antialiased: true)
                )
                .clipShape(Capsule(), style: FillStyle(antialiased: true))

                Spacer(minLength: 2)

                // 1-Click Interactive Action Button
                if isFlightActive {
                    Button(action: { onHoldAction?() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 7.5, weight: .bold))
                            Text("GATE HOLD")
                                .font(KaruTheme.captionMono)
                        }
                        .foregroundColor(KaruTheme.carbonMatte)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: { onTakeoffAction?() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "airplane")
                                .font(.system(size: 8, weight: .bold))
                            Text("TAKEOFF")
                                .font(KaruTheme.captionMono)
                        }
                        .foregroundColor(KaruTheme.carbonMatte)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

    private var isFlightActive: Bool {
        snapshot.state == .cruising || snapshot.state == .trafficStalled
    }

    private var statusColor: Color {
        switch snapshot.state {
        case .cruising:
            return Color.white
        case .trafficStalled:
            return Color(hex: 0xF59E0B) // Amber
        case .pitStop:
            return Color(hex: 0x3B82F6) // Hold blue
        case .completed:
            return Color.white
        case .idle:
            return KaruTheme.textMuted
        }
    }
}
