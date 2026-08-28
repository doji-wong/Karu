import SwiftUI
import KaruCore

/// The Left telemetry wing flanking the MacBook camera notch (Speedometer).
public struct NotchLeftWingView: View {
    @Bindable public var engine: TransitEngine
    @State private var isHovering: Bool = false

    public init(engine: TransitEngine) {
        self.engine = engine
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: engine.state == .trafficStalled ? "exclamationmark.triangle.fill" : "bolt.car.fill")
                .foregroundStyle(KaruTheme.statusGlow(for: engine.state))
                .font(.system(size: 11, weight: .bold))
                .symbolEffect(.pulse, options: .repeating, isActive: engine.state == .cruising)

            Text("\(Int(engine.currentVelocity))")
                .font(KaruTheme.captionMono)
                .fontWeight(.bold)
                .foregroundStyle(KaruTheme.statusGlow(for: engine.state))

            Text("km/h")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(KaruTheme.textMuted)
        }
        .padding(.horizontal, isHovering ? 10 : 8)
        .padding(.vertical, isHovering ? 4 : 3)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
                .shadow(color: KaruTheme.statusGlow(for: engine.state).opacity(isHovering ? 0.6 : 0.2), radius: isHovering ? 8 : 4)
        )
        .overlay(
            Capsule()
                .stroke(KaruTheme.statusGlow(for: engine.state).opacity(isHovering ? 0.8 : 0.3), lineWidth: 1)
        )
        .scaleEffect(isHovering ? 1.06 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

/// The Right telemetry wing flanking the MacBook camera notch (Route Progress).
public struct NotchRightWingView: View {
    @Bindable public var engine: TransitEngine
    @State private var isHovering: Bool = false

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
        .padding(.horizontal, isHovering ? 10 : 8)
        .padding(.vertical, isHovering ? 4 : 3)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
                .shadow(color: KaruTheme.navCyan.opacity(isHovering ? 0.6 : 0.2), radius: isHovering ? 8 : 4)
        )
        .overlay(
            Capsule()
                .stroke(KaruTheme.navCyan.opacity(isHovering ? 0.8 : 0.3), lineWidth: 1)
        )
        .scaleEffect(isHovering ? 1.06 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
