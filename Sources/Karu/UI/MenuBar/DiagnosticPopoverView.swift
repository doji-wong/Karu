import SwiftUI
import KaruCore

/// Tesla & Cybertruck-inspired Cockpit Diagnostic Dashboard popover for Menu Bar & Notch.
public struct DiagnosticPopoverView: View {
    @Bindable public var engine: TransitEngine
    @Bindable public var scratchpadStore: ScratchpadStore
    public var audioEngine: AudioEngine
    public var storage: LocalStorageManager
    public var onToggleFloatingHUD: (() -> Void)?
    public var onOpenGarage: (() -> Void)?
    public var onOpenSettings: (() -> Void)?

    @State private var selectedPreset: TripPreset = .cityDash25
    @State private var selectedHabitId: UUID?
    @State private var habits: [Habit] = []
    @State private var activeTab: Int = 0

    public init(
        engine: TransitEngine,
        scratchpadStore: ScratchpadStore,
        audioEngine: AudioEngine,
        storage: LocalStorageManager,
        onToggleFloatingHUD: (() -> Void)? = nil,
        onOpenGarage: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil
    ) {
        self.engine = engine
        self.scratchpadStore = scratchpadStore
        self.audioEngine = audioEngine
        self.storage = storage
        self.onToggleFloatingHUD = onToggleFloatingHUD
        self.onOpenGarage = onOpenGarage
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top Tesla Telemetry & PRND Header
            telemetryHeader
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)
            
            // Neon accent divider line
            Rectangle()
                .fill(KaruTheme.stripeAccent(for: engine.state))
                .frame(height: 1.5)
                .shadow(color: KaruTheme.stripeAccent(for: engine.state).opacity(0.6), radius: 4)

            // Dynamic Content
            if engine.state == .idle {
                idleLauncherSection
                    .padding(14)
            } else {
                activeFlightSection
                    .padding(14)
            }

            Rectangle()
                .fill(KaruTheme.cardBorder)
                .frame(height: 1)

            // Bottom Utility Toolbar
            bottomToolbar
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        }
        .frame(width: 380)
        .background(KaruTheme.background)
        .onAppear {
            self.habits = storage.loadHabits()
        }
    }

    // MARK: - 1. Telemetry & PRND Header
    private var telemetryHeader: some View {
        HStack(alignment: .center, spacing: 10) {
            // Tesla PRND Gear Cluster + Battery Focus Bar
            TeslaGearSelectorView(
                state: engine.state,
                showEnergyBar: true,
                focusFraction: engine.activeSession?.progressFraction ?? 1.0
            )

            Spacer()

            // Digital Speedometer Readout
            VStack(alignment: .trailing, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(Int(engine.currentVelocity))")
                        .font(KaruTheme.velocityDisplay)
                        .foregroundStyle(KaruTheme.statusGlow(for: engine.state))

                    Text("KM/H")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.textMuted)
                }

                Text(KaruTheme.stateSubtitle(for: engine.state))
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(KaruTheme.statusGlow(for: engine.state))
            }
        }
    }

    // MARK: - 2. Idle Launcher (Cybertruck Non-Truncating Route Preset Cards)
    private var idleLauncherSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MISSION OBJECTIVE / ROUTE")
                    .font(KaruTheme.statLabel)
                    .foregroundStyle(KaruTheme.textMuted)
                    .tracking(1.2)

                Spacer()

                Text(engine.activeVehicle.name.uppercased())
                    .font(KaruTheme.statLabel)
                    .foregroundStyle(KaruTheme.cyberCyan)
                    .tracking(1.0)
            }

            // 2x2 Preset Grid with 100% Crisp Non-Truncated Badges
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(TripPreset.allCases) { preset in
                    let isSelected = selectedPreset == preset
                    Button {
                        selectedPreset = preset
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            // Top Row: Title + Duration Tag
                            HStack {
                                Text(presetShortTitle(preset))
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(isSelected ? Color.white : KaruTheme.textPrimary)

                                Spacer()

                                Text(presetDurationTag(preset))
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(isSelected ? KaruTheme.cyberCyan : KaruTheme.surfaceElevated)
                                    .foregroundStyle(isSelected ? Color.black : KaruTheme.cyberCyan)
                                    .clipShape(Capsule())
                            }

                            // Bottom Row: Distance Subtitle
                            if let dist = preset.targetDistanceKm {
                                Text("\(Int(dist)) KM CRUISE")
                                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(isSelected ? KaruTheme.cyberCyan : KaruTheme.textSecondary)
                            } else {
                                Text("UNCAPPED FLOW")
                                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(KaruTheme.textMuted)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(isSelected ? KaruTheme.surfaceElevated : KaruTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? KaruTheme.cyberCyan : KaruTheme.cardBorder, lineWidth: isSelected ? 1.5 : 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Habit Linker (Optional)
            if !habits.isEmpty {
                Menu {
                    Button("None (Quick Trip)") { selectedHabitId = nil }
                    ForEach(habits) { habit in
                        Button("\(habit.name) (\(habit.currentStreakDays)d streak)") {
                            selectedHabitId = habit.id
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 10))
                        Text(habits.first(where: { $0.id == selectedHabitId })?.name ?? "Link Daily Habit Target...")
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10))
                    }
                    .font(KaruTheme.subheadline)
                    .foregroundStyle(KaruTheme.textSecondary)
                    .padding(9)
                    .background(KaruTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(KaruTheme.cardBorder, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .menuStyle(.borderlessButton)
            }

            // Cybertruck-style START TRIP Action Bar
            Button {
                let linkedHabit = habits.first(where: { $0.id == selectedHabitId })
                engine.startTrip(preset: selectedPreset, habit: linkedHabit)
                audioEngine.start()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .black))
                    Text("ENGAGE AUTOPILOT · START TRIP")
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .tracking(1.0)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [KaruTheme.cyberCyan, KaruTheme.cruiseEmerald],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundStyle(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: KaruTheme.cyberCyan.opacity(0.4), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 3. Active Flight Section
    private var activeFlightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let session = engine.activeSession {
                // Highway Perspective Road with Vector Vehicle
                HighwayNavigationView(engine: engine)

                // In-Flight Scratchpad Tab Selector
                Picker("", selection: $activeTab) {
                    Text("Scratchpad").tag(0)
                    Text("Traffic Hazards (\(session.incidents.count))").tag(1)
                }
                .pickerStyle(.segmented)

                if activeTab == 0 {
                    // Live Scratchpad Editor
                    VStack(alignment: .trailing, spacing: 4) {
                        TextEditor(text: $scratchpadStore.notes)
                            .font(.system(size: 11, design: .monospaced))
                            .frame(height: 80)
                            .scrollContentBackground(.hidden)
                            .background(KaruTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(KaruTheme.cardBorder, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        Text("Local-first atomic persistence")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(KaruTheme.textMuted)
                    }
                } else {
                    // Incident Log List
                    ScrollView {
                        VStack(spacing: 6) {
                            if session.incidents.isEmpty {
                                Text("Clear highway. Zero traffic stalls detected.")
                                    .font(KaruTheme.subheadline)
                                    .foregroundStyle(KaruTheme.textMuted)
                                    .padding(.vertical, 16)
                            } else {
                                ForEach(session.incidents) { inc in
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(KaruTheme.cyberOrange)
                                        Text(inc.appName)
                                            .font(KaruTheme.subheadline)
                                            .foregroundStyle(KaruTheme.textPrimary)
                                        Spacer()
                                        Text("\(Int(inc.duration))s stall")
                                            .font(KaruTheme.captionMono)
                                            .foregroundStyle(KaruTheme.hazardRed)
                                    }
                                    .padding(8)
                                    .background(KaruTheme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                        }
                    }
                    .frame(height: 95)
                }

                // Active Trip Controls
                HStack(spacing: 8) {
                    // Pit Stop Button
                    Button {
                        engine.togglePitStop()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: engine.state == .pitStop ? "play.fill" : "pause.fill")
                            Text(engine.state == .pitStop ? "RESUME" : "PIT STOP")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(KaruTheme.surfaceElevated)
                        .foregroundStyle(engine.state == .pitStop ? KaruTheme.hazardAmber : KaruTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(KaruTheme.cardBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    // Arrive Early Button
                    Button {
                        engine.completeTrip()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "flag.checkered")
                            Text("ARRIVE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(KaruTheme.cruiseEmerald)
                        .foregroundStyle(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)

                    // Cancel / Eject Trip
                    Button {
                        engine.cancelTrip()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .padding(8)
                            .background(KaruTheme.surface)
                            .foregroundStyle(KaruTheme.textSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(KaruTheme.cardBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 4. Bottom Utility Toolbar
    private var bottomToolbar: some View {
        HStack(spacing: 12) {
            // Ambient Audio Volume Slider
            HStack(spacing: 6) {
                Button {
                    audioEngine.toggleMute()
                } label: {
                    Image(systemName: audioEngine.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(audioEngine.isMuted ? KaruTheme.textMuted : KaruTheme.cyberCyan)
                }
                .buttonStyle(.plain)

                Slider(
                    value: Binding(
                        get: { Double(audioEngine.masterVolume) },
                        set: { audioEngine.masterVolume = Float($0) }
                    ),
                    in: 0.0...1.0
                )
                .frame(width: 80)
            }

            Spacer()

            // Floating HUD Overlay Toggle
            Button {
                onToggleFloatingHUD?()
            } label: {
                Image(systemName: "pip.badge.plus")
                    .font(.system(size: 12))
                    .foregroundStyle(KaruTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Toggle Minimal Floating HUD")

            // Garage Button
            Button {
                onOpenGarage?()
            } label: {
                Image(systemName: "car.2.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(KaruTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Open Karu Vehicle Garage")

            // Settings Button
            Button {
                onOpenSettings?()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(KaruTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Filter Rules & Preferences")
        }
    }

    // MARK: - Preset Formatting Helpers

    private func presetShortTitle(_ preset: TripPreset) -> String {
        switch preset {
        case .cityDash25: return "City Dash"
        case .expressway50: return "Expressway"
        case .interstate90: return "Interstate"
        case .openHighway: return "Open Highway"
        }
    }

    private func presetDurationTag(_ preset: TripPreset) -> String {
        switch preset {
        case .cityDash25: return "25 MIN"
        case .expressway50: return "50 MIN"
        case .interstate90: return "90 MIN"
        case .openHighway: return "STOPWATCH"
        }
    }
}
