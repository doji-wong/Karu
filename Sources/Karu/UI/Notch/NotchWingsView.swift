import SwiftUI
import KaruCore

/// The Left telemetry wing flanking the MacBook camera notch (Flight Speed & Status).
public struct NotchLeftWingView: View {
    @Bindable public var engine: TransitEngine
    @State private var isHovering: Bool = false

    public init(engine: TransitEngine) {
        self.engine = engine
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: engine.state == .trafficStalled ? "wind" : (engine.state == .cruising ? "airplane.departure" : "airplane"))
                .foregroundStyle(statusColor)
                .font(.system(size: 11, weight: .bold))
                .symbolEffect(.pulse, options: .repeating, isActive: engine.state == .cruising)

            Text(engine.state == .cruising ? "540 kts" : (engine.state == .trafficStalled ? "HOLD" : "FL 288"))
                .font(KaruTheme.captionMono)
                .fontWeight(.bold)
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, isHovering ? 10 : 8)
        .padding(.vertical, isHovering ? 4 : 3)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
                .shadow(color: statusColor.opacity(isHovering ? 0.6 : 0.2), radius: isHovering ? 8 : 4)
        )
        .overlay(
            Capsule()
                .stroke(statusColor.opacity(isHovering ? 0.8 : 0.3), lineWidth: 1)
        )
        .scaleEffect(isHovering ? 1.06 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private var statusColor: Color {
        KaruTheme.statusGlow(for: engine.state)
    }
}

/// The Right telemetry wing flanking the MacBook camera notch (Route & Countdown).
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
                    let hours = mins / 60
                    let remMins = mins % 60
                    
                    if hours > 0 {
                        Text("\(hours)h \(remMins)m")
                            .font(KaruTheme.captionMono)
                            .foregroundStyle(KaruTheme.luminousLime)
                    } else {
                        Text("\(mins)m")
                            .font(KaruTheme.captionMono)
                            .foregroundStyle(KaruTheme.luminousLime)
                    }
                } else {
                    Text("Open Run")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.luminousLime)
                }
            } else {
                Text("YYZ ➔ HND")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
        .padding(.horizontal, isHovering ? 10 : 8)
        .padding(.vertical, isHovering ? 4 : 3)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
                .shadow(color: KaruTheme.luminousLime.opacity(isHovering ? 0.6 : 0.2), radius: isHovering ? 8 : 4)
        )
        .overlay(
            Capsule()
                .stroke(KaruTheme.luminousLime.opacity(isHovering ? 0.8 : 0.3), lineWidth: 1)
        )
        .scaleEffect(isHovering ? 1.06 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
