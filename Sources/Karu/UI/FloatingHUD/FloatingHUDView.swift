import SwiftUI
import KaruCore

/// Premium floating HUD with racing livery design, horse mascot, speedometer ring, and route progress lane.
public struct FloatingHUDView: View {
    @Bindable public var engine: TransitEngine
    @Bindable public var scratchpadStore: ScratchpadStore
    public var onClose: (() -> Void)?

    @State private var isHovering: Bool = false
    @State private var isScratchpadExpanded: Bool = false
    @State private var isHighwayExpanded: Bool = false
    @State private var ringProgress: CGFloat = 0.0

    public init(
        engine: TransitEngine,
        scratchpadStore: ScratchpadStore,
        onClose: (() -> Void)? = nil
    ) {
        self.engine = engine
        self.scratchpadStore = scratchpadStore
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // ── 1. Title Bar with Mascot & Racing Stripe ──
            titleBar

            // Racing stripe accent
            Rectangle()
                .fill(KaruTheme.stripeAccent(for: engine.state))
                .frame(height: 2)
                .shadow(color: KaruTheme.stripeAccent(for: engine.state).opacity(0.6), radius: 4)

            VStack(spacing: 10) {
                // ── 2. Speedometer Ring with Mascot ──
                speedometerSection

                // ── 3. Route Progress Lane ──
                routeProgressLane

                // ── 4. Session Stats ──
                sessionStats

                // ── 5. Control Bar ──
                controlBar
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            // ── 6. Expandable Panels ──
            expandablePanels
        }
        .frame(width: isHighwayExpanded ? 320 : 280)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(KaruTheme.background.opacity(0.94))
                .shadow(color: Color.black.opacity(0.55), radius: 16, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(KaruTheme.cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onChange(of: engine.activeSession?.progressFraction) { _, newVal in
            withAnimation(.easeInOut(duration: 0.5)) {
                ringProgress = CGFloat(newVal ?? 0.0)
            }
        }
    }

    // MARK: - 1. Title Bar

    private var titleBar: some View {
        HStack(spacing: 6) {
            // Mascot head
            KaruMascotInline(state: engine.state, size: 14)

            // KARU wordmark
            Text("KARU")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(KaruTheme.textPrimary)
                .tracking(2)

            Spacer()

            // State label
            Text(stateLabel)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(KaruTheme.statusGlow(for: engine.state))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(KaruTheme.statusGlow(for: engine.state).opacity(0.12))
                .clipShape(Capsule())

            // Highway toggle
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isHighwayExpanded.toggle()
                    if isHighwayExpanded { isScratchpadExpanded = false }
                }
            } label: {
                Image(systemName: "road.lanes.curved.right")
                    .font(.system(size: 10))
                    .foregroundStyle(isHighwayExpanded ? KaruTheme.racingTeal : KaruTheme.textMuted)
            }
            .buttonStyle(.plain)

            // Close button (on hover)
            if isHovering {
                Button { onClose?() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(KaruTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    // MARK: - 2. Speedometer Ring

    private var speedometerSection: some View {
        HStack(spacing: 12) {
            // Mascot with glow
            KaruMascotView(state: engine.state, size: 44)

            // Speedometer ring
            ZStack {
                // Track ring
                Circle()
                    .stroke(KaruTheme.surfaceElevated, lineWidth: 5)
                    .frame(width: 76, height: 76)

                // Progress ring
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        KaruTheme.statusGlow(for: engine.state),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 76, height: 76)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: KaruTheme.statusGlow(for: engine.state).opacity(0.4), radius: 6)

                // Velocity text
                VStack(spacing: 0) {
                    Text("\(Int(ringProgress * 100))%")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(KaruTheme.statusGlow(for: engine.state))

                    Text("\(Int(engine.currentVelocity))")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(KaruTheme.textPrimary)

                    Text("km/h")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(KaruTheme.textMuted)
                }
            }

            Spacer()
        }
    }

    // MARK: - 3. Route Progress Lane

    private var routeProgressLane: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                // Origin pin
                Circle()
                    .fill(KaruTheme.cruiseEmerald)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1))

                // Road progress track
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Gray road
                        RoundedRectangle(cornerRadius: 2)
                            .fill(KaruTheme.surfaceElevated)
                            .frame(height: 4)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [KaruTheme.racingTeal, KaruTheme.cruiseEmerald],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * ringProgress, height: 4)
                            .shadow(color: KaruTheme.cruiseEmerald.opacity(0.5), radius: 4)

                        // Road lane dashes
                        ForEach(0..<8, id: \.self) { i in
                            Rectangle()
                                .fill(KaruTheme.textMuted.opacity(0.3))
                                .frame(width: 6, height: 1)
                                .offset(x: geo.size.width * CGFloat(i) / 8.0)
                        }
                    }
                    .frame(height: 4)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                .frame(height: 8)

                // Destination flag
                Text("🏁")
                    .font(.system(size: 8))
            }

            // ETA label
            if let session = engine.activeSession {
                HStack {
                    Spacer()
                    if let target = session.targetDuration {
                        let remaining = max(0, target - session.cruisingDuration)
                        let mins = Int(remaining) / 60
                        Text("\(mins)m away")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(KaruTheme.racingTeal)
                    } else {
                        Text("En route")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(KaruTheme.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - 4. Session Stats

    private var sessionStats: some View {
        HStack(spacing: 6) {
            if let session = engine.activeSession {
                // Duration
                statPill(
                    value: "\(Int(session.cruisingDuration) / 60)m",
                    label: "focus",
                    color: KaruTheme.cruiseEmerald
                )

                // Efficiency
                let efficiency = session.cruiseEfficiency
                statPill(
                    value: "\(Int(efficiency))%",
                    label: "efficiency",
                    color: efficiency >= 80 ? KaruTheme.cruiseEmerald : KaruTheme.hazardAmber
                )

                // Incidents
                statPill(
                    value: "\(session.incidents.count)",
                    label: "incidents",
                    color: session.incidents.isEmpty ? KaruTheme.textMuted : KaruTheme.hotCoral
                )
            } else {
                statPill(value: "--", label: "focus", color: KaruTheme.textMuted)
                statPill(value: "--", label: "efficiency", color: KaruTheme.textMuted)
                statPill(value: "--", label: "incidents", color: KaruTheme.textMuted)
            }
        }
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(KaruTheme.statValue)
                .foregroundStyle(color)
            Text(label)
                .font(KaruTheme.statLabel)
                .foregroundStyle(KaruTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(KaruTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - 5. Control Bar

    private var controlBar: some View {
        HStack(spacing: 6) {
            // Primary action button
            Button {
                handlePrimaryAction()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: primaryActionIcon)
                        .font(.system(size: 10, weight: .bold))
                    Text(primaryActionLabel)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(KaruTheme.racingTeal)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // Pit Stop / Scratchpad
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isScratchpadExpanded.toggle()
                    if isScratchpadExpanded { isHighwayExpanded = false }
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "note.text")
                        .font(.system(size: 9))
                    Text("Notes")
                        .font(.system(size: 9, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(KaruTheme.surfaceElevated)
                .foregroundStyle(isScratchpadExpanded ? KaruTheme.racingTeal : KaruTheme.textSecondary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(KaruTheme.cardBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Vehicle indicator
            KaruMascotInline(state: engine.state, size: 12)
        }
    }

    // MARK: - 6. Expandable Panels

    @ViewBuilder
    private var expandablePanels: some View {
        if isHighwayExpanded {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(KaruTheme.cardBorder)
                    .frame(height: 1)
                HighwayNavigationView(engine: engine)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
            }
        }

        if isScratchpadExpanded {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(KaruTheme.cardBorder)
                    .frame(height: 1)
                TextEditor(text: $scratchpadStore.notes)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(height: 70)
                    .scrollContentBackground(.hidden)
                    .background(KaruTheme.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
        }
    }

    // MARK: - Helpers

    private var stateLabel: String {
        switch engine.state {
        case .cruising: return "CRUISING"
        case .trafficStalled: return "GRIDLOCK"
        case .pitStop: return "PIT STOP"
        case .idle: return "IDLE"
        case .completed: return "ARRIVED"
        }
    }

    private var primaryActionIcon: String {
        switch engine.state {
        case .idle: return "play.fill"
        case .cruising: return "cup.and.saucer.fill"
        case .trafficStalled: return "arrow.forward"
        case .pitStop: return "play.fill"
        case .completed: return "arrow.counterclockwise"
        }
    }

    private var primaryActionLabel: String {
        switch engine.state {
        case .idle: return "Start Trip"
        case .cruising: return "Pit Stop"
        case .trafficStalled: return "Refocus"
        case .pitStop: return "Resume"
        case .completed: return "New Trip"
        }
    }

    private func handlePrimaryAction() {
        switch engine.state {
        case .idle:
            engine.startTrip()
        case .cruising:
            engine.togglePitStop()
        case .trafficStalled:
            // The user needs to switch back to a focus app
            break
        case .pitStop:
            engine.togglePitStop()
        case .completed:
            engine.cancelTrip() // Reset to idle
        }
    }
}
