import SwiftUI
import KaruCore

/// Ultra-minimalist SpaceX Dragon-inspired Floating Telemetry HUD for macOS.
public struct FloatingHUDView: View {
    @Bindable public var engine: TransitEngine
    @Bindable public var scratchpadStore: ScratchpadStore
    public var onClose: (() -> Void)?

    @State private var isHovering: Bool = false
    @State private var isScratchpadExpanded: Bool = false
    @State private var isMapExpanded: Bool = false
    @State private var trajectoryProgress: CGFloat = 0.0

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
            // ── 1. SpaceX Mission Header ──
            HStack(spacing: 8) {
                // Flight Status Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(KaruTheme.statusGlow(for: engine.state))
                        .frame(width: 5, height: 5)
                    Text(KaruTheme.flightStage(for: engine.state))
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundStyle(KaruTheme.statusGlow(for: engine.state))
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(KaruTheme.surfaceElevated)
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(KaruTheme.cardBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 2))

                Text("KARU")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(KaruTheme.textPrimary)
                    .tracking(1.5)

                Spacer()

                // Velocity
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(engine.currentVelocity))")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundStyle(KaruTheme.statusGlow(for: engine.state))

                    Text("KM/H")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(KaruTheme.textMuted)
                }

                // Map Expand Toggle
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        isMapExpanded.toggle()
                        if isMapExpanded { isScratchpadExpanded = false }
                    }
                } label: {
                    Image(systemName: "map.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(isMapExpanded ? KaruTheme.telemetryCyan : KaruTheme.textMuted)
                }
                .buttonStyle(.plain)

                // Close Button
                if isHovering {
                    Button { onClose?() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(KaruTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)

            // 1px Trajectory Divider
            Rectangle()
                .fill(KaruTheme.stripeAccent(for: engine.state))
                .frame(height: 1)
                .shadow(color: KaruTheme.stripeAccent(for: engine.state).opacity(0.8), radius: 2)

            VStack(spacing: 6) {
                // ── 2. Laser Progress Trajectory Line ──
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(KaruTheme.surfaceElevated)
                            .frame(height: 2.5)

                        RoundedRectangle(cornerRadius: 1)
                            .fill(KaruTheme.telemetryCyan)
                            .frame(width: geo.size.width * trajectoryProgress, height: 2.5)
                            .shadow(color: KaruTheme.telemetryCyan.opacity(0.8), radius: 3)
                    }
                    .frame(height: 2.5)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                .frame(height: 4)

                // ── 3. Modular Telemetry Stats ──
                HStack(spacing: 4) {
                    if let session = engine.activeSession {
                        statPill(
                            value: "\(Int(session.cruisingDuration) / 60)M",
                            label: "FLIGHT",
                            color: KaruTheme.telemetryCyan
                        )

                        let efficiency = session.cruiseEfficiency
                        statPill(
                            value: "\(Int(efficiency))%",
                            label: "EFF",
                            color: efficiency >= 80 ? KaruTheme.telemetryGreen : KaruTheme.telemetryAmber
                        )

                        statPill(
                            value: "\(session.incidents.count)",
                            label: "HAZARDS",
                            color: session.incidents.isEmpty ? KaruTheme.textMuted : KaruTheme.telemetryRed
                        )
                    } else {
                        statPill(value: "--", label: "FLIGHT", color: KaruTheme.textMuted)
                        statPill(value: "--", label: "EFF", color: KaruTheme.textMuted)
                        statPill(value: "--", label: "HAZARDS", color: KaruTheme.textMuted)
                    }
                }

                // ── 4. Flight Actions ──
                HStack(spacing: 5) {
                    Button {
                        handlePrimaryAction()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: primaryActionIcon)
                                .font(.system(size: 8, weight: .bold))
                            Text(primaryActionLabel)
                                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(KaruTheme.telemetryCyan)
                        .foregroundStyle(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                    .buttonStyle(.plain)

                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isScratchpadExpanded.toggle()
                            if isScratchpadExpanded { isMapExpanded = false }
                        }
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "note.text").font(.system(size: 7))
                            Text("LOG").font(.system(size: 7, weight: .bold, design: .monospaced))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(KaruTheme.surfaceElevated)
                        .foregroundStyle(isScratchpadExpanded ? KaruTheme.telemetryCyan : KaruTheme.textSecondary)
                        .overlay(RoundedRectangle(cornerRadius: 2).stroke(KaruTheme.cardBorder, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            // ── 5. Expandable Panels (Map / Log) ──
            if isMapExpanded {
                VStack(spacing: 0) {
                    Rectangle().fill(KaruTheme.cardBorder).frame(height: 1)
                    LiveRouteTrackingView(engine: engine)
                        .frame(height: 130)
                        .padding(4)
                }
            }

            if isScratchpadExpanded {
                VStack(spacing: 0) {
                    Rectangle().fill(KaruTheme.cardBorder).frame(height: 1)
                    TextEditor(text: $scratchpadStore.notes)
                        .font(.system(size: 10, design: .monospaced))
                        .frame(height: 55)
                        .scrollContentBackground(.hidden)
                        .background(KaruTheme.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                        .padding(6)
                }
            }
        }
        .frame(width: isMapExpanded ? 300 : 250)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(KaruTheme.background.opacity(0.96))
                .shadow(color: Color.black.opacity(0.7), radius: 10, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(KaruTheme.cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .onChange(of: engine.activeSession?.progressFraction) { _, newVal in
            withAnimation(.easeInOut(duration: 0.5)) {
                trajectoryProgress = CGFloat(newVal ?? 0.0)
            }
        }
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 6.5, weight: .black, design: .monospaced))
                .foregroundStyle(KaruTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 3)
        .background(KaruTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(KaruTheme.cardBorder, lineWidth: 0.8))
    }

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
        case .idle: return "LAUNCH"
        case .cruising: return "HOLD"
        case .trafficStalled: return "REFOCUS"
        case .pitStop: return "RESUME"
        case .completed: return "NEW MISSION"
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
