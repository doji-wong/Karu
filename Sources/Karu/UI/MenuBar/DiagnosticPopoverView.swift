import SwiftUI
import KaruCore

/// SpaceX-inspired Cockpit Telemetry Dashboard popover for macOS Menu Bar & Notch.
public struct DiagnosticPopoverView: View {
    @Bindable public var engine: TransitEngine
    @Bindable public var scratchpadStore: ScratchpadStore
    public var audioEngine: AudioEngine
    public var storage: LocalStorageManager
    public var onToggleFloatingHUD: (() -> Void)?
    public var onOpenGarage: (() -> Void)?
    public var onOpenSettings: (() -> Void)?

    @State private var selectedPreset: TripPreset = .cityDash25
    @State private var selectedCityRoute: CityRoutePreset = .manilaBGC
    @State private var selectedHabitId: UUID?
    @State private var habits: [Habit] = []
    @State private var isLogDrawerExpanded: Bool = false

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
            // ── 1. SpaceX Mission Telemetry Header ──
            SpaceXTelemetryHeader(
                state: engine.state,
                velocity: engine.currentVelocity,
                activeSession: engine.activeSession
            )
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)
            
            // Razor-sharp 1px divider
            Rectangle()
                .fill(KaruTheme.stripeAccent(for: engine.state))
                .frame(height: 1)
                .shadow(color: KaruTheme.stripeAccent(for: engine.state).opacity(0.8), radius: 3)

            // ── 2. Dynamic Stage Content ──
            if engine.state == .idle {
                preFlightLauncherSection
                    .padding(14)
            } else {
                activeMissionSection
                    .padding(14)
            }

            Rectangle()
                .fill(KaruTheme.cardBorder)
                .frame(height: 1)

            // ── 3. Bottom Aerospace Toolbar ──
            bottomToolbar
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .frame(width: 390)
        .background(KaruTheme.background)
        .onAppear {
            self.habits = storage.loadHabits()
        }
    }

    // MARK: - Pre-Flight Launcher (Idle State)
    private var preFlightLauncherSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("MISSION PROFILE / TARGET")
                    .font(KaruTheme.statLabel)
                    .foregroundStyle(KaruTheme.textMuted)
                    .tracking(1.0)

                Spacer()

                Menu {
                    ForEach(CityRoutePreset.allCases) { route in
                        Button(route.rawValue) {
                            selectedCityRoute = route
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 9))
                        Text(selectedCityRoute.rawValue)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(KaruTheme.surfaceElevated)
                    .foregroundStyle(KaruTheme.telemetryCyan)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(KaruTheme.cardBorder, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .menuStyle(.borderlessButton)
            }

            // Minimalist Mission Preset Selector
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
                ForEach(TripPreset.allCases) { preset in
                    let isSelected = selectedPreset == preset
                    Button {
                        selectedPreset = preset
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(presetTitle(preset))
                                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(isSelected ? Color.white : KaruTheme.textPrimary)

                                Spacer()

                                Text(presetTag(preset))
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(isSelected ? KaruTheme.telemetryCyan : KaruTheme.surfaceElevated)
                                    .foregroundStyle(isSelected ? Color.black : KaruTheme.telemetryCyan)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                            }

                            if let dist = preset.targetDistanceKm {
                                Text("\(Int(dist)) KM TRAJECTORY")
                                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(isSelected ? KaruTheme.telemetryCyan : KaruTheme.textSecondary)
                            } else {
                                Text("UNCAPPED FLIGHT")
                                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                    .foregroundStyle(KaruTheme.textMuted)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(isSelected ? KaruTheme.surfaceElevated : KaruTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(isSelected ? KaruTheme.telemetryCyan : KaruTheme.cardBorder, lineWidth: isSelected ? 1.5 : 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Live Map Preview
            ZStack {
                LiveRouteTrackingView(engine: engine, cityRoute: selectedCityRoute)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(KaruTheme.cardBorder, lineWidth: 1))
            }

            // Habit Linker
            if !habits.isEmpty {
                Menu {
                    Button("None (Standard Mission)") { selectedHabitId = nil }
                    ForEach(habits) { habit in
                        Button("\(habit.name) (\(habit.currentStreakDays)d streak)") {
                            selectedHabitId = habit.id
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "tag.fill").font(.system(size: 9))
                        Text(habits.first(where: { $0.id == selectedHabitId })?.name ?? "Link Habit Track...")
                        Spacer()
                        Image(systemName: "chevron.down").font(.system(size: 9))
                    }
                    .font(KaruTheme.subheadline)
                    .foregroundStyle(KaruTheme.textSecondary)
                    .padding(8)
                    .background(KaruTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(KaruTheme.cardBorder, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .menuStyle(.borderlessButton)
            }

            // Launch Action Button
            Button {
                let linkedHabit = habits.first(where: { $0.id == selectedHabitId })
                engine.startTrip(preset: selectedPreset, habit: linkedHabit)
                audioEngine.start()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .black))
                    Text("INITIATE MISSION · START FOCUS")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(0.8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(KaruTheme.telemetryCyan)
                .foregroundStyle(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .shadow(color: KaruTheme.telemetryCyan.opacity(0.4), radius: 6)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Active Mission Section (Flight State)
    private var activeMissionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Embedded CARTO Dark Matter Real Vector Map Centerpiece
            ZStack(alignment: .topTrailing) {
                LiveRouteTrackingView(engine: engine, cityRoute: selectedCityRoute)
                    .frame(height: 155)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(KaruTheme.cardBorder, lineWidth: 1))

                // Route Switcher Badge on Map
                Menu {
                    ForEach(CityRoutePreset.allCases) { route in
                        Button(route.rawValue) {
                            selectedCityRoute = route
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "location.north.line.fill")
                            .font(.system(size: 8))
                        Text(selectedCityRoute.rawValue.components(separatedBy: " ").prefix(2).joined(separator: " "))
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.85))
                    .foregroundStyle(KaruTheme.telemetryCyan)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(KaruTheme.cardBorder, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .menuStyle(.borderlessButton)
                .padding(6)
            }

            // SpaceX 3-Box Telemetry Grid
            SpaceXTelemetryGrid(
                session: engine.activeSession,
                targetDistanceKm: engine.activeSession?.preset.targetDistanceKm
            )

            // Collapsible In-Flight Log Drawer
            if isLogDrawerExpanded {
                VStack(alignment: .trailing, spacing: 3) {
                    TextEditor(text: $scratchpadStore.notes)
                        .font(.system(size: 10, design: .monospaced))
                        .frame(height: 60)
                        .scrollContentBackground(.hidden)
                        .background(KaruTheme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(KaruTheme.cardBorder, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    
                    Text("LOCAL TELEMETRY LOG")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(KaruTheme.textMuted)
                }
            }

            // Aerospace Flight Controls
            HStack(spacing: 6) {
                // Hold / Pit Stop
                Button {
                    engine.togglePitStop()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: engine.state == .pitStop ? "play.fill" : "pause.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text(engine.state == .pitStop ? "RESUME" : "HOLD")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(KaruTheme.surfaceElevated)
                    .foregroundStyle(engine.state == .pitStop ? KaruTheme.telemetryAmber : KaruTheme.textPrimary)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(KaruTheme.cardBorder, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .buttonStyle(.plain)

                // Complete / Dock
                Button {
                    engine.completeTrip()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "flag.checkered")
                            .font(.system(size: 9, weight: .bold))
                        Text("DOCK")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(KaruTheme.telemetryGreen)
                    .foregroundStyle(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .buttonStyle(.plain)

                // Log Drawer Toggle
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isLogDrawerExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "note.text")
                        .font(.system(size: 9, weight: .bold))
                        .padding(7)
                        .background(isLogDrawerExpanded ? KaruTheme.surfaceElevated : KaruTheme.surface)
                        .foregroundStyle(isLogDrawerExpanded ? KaruTheme.telemetryCyan : KaruTheme.textSecondary)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(KaruTheme.cardBorder, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .buttonStyle(.plain)

                // Abort Mission
                Button {
                    engine.cancelTrip()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .padding(7)
                        .background(KaruTheme.surface)
                        .foregroundStyle(KaruTheme.telemetryRed)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(KaruTheme.telemetryRed.opacity(0.4), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Bottom Utility Toolbar
    private var bottomToolbar: some View {
        HStack(spacing: 12) {
            // Audio Mute & Volume
            HStack(spacing: 5) {
                Button {
                    audioEngine.toggleMute()
                } label: {
                    Image(systemName: audioEngine.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(audioEngine.isMuted ? KaruTheme.textMuted : KaruTheme.telemetryCyan)
                }
                .buttonStyle(.plain)

                Slider(
                    value: Binding(
                        get: { Double(audioEngine.masterVolume) },
                        set: { audioEngine.masterVolume = Float($0) }
                    ),
                    in: 0.0...1.0
                )
                .frame(width: 75)
            }

            Spacer()

            // Floating HUD Overlay
            Button {
                onToggleFloatingHUD?()
            } label: {
                Image(systemName: "pip.badge.plus")
                    .font(.system(size: 11))
                    .foregroundStyle(KaruTheme.textSecondary)
            }
            .buttonStyle(.plain)

            // Garage
            Button {
                onOpenGarage?()
            } label: {
                Image(systemName: "car.2.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(KaruTheme.textSecondary)
            }
            .buttonStyle(.plain)

            // Settings
            Button {
                onOpenSettings?()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(KaruTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func presetTitle(_ preset: TripPreset) -> String {
        switch preset {
        case .cityDash25: return "CITY DASH"
        case .expressway50: return "EXPRESSWAY"
        case .interstate90: return "INTERSTATE"
        case .openHighway: return "OPEN FLOW"
        }
    }

    private func presetTag(_ preset: TripPreset) -> String {
        switch preset {
        case .cityDash25: return "25M"
        case .expressway50: return "50M"
        case .interstate90: return "90M"
        case .openHighway: return "∞"
        }
    }
}
