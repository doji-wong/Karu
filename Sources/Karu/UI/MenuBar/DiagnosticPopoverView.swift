import SwiftUI
import KaruCore

/// The expanded Cockpit Diagnostic Dashboard popover for the Menu Bar and Notch hover.
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
            // Top Telemetry Header
            telemetryHeader
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)
            
            Divider()
                .background(KaruTheme.cardBorder)

            // Dynamic Content
            if engine.state == .idle {
                idleLauncherSection
                    .padding(16)
            } else {
                activeFlightSection
                    .padding(16)
            }

            Divider()
                .background(KaruTheme.cardBorder)

            // Bottom Utility Toolbar
            bottomToolbar
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .frame(width: 380)
        .background(KaruTheme.background)
        .onAppear {
            self.habits = storage.loadHabits()
        }
    }

    // MARK: - Telemetry Header
    private var telemetryHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            // Speedometer Gauge Pill
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(KaruTheme.statusGlow(for: engine.state))
                        .frame(width: 8, height: 8)
                    Text(engine.state.displayTitle.uppercased())
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.textSecondary)
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(engine.currentVelocity))")
                        .font(KaruTheme.telemetryDigits)
                        .foregroundStyle(KaruTheme.statusGlow(for: engine.state))
                    Text("KM/H")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.textMuted)
                }
            }

            Spacer()

            // Efficiency & Progress Badge
            if let session = engine.activeSession {
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "gauge.with.needle.fill")
                        Text("\(Int(session.cruiseEfficiency))% Efficiency")
                    }
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.cruiseNeon)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(KaruTheme.surfaceElevated)
                    .clipShape(Capsule())

                    Text(formattedTime(session.cruisingDuration) + " Focus")
                        .font(KaruTheme.subheadline)
                        .foregroundStyle(KaruTheme.textPrimary)
                }
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(engine.activeVehicle.name)
                        .font(KaruTheme.headerTitle)
                        .foregroundStyle(KaruTheme.textPrimary)
                    Text(engine.activeVehicle.subtitle)
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.textMuted)
                }
            }
        }
    }

    // MARK: - Idle Launcher
    private var idleLauncherSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SELECT TRANSIT ROUTE")
                .font(KaruTheme.captionMono)
                .foregroundStyle(KaruTheme.textSecondary)

            // Preset Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(TripPreset.allCases) { preset in
                    Button {
                        selectedPreset = preset
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(preset.displayName)
                                .font(KaruTheme.subheadline)
                                .foregroundStyle(selectedPreset == preset ? Color.white : KaruTheme.textSecondary)
                                .lineLimit(1)
                            
                            if let dist = preset.targetDistanceKm {
                                Text("\(Int(dist)) km route")
                                    .font(KaruTheme.captionMono)
                                    .foregroundStyle(KaruTheme.navCyan)
                            } else {
                                Text("Uncapped flow")
                                    .font(KaruTheme.captionMono)
                                    .foregroundStyle(KaruTheme.textMuted)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(selectedPreset == preset ? KaruTheme.surfaceElevated : KaruTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedPreset == preset ? KaruTheme.navCyan : KaruTheme.cardBorder, lineWidth: 1)
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
                        Text(habits.first(where: { $0.id == selectedHabitId })?.name ?? "Link Daily Habit...")
                        Spacer()
                        Image(systemName: "chevron.down")
                    }
                    .font(KaruTheme.subheadline)
                    .foregroundStyle(KaruTheme.textSecondary)
                    .padding(10)
                    .background(KaruTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .menuStyle(.borderlessButton)
            }

            // Launch Button
            Button {
                let linkedHabit = habits.first(where: { $0.id == selectedHabitId })
                engine.startTrip(preset: selectedPreset, habit: linkedHabit)
                audioEngine.start()
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("START TRIP")
                        .font(KaruTheme.headerTitle)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(KaruTheme.cruiseEmerald)
                .foregroundStyle(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Active Flight Section
    private var activeFlightSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let session = engine.activeSession {
                // Waze-Style Live Highway Navigation Map
                HighwayNavigationView(engine: engine)

                // In-Flight Scratchpad Tab Selector
                Picker("", selection: $activeTab) {
                    Text("Scratchpad").tag(0)
                    Text("Traffic Incidents (\(session.incidents.count))").tag(1)
                }
                .pickerStyle(.segmented)

                if activeTab == 0 {
                    // Live Scratchpad Editor
                    VStack(alignment: .trailing, spacing: 4) {
                        TextEditor(text: $scratchpadStore.notes)
                            .font(.system(size: 12, design: .monospaced))
                            .frame(height: 90)
                            .scrollContentBackground(.hidden)
                            .background(KaruTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        Text("Auto-saved locally")
                            .font(.system(size: 9))
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
                                    .padding(.vertical, 20)
                            } else {
                                ForEach(session.incidents) { inc in
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(KaruTheme.hazardAmber)
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
                    .frame(height: 105)
                }

                // Active Trip Controls
                HStack(spacing: 8) {
                    Button {
                        engine.togglePitStop()
                    } label: {
                        HStack {
                            Image(systemName: engine.state == .pitStop ? "play.fill" : "pause.fill")
                            Text(engine.state == .pitStop ? "Resume" : "Pit Stop")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(KaruTheme.surfaceElevated)
                        .foregroundStyle(KaruTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)

                    Button {
                        engine.completeTrip()
                        audioEngine.updateState(.completed)
                    } label: {
                        HStack {
                            Image(systemName: "flag.checkered")
                            Text("Arrive")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(KaruTheme.cruiseEmerald.opacity(0.8))
                        .foregroundStyle(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)

                    Button {
                        engine.cancelTrip()
                        audioEngine.stop()
                    } label: {
                        Image(systemName: "xmark")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(KaruTheme.surface)
                            .foregroundStyle(KaruTheme.hazardRed)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        HStack(spacing: 12) {
            // Audio Volume & Mute Toggle
            Button {
                audioEngine.toggleMute()
            } label: {
                Image(systemName: audioEngine.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .foregroundStyle(audioEngine.isMuted ? KaruTheme.textMuted : KaruTheme.navCyan)
            }
            .buttonStyle(.plain)

            Slider(value: Binding(
                get: { Double(audioEngine.masterVolume) },
                set: { audioEngine.masterVolume = Float($0) }
            ), in: 0.0...1.0)
            .frame(width: 80)
            .accentColor(KaruTheme.navCyan)

            Spacer()

            // Floating HUD Overlay Toggle
            Button {
                onToggleFloatingHUD?()
            } label: {
                Image(systemName: "pip.enter")
                    .foregroundStyle(KaruTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Toggle Floating HUD Overlay")

            // Garage Button
            Button {
                onOpenGarage?()
            } label: {
                Image(systemName: "car.side.fill")
                    .foregroundStyle(KaruTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Garage & Vehicle Hangar")

            // Settings Button
            Button {
                onOpenSettings?()
            } label: {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(KaruTheme.textSecondary)
            }
            .buttonStyle(.plain)
            .help("Preferences & App Whitelist")
        }
        .font(.system(size: 13))
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
