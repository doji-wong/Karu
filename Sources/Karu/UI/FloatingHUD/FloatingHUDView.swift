import SwiftUI
import KaruCore

/// Tesla & Cybertruck-inspired Brutalist Floating HUD with PRND telemetry, vector vehicle, and route lane.
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
            // ── 1. Title Bar with Tesla PRND Selector ──
            titleBar

            // Neon Cybertruck accent divider
            Rectangle()
                .fill(KaruTheme.stripeAccent(for: engine.state))
                .frame(height: 1.5)
                .shadow(color: KaruTheme.stripeAccent(for: engine.state).opacity(0.6), radius: 3)

            VStack(spacing: 8) {
                // ── 2. Telemetry Gauge Row ──
                speedometerSection

                // ── 3. Route Progress Lane ──
                routeProgressLane

                // ── 4. Session Stats ──
                sessionStats

                // ── 5. Control Bar ──
                controlBar
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            // ── 6. Expandable Panels ──
            expandablePanels
        }
        .frame(width: isHighwayExpanded ? 320 : 270)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(KaruTheme.background.opacity(0.95))
                .shadow(color: Color.black.opacity(0.6), radius: 14, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(KaruTheme.cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
        HStack(spacing: 8) {
            // Mini PRND Gear Cluster
            TeslaGearSelectorView(state: engine.state, showEnergyBar: false)

            Text("KARU")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundStyle(KaruTheme.textPrimary)
                .tracking(1.5)

            Spacer()

            // State label
            Text(KaruTheme.stateSubtitle(for: engine.state))
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundStyle(KaruTheme.statusGlow(for: engine.state))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(KaruTheme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 3))

            // Highway toggle
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isHighwayExpanded.toggle()
                    if isHighwayExpanded { isScratchpadExpanded = false }
                }
            } label: {
                Image(systemName: "road.lanes.curved.right")
                    .font(.system(size: 10))
                    .foregroundStyle(isHighwayExpanded ? KaruTheme.cyberCyan : KaruTheme.textMuted)
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
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
    }

    // MARK: - 2. Speedometer Section

    private var speedometerSection: some View {
        HStack(alignment: .center, spacing: 10) {
            // Vector Vehicle Mini Twin
            VehicleDigitalTwinView(
                vehicle: engine.activeVehicle,
                state: engine.state,
                size: CGSize(width: 32, height: 50)
            )

            // Speedometer Digits
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(Int(engine.currentVelocity))")
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .foregroundStyle(KaruTheme.statusGlow(for: engine.state))

                    Text("KM/H")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(KaruTheme.textMuted)
                }

                Text(engine.activeVehicle.name.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(KaruTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Battery / Focus % Pill
            if let session = engine.activeSession {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(session.cruiseEfficiency))% EFF")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(KaruTheme.cyberCyan)

                    if let target = session.targetDuration {
                        let remaining = max(0, target - session.cruisingDuration)
                        let mins = Int(remaining) / 60
                        Text("\(mins)M LEFT")
                            .font(.system(size: 8, weight: .semibold, design: .monospaced))
                            .foregroundStyle(KaruTheme.textMuted)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(KaruTheme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(KaruTheme.cardBorder, lineWidth: 1))
            }
        }
    }

    // MARK: - 3. Route Progress Lane

    private var routeProgressLane: some View {
        VStack(spacing: 3) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Dark highway track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(KaruTheme.surfaceElevated)
                        .frame(height: 3.5)

                    // Autopilot Progress Beam
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [KaruTheme.cyberCyan, KaruTheme.cruiseEmerald],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * ringProgress, height: 3.5)
                        .shadow(color: KaruTheme.cyberCyan.opacity(0.6), radius: 3)
                }
                .frame(height: 3.5)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
            .frame(height: 6)
        }
    }

    // MARK: - 4. Session Stats

    private var sessionStats: some View {
        HStack(spacing: 4) {
            if let session = engine.activeSession {
                statPill(
                    value: "\(Int(session.cruisingDuration) / 60)M",
                    label: "FOCUS",
                    color: KaruTheme.cruiseEmerald
                )

                let efficiency = session.cruiseEfficiency
                statPill(
                    value: "\(Int(efficiency))%",
                    label: "EFF",
                    color: efficiency >= 80 ? KaruTheme.cyberCyan : KaruTheme.hazardAmber
                )

                statPill(
                    value: "\(session.incidents.count)",
                    label: "HAZARDS",
                    color: session.incidents.isEmpty ? KaruTheme.textMuted : KaruTheme.cyberOrange
                )
            } else {
                statPill(value: "--", label: "FOCUS", color: KaruTheme.textMuted)
                statPill(value: "--", label: "EFF", color: KaruTheme.textMuted)
                statPill(value: "--", label: "HAZARDS", color: KaruTheme.textMuted)
            }
        }
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 7, weight: .heavy, design: .monospaced))
                .foregroundStyle(KaruTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(KaruTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(KaruTheme.cardBorder, lineWidth: 0.8))
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
                        .font(.system(size: 9, weight: .bold))
                    Text(primaryActionLabel)
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    LinearGradient(
                        colors: [KaruTheme.cyberCyan, KaruTheme.cruiseEmerald],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 4))
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
                        .font(.system(size: 8))
                    Text("LOG")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(KaruTheme.surfaceElevated)
                .foregroundStyle(isScratchpadExpanded ? KaruTheme.cyberCyan : KaruTheme.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(KaruTheme.cardBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
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
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
            }
        }

        if isScratchpadExpanded {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(KaruTheme.cardBorder)
                    .frame(height: 1)
                TextEditor(text: $scratchpadStore.notes)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(height: 65)
                    .scrollContentBackground(.hidden)
                    .background(KaruTheme.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Helpers

    private var primaryActionIcon: String {
        switch engine.state {
        case .idle: return "bolt.fill"
        case .cruising: return "pause.fill"
        case .trafficStalled: return "arrow.forward"
        case .pitStop: return "play.fill"
        case .completed: return "arrow.counterclockwise"
        }
    }

    private var primaryActionLabel: String {
        switch engine.state {
        case .idle: return "START"
        case .cruising: return "PIT STOP"
        case .trafficStalled: return "REFOCUS"
        case .pitStop: return "RESUME"
        case .completed: return "NEW TRIP"
        }
    }

    private func handlePrimaryAction() {
        switch engine.state {
        case .idle:
            engine.startTrip()
        case .cruising:
            engine.togglePitStop()
        case .trafficStalled:
            break
        case .pitStop:
            engine.togglePitStop()
        case .completed:
            engine.cancelTrip()
        }
    }
}
