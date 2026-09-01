import SwiftUI
import AppKit
import KaruCore

/// 4-Stage Interactive First-Time Pilot Briefing & Workspace Intake Flow.
public struct OnboardingView: View {
    public var classifier: AppClassifier
    public var storage: LocalStorageManager
    public var onTakeoffAuthorized: (KaruPreferences) -> Void

    @State private var currentStage: Int = 1 // 1: Mission, 2: Radar, 3: Avionics, 4: Clearance
    @State private var selectedRole: PilotRoleMission = .developer
    @State private var dailyGoalMinutes: Int = 240
    @State private var presentationMode: AppPresentationMode = .standardDock
    @State private var runningApps: [RunningAppItem] = []
    @State private var customizedRules: [String: AppFocusCategory] = [:]

    public init(
        classifier: AppClassifier,
        storage: LocalStorageManager,
        onTakeoffAuthorized: @escaping (KaruPreferences) -> Void
    ) {
        self.classifier = classifier
        self.storage = storage
        self.onTakeoffAuthorized = onTakeoffAuthorized
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerView
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 14)

            Divider().background(KaruTheme.cardBorder)

            // Dynamic Stage Body
            ScrollView {
                VStack(spacing: 16) {
                    switch currentStage {
                    case 1:
                        stage1MissionIntake
                    case 2:
                        stage2AppRadar
                    case 3:
                        stage3AvionicsHUD
                    case 4:
                        stage4FlightClearance
                    default:
                        EmptyView()
                    }
                }
                .padding(24)
            }
            .frame(maxHeight: 400)

            Divider().background(KaruTheme.cardBorder)

            // Bottom Navigation Controls
            footerControlsView
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(KaruTheme.surface)
        }
        .frame(width: 620, height: 540)
        .background(KaruTheme.background)
        .onAppear {
            scanRunningApplications()
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xFF5C00).opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "airplane")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFF5C00))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("KARU PRE-FLIGHT COCKPIT BRIEFING")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(Color(hex: 0xFF5C00))
                Text("Pilot Intake & Workspace Radar")
                    .font(KaruTheme.headerTitle)
                    .foregroundStyle(KaruTheme.textPrimary)
            }

            Spacer()

            // Step Progress Pills
            HStack(spacing: 6) {
                ForEach(1...4, id: \.self) { step in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(step == currentStage ? Color(hex: 0x00E5FF) : (step < currentStage ? Color(hex: 0x10B981) : Color.white.opacity(0.15)))
                            .frame(width: 8, height: 8)
                        if step == currentStage {
                            Text("STEP \(step)")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundStyle(Color(hex: 0x00E5FF))
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(step == currentStage ? 0.08 : 0.03))
                    .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Stage 1: Mission Intake & Daily Quota
    private var stage1MissionIntake: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("1. What is your primary focus mission?")
                    .font(KaruTheme.metricMedium)
                    .foregroundStyle(KaruTheme.textPrimary)
                Text("Karu tunes its velocity engine and workspace filters to match your workflow:")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.textMuted)
            }

            // Role selection grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(PilotRoleMission.allCases, id: \.self) { role in
                    Button {
                        self.selectedRole = role
                        applyRolePreset(role)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: role.iconSymbol)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(selectedRole == role ? Color(hex: 0x00E5FF) : Color.white.opacity(0.6))
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(role.title)
                                    .font(KaruTheme.subheadline)
                                    .foregroundStyle(selectedRole == role ? Color.white : KaruTheme.textSecondary)
                                Text(rolePresetSummary(role))
                                    .font(KaruTheme.captionMono)
                                    .foregroundStyle(KaruTheme.textMuted)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(selectedRole == role ? Color(hex: 0x00E5FF).opacity(0.12) : KaruTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedRole == role ? Color(hex: 0x00E5FF) : KaruTheme.cardBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("2. Target daily flight hours (focus quota):")
                    .font(KaruTheme.metricMedium)
                    .foregroundStyle(KaruTheme.textPrimary)

                HStack(spacing: 10) {
                    flightGoalButton(hours: 2, distanceNM: 1080, label: "2 Hours • Commute")
                    flightGoalButton(hours: 4, distanceNM: 2160, label: "4 Hours • Transcon", recommended: true)
                    flightGoalButton(hours: 6, distanceNM: 3240, label: "6 Hours • Long-Haul")
                }
            }
        }
    }

    private func flightGoalButton(hours: Int, distanceNM: Int, label: String, recommended: Bool = false) -> some View {
        Button {
            self.dailyGoalMinutes = hours * 60
        } label: {
            VStack(spacing: 3) {
                if recommended {
                    Text("RECOMMENDED")
                        .font(.system(size: 7.5, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(hex: 0xFF5C00))
                }
                Text(label)
                    .font(KaruTheme.subheadline)
                    .foregroundStyle(dailyGoalMinutes == hours * 60 ? Color.white : KaruTheme.textSecondary)
                Text("\(distanceNM) NM Goal")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(dailyGoalMinutes == hours * 60 ? Color(hex: 0xFF5C00).opacity(0.15) : KaruTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(dailyGoalMinutes == hours * 60 ? Color(hex: 0xFF5C00) : KaruTheme.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stage 2: 1-Click Running App Radar
    private var stage2AppRadar: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("1-Click Active Workspace Radar")
                        .font(KaruTheme.metricMedium)
                        .foregroundStyle(KaruTheme.textPrimary)
                    Spacer()
                    Button("Rescan Open Apps") {
                        scanRunningApplications()
                    }
                    .font(KaruTheme.captionMono)
                    .buttonStyle(.link)
                }
                Text("We scanned your active applications. 1-Click categorize which apps should maintain 540 kts cruise:")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.textMuted)
            }

            VStack(spacing: 6) {
                ForEach(runningApps) { app in
                    let category = customizedRules[app.id] ?? app.category ?? .neutralUtility

                    HStack(spacing: 10) {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 22, height: 22)
                        } else {
                            Image(systemName: "app.fill")
                                .frame(width: 22, height: 22)
                                .foregroundStyle(KaruTheme.textMuted)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(app.localizedName)
                                .font(KaruTheme.subheadline)
                                .foregroundStyle(Color.white)
                            Text(app.id)
                                .font(KaruTheme.captionMono)
                                .foregroundStyle(KaruTheme.textMuted)
                        }

                        Spacer()

                        // Category Pills
                        HStack(spacing: 4) {
                            categoryButton(bundleId: app.id, label: "Focus", targetCategory: .focusWorkspace, activeCategory: category, color: Color(hex: 0x10B981))
                            categoryButton(bundleId: app.id, label: "Hazard", targetCategory: .distractionHazard, activeCategory: category, color: Color(hex: 0xEF4444))
                            categoryButton(bundleId: app.id, label: "Neutral", targetCategory: .neutralUtility, activeCategory: category, color: Color(hex: 0x3B82F6))
                        }
                    }
                    .padding(8)
                    .background(KaruTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    private func categoryButton(bundleId: String, label: String, targetCategory: AppFocusCategory, activeCategory: AppFocusCategory, color: Color) -> some View {
        Button {
            customizedRules[bundleId] = targetCategory
        } label: {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(activeCategory == targetCategory ? color : Color.white.opacity(0.08))
                .foregroundStyle(activeCategory == targetCategory ? Color.white : Color.white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stage 3: Avionics & HUD Briefing
    private var stage3AvionicsHUD: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("How Flight Velocity Works")
                    .font(KaruTheme.metricMedium)
                    .foregroundStyle(KaruTheme.textPrimary)
                Text("Karu eliminates timer anxiety by replacing countdowns with airspeed momentum:")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.textMuted)
            }

            // Velocity comparison cards
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "airplane.departure")
                            .foregroundStyle(Color(hex: 0x00E5FF))
                        Text("CRUISING (540 KTS)")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(hex: 0x00E5FF))
                    }
                    Text("Active inside approved Focus Workspaces. Nautical miles and flight hours log into your certified pilot logbook.")
                        .font(.system(size: 11))
                        .foregroundStyle(KaruTheme.textSecondary)
                }
                .padding(12)
                .background(Color(hex: 0x00E5FF).opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0x00E5FF).opacity(0.3), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "wind")
                            .foregroundStyle(Color(hex: 0xEF4444))
                        Text("TURBULENCE (0 KTS)")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(hex: 0xEF4444))
                    }
                    Text("Active in Distraction Hazards. Airspeed drops to zero and cabin turbulence alert sounds until you return to focus.")
                        .font(.system(size: 11))
                        .foregroundStyle(KaruTheme.textSecondary)
                }
                .padding(12)
                .background(Color(hex: 0xEF4444).opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: 0xEF4444).opacity(0.3), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Select your Cockpit HUD presentation style:")
                    .font(KaruTheme.metricMedium)
                    .foregroundStyle(KaruTheme.textPrimary)

                HStack(spacing: 10) {
                    presentationCard(
                        mode: .standardDock,
                        title: "Standard Cockpit",
                        subtitle: "Menu Bar + Interactive Dynamic Dock Telemetry (Recommended)",
                        icon: "dock.rectangle"
                    )
                    presentationCard(
                        mode: .menuBarOnly,
                        title: "Stealth Recon",
                        subtitle: "Top Menu Bar HUD & Floating Card only (Hidden from Dock)",
                        icon: "menubar.rectangle"
                    )
                }
            }
        }
    }

    private func presentationCard(mode: AppPresentationMode, title: String, subtitle: String, icon: String) -> some View {
        Button {
            self.presentationMode = mode
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(presentationMode == mode ? Color(hex: 0x00E5FF) : Color.white.opacity(0.5))
                    Text(title)
                        .font(KaruTheme.subheadline)
                        .foregroundStyle(presentationMode == mode ? Color.white : KaruTheme.textSecondary)
                }
                Text(subtitle)
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(presentationMode == mode ? Color(hex: 0x00E5FF).opacity(0.12) : KaruTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(presentationMode == mode ? Color(hex: 0x00E5FF) : KaruTheme.cardBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stage 4: Flight Clearance & Maiden Takeoff
    private var stage4FlightClearance: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("PRE-FLIGHT CLEARANCE GRANTED")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(Color(hex: 0x10B981))
                Text("Boarding Pass: Maiden Focus Voyage")
                    .font(KaruTheme.headerTitle)
                    .foregroundStyle(KaruTheme.textPrimary)
            }

            // Boarding Pass Card
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FLIGHT")
                            .font(KaruTheme.captionMono)
                            .foregroundStyle(KaruTheme.textMuted)
                        Text("KR-001")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.white)
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 2) {
                        Text("ROUTE")
                            .font(KaruTheme.captionMono)
                            .foregroundStyle(KaruTheme.textMuted)
                        Text("SFO ✈ HND")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: 0x00E5FF))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("VELOCITY")
                            .font(KaruTheme.captionMono)
                            .foregroundStyle(KaruTheme.textMuted)
                        Text("540 KTS")
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundStyle(Color(hex: 0x10B981))
                    }
                }

                Divider().background(KaruTheme.cardBorder)

                HStack {
                    Text("MISSION: \(selectedRole.title.uppercased())")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.textSecondary)
                    Spacer()
                    Text("QUOTA: \(dailyGoalMinutes / 60) HOURS / DAY")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(Color(hex: 0xFF5C00))
                }
            }
            .padding(14)
            .background(KaruTheme.surface)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0x00E5FF).opacity(0.4), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Ignition Takeoff Button
            Button {
                authorizeMaidenFlight()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 16, weight: .bold))
                    Text("AUTHORIZE MAIDEN TAKEOFF (540 KTS)")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0x00E5FF), Color(hex: 0x10B981)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .shadow(color: Color(hex: 0x00E5FF).opacity(0.6), radius: 10)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Footer Controls
    private var footerControlsView: some View {
        HStack {
            if currentStage > 1 {
                Button("Back") {
                    withAnimation { currentStage -= 1 }
                }
                .font(KaruTheme.subheadline)
                .foregroundStyle(KaruTheme.textSecondary)
                .buttonStyle(.plain)
            }

            Spacer()

            if currentStage < 4 {
                Button {
                    withAnimation { currentStage += 1 }
                } label: {
                    HStack(spacing: 4) {
                        Text(currentStage == 1 ? "Next: App Radar" : (currentStage == 2 ? "Next: Avionics" : "Review Clearance"))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                        Image(systemName: "arrow.right")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: 0x00E5FF))
                    .foregroundStyle(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Logic & Scanning
    private func scanRunningApplications() {
        let running = NSWorkspace.shared.runningApplications
        let rules = classifier.allActiveRules()
        let ruleMap = Dictionary(uniqueKeysWithValues: rules.map { ($0.bundleIdentifier, $0.category) })

        self.runningApps = running
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier }
            .compactMap { app -> RunningAppItem? in
                guard let bundleId = app.bundleIdentifier, let name = app.localizedName else { return nil }
                let category = customizedRules[bundleId] ?? ruleMap[bundleId]
                return RunningAppItem(id: bundleId, localizedName: name, icon: app.icon, category: category)
            }
            .sorted { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }
    }

    private func applyRolePreset(_ role: PilotRoleMission) {
        classifier.setPreset(role.suggestedFocusPreset)
        scanRunningApplications()
    }

    private func rolePresetSummary(_ role: PilotRoleMission) -> String {
        switch role {
        case .developer: return "Xcode, VS Code, Cursor, Terminal"
        case .writer: return "Obsidian, Notion, Ulysses, Word"
        case .student: return "Anki, Notes, PDF Readers, Docs"
        case .designer: return "Figma, Sketch, Illustrator, Blender"
        }
    }

    private func authorizeMaidenFlight() {
        // Save customized rules from Stage 2
        var currentCustomRules = storage.loadCustomRules()
        for (bundleId, category) in customizedRules {
            let appName = runningApps.first(where: { $0.id == bundleId })?.localizedName ?? bundleId
            let rule = AppFilterRule(bundleIdentifier: bundleId, appName: appName, category: category, isCustomOverride: true)
            classifier.setCustomRule(rule)
            currentCustomRules.removeAll(where: { $0.bundleIdentifier == bundleId })
            currentCustomRules.append(rule)
        }
        try? storage.saveCustomRules(currentCustomRules)

        // Save preferences
        let prefs = KaruPreferences(
            hasCompletedOnboarding: true,
            presentationMode: presentationMode,
            dockBadgeStyle: .timeRemaining,
            enableDockTileGraphics: true,
            dailyFlightGoalMinutes: dailyGoalMinutes,
            selectedMissionRole: selectedRole,
            launchAtLogin: false
        )
        try? storage.savePreferences(prefs)

        // Trigger callback to start flight and close onboarding window
        onTakeoffAuthorized(prefs)
    }
}
