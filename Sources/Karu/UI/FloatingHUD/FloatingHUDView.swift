import SwiftUI
import KaruCore

/// Floating Avionics Flight HUD View for macOS.
/// Embeds the official Direction A flight card directly into a draggable floating overlay with dynamic hover expansion.
public struct FloatingHUDView: View {
    @Bindable public var engine: TransitEngine
    public var onClose: (() -> Void)?

    @State private var isHovering: Bool = false

    public init(
        engine: TransitEngine,
        onClose: (() -> Void)? = nil
    ) {
        self.engine = engine
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                FocusFlightCard(
                    state: engine.state,
                    velocity: engine.currentVelocity,
                    activeSession: engine.activeSession,
                    aircraft: engine.activeAircraft,
                    onStart: { preset, customDuration in
                        engine.startTrip(preset: preset, customDuration: customDuration)
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
                        onClose?()
                    }
                )

                // Close button overlay on hover
                if isHovering {
                    Button {
                        onClose?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(KaruTheme.textMuted)
                            .padding(10)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }
            }
            Spacer(minLength: 0)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}
