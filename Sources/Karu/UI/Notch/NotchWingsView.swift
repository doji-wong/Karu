import SwiftUI
import KaruCore

/// The dual telemetry wings flanking the MacBook camera notch.
public struct NotchLeftWingView: View {
    @Bindable public var engine: TransitEngine

    public init(engine: TransitEngine) {
        self.engine = engine
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: engine.state == .trafficStalled ? "exclamationmark.triangle.fill" : "bolt.car.fill")
                .foregroundStyle(KaruTheme.statusGlow(for: engine.state))
                .font(.system(size: 11, weight: .bold))

            Text("\(Int(engine.currentVelocity))")
                .font(KaruTheme.captionMono)
                .fontWeight(.bold)
                .foregroundStyle(KaruTheme.statusGlow(for: engine.state))

            Text("km/h")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(KaruTheme.textMuted)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.85))
        .clipShape(Capsule())
    }
}

public struct NotchRightWingView: View {
    @Bindable public var engine: TransitEngine

    public init(engine: TransitEngine) {
        self.engine = engine
    }

    public var body: some View {
        HStack(spacing: 5) {
            if let session = engine.activeSession {
                if let target = session.targetDuration {
                    let remaining = max(0, target - session.cruisingDuration)
                    let mins = Int(remaining) / 60
                    Text("📍 \(mins)m")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.navCyan)
                } else {
                    Text("📍 Open")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.navCyan)
                }

                if let habitName = session.habitName {
                    Text("· \(habitName)")
                        .font(.system(size: 10))
                        .foregroundStyle(KaruTheme.textSecondary)
                        .lineLimit(1)
                }
            } else {
                Text("Karu")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.textMuted)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.85))
        .clipShape(Capsule())
    }
}
