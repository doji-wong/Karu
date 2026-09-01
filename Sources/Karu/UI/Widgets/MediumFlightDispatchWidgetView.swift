import SwiftUI
import KaruCore

/// Direction A Monochrome Avionics Medium Widget (`systemMedium` — 338x158 pt).
/// Split-pane Flight Dispatch Board: Left pane displays today's certified flight performance;
/// Right pane displays active flight route telemetry and 1-click takeoff control.
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
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(KaruTheme.textMuted)
                        .tracking(0.8)

                    Spacer()

                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 7))
                            .foregroundColor(.white)
                        Text("\(snapshot.currentStreakDays)D")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                }

                // Primary Focus Hours & Linear Progress Bar
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(snapshot.formattedCompletedHours)
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("/ \(snapshot.formattedGoalHours)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(KaruTheme.textSecondary)
                    }

                    // Linear Quota Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white)
                                .frame(width: geo.size.width * CGFloat(snapshot.dailyProgressFraction), height: 4)
                        }
                    }
                    .frame(height: 4)
                }

                Spacer(minLength: 2)

                // Secondary Metrics Grid
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("DISTANCE")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(KaruTheme.textMuted)
                        Text(snapshot.formattedDistanceNM)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .leading, spacing: 1) {
                        Text("EFFICIENCY")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(KaruTheme.textMuted)
                        Text(snapshot.formattedEfficiency)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                .padding(6)
                .background(KaruTheme.recessedTray)
                .cornerRadius(6)

                // Fleet Tag
                Text("FLEET: \(snapshot.activeAircraftName)")
                    .font(.system(size: 7, weight: .medium, design: .monospaced))
                    .foregroundColor(KaruTheme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // MARK: - Center Divider Line
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1)
                .padding(.vertical, 4)

            // MARK: - Right Column: Active Flight Ops & 1-Click Action
            VStack(alignment: .leading, spacing: 6) {
                // Section Header
                Text("ACTIVE FLIGHT OPS")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(KaruTheme.textMuted)
                    .tracking(0.8)

                // Route Display (SFO ✈ HND)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(snapshot.originIATA)
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.white)

                        Image(systemName: "airplane")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(KaruTheme.textSecondary)

                        Text(snapshot.destinationIATA)
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                    }

                    Text("\(snapshot.originCity.uppercased()) ➔ \(snapshot.destinationCity.uppercased())")
                        .font(.system(size: 7, weight: .medium, design: .monospaced))
                        .foregroundColor(KaruTheme.textMuted)
                        .lineLimit(1)
                }

                // Flight Status Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 4, height: 4)

                    Text(snapshot.statusBadgeText)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(KaruTheme.recessedTray)
                .clipShape(Capsule())

                Spacer(minLength: 2)

                // 1-Click Interactive Action Button
                if isFlightActive {
                    Button(action: { onHoldAction?() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 8))
                            Text("GATE HOLD")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
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
                            Image(systemName: "airplane.departure")
                                .font(.system(size: 9, weight: .bold))
                            Text("TAKEOFF")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
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
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(KaruTheme.carbonMatte)
    }

    // MARK: - Helpers

    private var isFlightActive: Bool {
        snapshot.state == .cruising || snapshot.state == .trafficStalled
    }

    private var statusColor: Color {
        switch snapshot.state {
        case .cruising:
            return .white
        case .trafficStalled:
            return Color(hex: 0xF59E0B) // Amber
        case .pitStop:
            return Color(hex: 0x3B82F6) // Hold blue
        case .completed:
            return .white
        case .idle:
            return KaruTheme.textMuted
        }
    }
}
