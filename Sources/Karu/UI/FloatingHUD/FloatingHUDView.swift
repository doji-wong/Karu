import SwiftUI
import KaruCore

/// Floating Avionics Flight HUD View for macOS.
/// Primarily renders as an ultra-compact minimalist plane progress bar with route-anchored runway
/// and Style 2 monochrome dual seat badge (strictly zero emojis), with optional 1-click expansion.
public struct FloatingHUDView: View {
    @Bindable public var engine: TransitEngine
    public var onClose: (() -> Void)?
    public var onSizeChange: ((CGFloat, CGFloat) -> Void)?

    @State private var isHovering: Bool = false
    @State private var isExpandedToFullCard: Bool = false

    public init(
        engine: TransitEngine,
        onClose: (() -> Void)? = nil,
        onSizeChange: ((CGFloat, CGFloat) -> Void)? = nil
    ) {
        self.engine = engine
        self.onClose = onClose
        self.onSizeChange = onSizeChange
    }

    // MARK: - Telemetry Helpers

    private var progress: Double {
        if let session = engine.activeSession {
            return min(1.0, max(0.0, session.progressFraction))
        }
        return engine.state == .cruising ? 0.42 : (engine.state == .completed ? 1.0 : 0.0)
    }

    private var remainingTimeNegativeFormatted: String {
        if let session = engine.activeSession, let target = session.targetDuration {
            let remaining: Double = max(0.0, target - session.cruisingDuration)
            let hours: Int = Int(remaining) / 3600
            let mins: Int = (Int(remaining) % 3600) / 60
            let secs: Int = Int(remaining) % 60
            if hours > 0 {
                return String(format: "-%dH %02dM", hours, mins)
            } else {
                return String(format: "-%02dM %02dS", mins, secs)
            }
        }
        return "-25M 00S"
    }

    private var seatBadgeText: String {
        let code = engine.activeSeatCode.isEmpty ? "5F" : engine.activeSeatCode.uppercased()
        let title = engine.activeTaskTitle.isEmpty ? "CODING" : engine.activeTaskTitle.uppercased()
        return "\(code) · \(title)"
    }

    public var body: some View {
        Group {
            if isExpandedToFullCard {
                expandedCardView
            } else {
                compactFlightPillView
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    // MARK: - Compact Minimalist Plane Progress Bar Pill

    @ViewBuilder
    private var compactFlightPillView: some View {
        HStack(spacing: 7) {
            // 1. Style 2 Dual Seat Badge (Zero Emojis, Pure SF Symbol & Monospaced Typography)
            HStack(spacing: 3.5) {
                Image(systemName: engine.activeSeatIcon.isEmpty ? "curlybraces" : engine.activeSeatIcon)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.white)
                Text(seatBadgeText)
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3.5)
            .background(
                Capsule()
                    .fill(KaruTheme.recessedTray)
                    .overlay(
                        Capsule().strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5, antialiased: true)
                    )
            )

            // 2. Route-Anchored Runway (Origin ✈ Destination)
            HStack(spacing: 4) {
                Text(engine.activeOrigin)
                    .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.65))

                LuminousSliderTrackView(
                    progress: progress,
                    state: engine.state,
                    remainingText: remainingTimeNegativeFormatted
                )
                .frame(height: 28)

                Text(engine.activeDestination)
                    .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color.white)
            }

            // 3. Quick Action Controls
            HStack(spacing: 3) {
                if engine.state != .idle && engine.state != .completed {
                    Button {
                        engine.toggleGateHold()
                    } label: {
                        Image(systemName: engine.state == .pitStop ? "play.fill" : "pause.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color.white)
                            .padding(4)
                            .background(Circle().fill(KaruTheme.recessedTray))
                    }
                    .buttonStyle(.plain)
                    .help(engine.state == .pitStop ? "Resume Cruise" : "Gate Hold")
                }

                // Expand to Full Cockpit Flight Card
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        isExpandedToFullCard = true
                        onSizeChange?(372, 156)
                    }
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundStyle(KaruTheme.textMuted)
                        .padding(4)
                        .background(Circle().fill(KaruTheme.recessedTray))
                }
                .buttonStyle(.plain)
                .help("Expand to Full Flight HUD")

                // Close Button on Hover
                if isHovering {
                    Button {
                        onClose?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundStyle(KaruTheme.textMuted)
                            .padding(4)
                            .background(Circle().fill(KaruTheme.recessedTray))
                    }
                    .buttonStyle(.plain)
                    .help("Dismiss Floating HUD")
                    .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(width: 390, height: 40)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(KaruTheme.carbonMatte)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5, antialiased: true)
                )
                .shadow(color: Color.black.opacity(0.55), radius: 8, x: 0, y: 3)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous), style: FillStyle(antialiased: true))
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isExpandedToFullCard = true
                onSizeChange?(372, 156)
            }
        }
    }

    // MARK: - Full Flight Card View

    @ViewBuilder
    private var expandedCardView: some View {
        ZStack(alignment: .topTrailing) {
            FocusFlightCard(
                state: engine.state,
                velocity: engine.currentVelocity,
                activeSession: engine.activeSession,
                aircraft: engine.activeAircraft,
                onStartFlight: { preset, customDuration, origin, destination, seatCode, taskTitle, seatIcon in
                    engine.startTrip(
                        preset: preset,
                        customDuration: customDuration,
                        origin: origin,
                        destination: destination,
                        seatCode: seatCode,
                        taskTitle: taskTitle,
                        seatIcon: seatIcon
                    )
                },
                onHold: {
                    engine.toggleGateHold()
                },
                onDock: {
                    engine.completeTrip()
                },
                onAbort: {
                    engine.cancelTrip()
                },
                onToggleFloatingHUD: {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        isExpandedToFullCard = false
                        onSizeChange?(390, 40)
                    }
                }
            )

            // Collapse & Close Header Overlay
            HStack(spacing: 4) {
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        isExpandedToFullCard = false
                        onSizeChange?(390, 40)
                    }
                } label: {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundStyle(KaruTheme.textMuted)
                        .padding(5)
                        .background(Circle().fill(KaruTheme.recessedTray))
                }
                .buttonStyle(.plain)
                .help("Collapse to Minimalist Progress Bar")

                if isHovering {
                    Button {
                        onClose?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundStyle(KaruTheme.textMuted)
                            .padding(5)
                            .background(Circle().fill(KaruTheme.recessedTray))
                    }
                    .buttonStyle(.plain)
                    .help("Dismiss Floating HUD")
                    .transition(.opacity)
                }
            }
            .padding(10)
        }
    }
}
