import SwiftUI
import KaruCore

/// Animated horse mascot view that changes pose and expression based on Karu transit state.
///
/// States:
/// - **Galloping**: Running horse with speed lines (cruising / focused)
/// - **Stuck in Traffic**: Frustrated horse, sweating, shaking (distracted / gridlock)
/// - **Sleeping**: Peaceful horse curled up with Z's (idle / no session)
/// - **Pit Stop**: Horse sipping coffee (paused)
/// - **Completed**: Horse celebrating with trophy (arrived)
public struct KaruMascotView: View {
    let state: TransitState
    let size: CGFloat

    @State private var isAnimating = false

    public init(state: TransitState, size: CGFloat = 40) {
        self.state = state
        self.size = size
    }

    public var body: some View {
        ZStack {
            // Glow halo behind mascot
            Circle()
                .fill(
                    RadialGradient(
                        colors: [KaruTheme.statusGlow(for: state).opacity(0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size * 1.2, height: size * 1.2)

            // Mascot body
            ZStack {
                // Background circle
                Circle()
                    .fill(KaruTheme.surfaceElevated)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(KaruTheme.statusGlow(for: state).opacity(0.5), lineWidth: 1.5)
                    )

                // Horse emoji with state expression
                Text(KaruTheme.mascotEmoji(for: state))
                    .font(.system(size: size * 0.5))
                    .offset(x: stateOffset.x, y: stateOffset.y)
            }
            .modifier(StateAnimationModifier(state: state, isAnimating: isAnimating))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: state)
    }

    private var stateOffset: CGPoint {
        switch state {
        case .cruising: return CGPoint(x: 1, y: -1)
        case .trafficStalled: return CGPoint(x: 0, y: 0)
        case .idle: return CGPoint(x: 0, y: 1)
        case .pitStop: return CGPoint(x: 0, y: 0)
        case .completed: return CGPoint(x: 0, y: -2)
        }
    }
}

// MARK: - State Animation Modifier

private struct StateAnimationModifier: ViewModifier {
    let state: TransitState
    let isAnimating: Bool

    func body(content: Content) -> some View {
        switch state {
        case .cruising:
            content
                .offset(y: isAnimating ? -2 : 2) // Galloping bounce
                .scaleEffect(isAnimating ? 1.02 : 0.98)
        case .trafficStalled:
            content
                .offset(x: isAnimating ? -1.5 : 1.5) // Frustrated shake
                .rotationEffect(.degrees(isAnimating ? -2 : 2))
        case .idle:
            content
                .scaleEffect(isAnimating ? 0.95 : 1.0) // Gentle breathing
                .opacity(isAnimating ? 0.85 : 1.0)
        case .pitStop:
            content
                .rotationEffect(.degrees(isAnimating ? -3 : 0)) // Slight sway
        case .completed:
            content
                .offset(y: isAnimating ? -4 : 0) // Celebration bounce
                .scaleEffect(isAnimating ? 1.05 : 1.0)
        }
    }
}

// MARK: - Compact Mascot (Menu Bar / Inline)

/// Tiny inline mascot for menu bar and compact HUD contexts.
public struct KaruMascotInline: View {
    let state: TransitState
    let size: CGFloat

    public init(state: TransitState, size: CGFloat = 16) {
        self.state = state
        self.size = size
    }

    public var body: some View {
        Text(KaruTheme.mascotEmoji(for: state))
            .font(.system(size: size))
    }
}
