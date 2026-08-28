import SwiftUI
import KaruCore

/// SpaceX Crew Dragon & Starship-inspired Top Mission Telemetry Bar.
public struct SpaceXTelemetryHeader: View {
    let state: TransitState
    let velocity: Double
    let activeSession: TripSession?

    public init(state: TransitState, velocity: Double, activeSession: TripSession?) {
        self.state = state
        self.velocity = velocity
        self.activeSession = activeSession
    }

    public var body: some View {
        HStack(spacing: 8) {
            // Stage Status Indicator
            HStack(spacing: 5) {
                Circle()
                    .fill(KaruTheme.statusGlow(for: state))
                    .frame(width: 6, height: 6)
                    .shadow(color: KaruTheme.statusGlow(for: state).opacity(0.8), radius: 3)

                Text(KaruTheme.flightStage(for: state))
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(KaruTheme.statusGlow(for: state))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(KaruTheme.surfaceElevated)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(KaruTheme.cardBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 3))

            // Mission Clock (T+ Elapsed)
            if let session = activeSession {
                HStack(spacing: 3) {
                    Text("T+")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(KaruTheme.textMuted)
                    Text(formattedElapsed(session.cruisingDuration))
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundStyle(KaruTheme.textPrimary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(KaruTheme.surfaceElevated)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(KaruTheme.cardBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 3))
            }

            Spacer()

            // Big Speed Telemetry Readout
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(Int(velocity))")
                    .font(KaruTheme.velocityDisplay)
                    .foregroundStyle(KaruTheme.statusGlow(for: state))

                Text("KM/H")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(KaruTheme.textMuted)
            }
        }
    }

    private func formattedElapsed(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

/// Modular 3-Box Aerospace Telemetry Readout Grid.
public struct SpaceXTelemetryGrid: View {
    let session: TripSession?
    let targetDistanceKm: Double?

    public init(session: TripSession?, targetDistanceKm: Double? = nil) {
        self.session = session
        self.targetDistanceKm = targetDistanceKm
    }

    public var body: some View {
        HStack(spacing: 6) {
            // Box 1: Distance
            telemetryBox(
                title: "DISTANCE COVERED",
                value: distanceValue,
                unit: "KM",
                valueColor: KaruTheme.textPrimary
            )

            // Box 2: ETA / Time Remaining
            telemetryBox(
                title: "ETA REMAINING",
                value: etaValue,
                unit: "MIN",
                valueColor: KaruTheme.telemetryCyan
            )

            // Box 3: Flight Anomalies / Incidents
            telemetryBox(
                title: "ANOMALIES / HAZARDS",
                value: "\(session?.incidents.count ?? 0)",
                unit: session?.incidents.isEmpty ?? true ? "NOMINAL" : "STALLS",
                valueColor: session?.incidents.isEmpty ?? true ? KaruTheme.textSecondary : KaruTheme.telemetryRed
            )
        }
    }

    private func telemetryBox(title: String, value: String, unit: String, valueColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                .foregroundStyle(KaruTheme.textMuted)
                .tracking(0.6)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(valueColor)

                Text(unit)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(KaruTheme.textMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(KaruTheme.surfaceElevated)
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(KaruTheme.cardBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var distanceValue: String {
        guard let s = session else { return "0.0" }
        return String(format: "%.1f", s.distanceTraveledKm)
    }

    private var etaValue: String {
        guard let s = session, let target = s.targetDuration else { return "--" }
        let remaining = max(0, target - s.cruisingDuration)
        let mins = Int(remaining) / 60
        return "\(mins)"
    }
}
