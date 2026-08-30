import SwiftUI
import AppKit
import KaruCore

/// Running application model for live radar detection.
struct RunningAppItem: Identifiable {
    let id: String // bundleIdentifier
    let localizedName: String
    let icon: NSImage?
    var category: AppFocusCategory?
}

/// Preferences view for managing Focus presets, 1-Click Running App Radar, and custom rules.
public struct AppFilterSettingsView: View {
    public var classifier: AppClassifier
    public var storage: LocalStorageManager

    @State private var selectedTab: Int = 0 // 0: Radar, 1: Rules & Presets
    @State private var selectedPreset: FocusPreset
    @State private var isStrictMode: Bool
    @State private var customRules: [AppFilterRule] = []
    
    // Live Running Apps
    @State private var runningApps: [RunningAppItem] = []
    @State private var radarSearchQuery: String = ""
    
    // Add new rule form
    @State private var newBundleId: String = ""
    @State private var newAppName: String = ""
    @State private var newCategory: AppFocusCategory = .distractionHazard

    public init(classifier: AppClassifier, storage: LocalStorageManager) {
        self.classifier = classifier
        self.storage = storage
        _selectedPreset = State(initialValue: classifier.activePreset)
        _isStrictMode = State(initialValue: classifier.isStrictModeEnabled)
    }

    public var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("FLIGHT TELEMETRY & APP RADAR")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(Color(hex: 0xFF5C00))
                    Text("App Classification Rules")
                        .font(KaruTheme.headerTitle)
                        .foregroundStyle(KaruTheme.textPrimary)
                }
                Spacer()
                
                Picker("", selection: $selectedTab) {
                    Text("Radar (Running Apps)").tag(0)
                    Text("Rules & Presets").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
            }

            Divider().background(KaruTheme.cardBorder)

            if selectedTab == 0 {
                runningAppRadarView
            } else {
                rulesAndPresetsView
            }
        }
        .padding(18)
        .frame(width: 560, height: 480)
        .background(KaruTheme.background)
        .onAppear {
            self.customRules = storage.loadCustomRules()
            refreshRunningApps()
        }
    }

    // MARK: - 1-Click Running App Radar View

    private var filteredRunningApps: [RunningAppItem] {
        if radarSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return runningApps
        }
        let query = radarSearchQuery.lowercased()
        return runningApps.filter {
            $0.localizedName.lowercased().contains(query) ||
            $0.id.lowercased().contains(query)
        }
    }

    @ViewBuilder
    private var runningAppRadarView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10))
                        .foregroundStyle(KaruTheme.textMuted)
                    TextField("Filter open applications...", text: $radarSearchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white)
                }
                .padding(6)
                .background(KaruTheme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                Spacer()

                Button {
                    refreshRunningApps()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                        Text("Rescan")
                            .font(KaruTheme.captionMono)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(KaruTheme.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            Text("1-Click classify currently active macOS applications into Focus Workspaces or Distraction Hazards:")
                .font(.system(size: 11))
                .foregroundStyle(KaruTheme.textMuted)

            ScrollView {
                VStack(spacing: 6) {
                    ForEach(filteredRunningApps) { app in
                        HStack(spacing: 10) {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 24, height: 24)
                            } else {
                                Image(systemName: "app.fill")
                                    .frame(width: 24, height: 24)
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

                            // Quick Classification Segmented Controls
                            HStack(spacing: 4) {
                                Button {
                                    setAppCategory(bundleId: app.id, name: app.localizedName, category: .focusWorkspace)
                                } label: {
                                    Text("Focus")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(app.category == .focusWorkspace ? Color(hex: 0x10B981) : Color.white.opacity(0.08))
                                        .foregroundStyle(app.category == .focusWorkspace ? Color.black : Color.white.opacity(0.8))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    setAppCategory(bundleId: app.id, name: app.localizedName, category: .distractionHazard)
                                } label: {
                                    Text("Hazard")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(app.category == .distractionHazard ? Color(hex: 0xEF4444) : Color.white.opacity(0.08))
                                        .foregroundStyle(app.category == .distractionHazard ? Color.white : Color.white.opacity(0.8))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .buttonStyle(.plain)

                                Button {
                                    setAppCategory(bundleId: app.id, name: app.localizedName, category: .neutralUtility)
                                } label: {
                                    Text("Neutral")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(app.category == .neutralUtility ? Color(hex: 0x3B82F6) : Color.white.opacity(0.08))
                                        .foregroundStyle(app.category == .neutralUtility ? Color.white : Color.white.opacity(0.8))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(8)
                        .background(KaruTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
            .frame(maxHeight: 330)
        }
    }

    // MARK: - Rules & Presets View

    @ViewBuilder
    private var rulesAndPresetsView: some View {
        VStack(spacing: 12) {
            // Preset Selector
            VStack(alignment: .leading, spacing: 6) {
                Text("PILOT WORKFLOW PRESET")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.textSecondary)

                Picker("", selection: $selectedPreset) {
                    ForEach(FocusPreset.allCases, id: \.self) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedPreset) { _, newPreset in
                    classifier.setPreset(newPreset)
                    refreshRunningApps()
                }
            }

            // Strict Mode Toggle
            Toggle(isOn: $isStrictMode) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Strict Distraction Mode")
                        .font(KaruTheme.subheadline)
                        .foregroundStyle(KaruTheme.textPrimary)
                    Text("Treat all unlisted applications as turbulence hazards (0 kts stall)")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.textMuted)
                }
            }
            .onChange(of: isStrictMode) { _, newValue in
                classifier.isStrictModeEnabled = newValue
            }

            Divider().background(KaruTheme.cardBorder)

            // Add Custom Rule Form
            VStack(alignment: .leading, spacing: 6) {
                Text("ADD CUSTOM BUNDLE RULE")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.textSecondary)

                HStack(spacing: 8) {
                    TextField("App Name (e.g. Steam)", text: $newAppName)
                        .textFieldStyle(.roundedBorder)

                    TextField("Bundle ID (e.g. com.valvesoftware.steam)", text: $newBundleId)
                        .textFieldStyle(.roundedBorder)

                    Picker("", selection: $newCategory) {
                        Text("Focus").tag(AppFocusCategory.focusWorkspace)
                        Text("Hazard").tag(AppFocusCategory.distractionHazard)
                        Text("Neutral").tag(AppFocusCategory.neutralUtility)
                    }
                    .frame(width: 90)

                    Button("Add") {
                        addCustomRule()
                    }
                    .disabled(newBundleId.isEmpty || newAppName.isEmpty)
                }
            }

            // Active Rules List
            VStack(alignment: .leading, spacing: 4) {
                Text("CONFIGURED RULES (\(classifier.allActiveRules().count))")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.textSecondary)

                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(classifier.allActiveRules()) { rule in
                            HStack {
                                Circle()
                                    .fill(categoryColor(rule.category))
                                    .frame(width: 8, height: 8)

                                Text(rule.appName)
                                    .font(KaruTheme.subheadline)
                                    .foregroundStyle(KaruTheme.textPrimary)

                                Text(rule.bundleIdentifier)
                                    .font(KaruTheme.captionMono)
                                    .foregroundStyle(KaruTheme.textMuted)

                                Spacer()

                                Text(rule.category.title)
                                    .font(KaruTheme.captionMono)
                                    .foregroundStyle(categoryColor(rule.category))

                                if rule.isCustomOverride {
                                    Button {
                                        removeRule(rule.bundleIdentifier)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.caption)
                                            .foregroundStyle(KaruTheme.hazardRed)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(6)
                            .background(KaruTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .frame(maxHeight: 140)
            }
        }
    }

    // MARK: - Actions & Helpers

    private func refreshRunningApps() {
        let running = NSWorkspace.shared.runningApplications
        let currentRules = classifier.allActiveRules()
        let ruleMap = Dictionary(uniqueKeysWithValues: currentRules.map { ($0.bundleIdentifier, $0.category) })

        self.runningApps = running
            .filter { $0.activationPolicy == .regular && $0.bundleIdentifier != Bundle.main.bundleIdentifier }
            .compactMap { app -> RunningAppItem? in
                guard let bundleId = app.bundleIdentifier, let name = app.localizedName else { return nil }
                let icon = app.icon
                let category = ruleMap[bundleId]
                return RunningAppItem(id: bundleId, localizedName: name, icon: icon, category: category)
            }
            .sorted { $0.localizedName.localizedCaseInsensitiveCompare($1.localizedName) == .orderedAscending }
    }

    private func setAppCategory(bundleId: String, name: String, category: AppFocusCategory) {
        let rule = AppFilterRule(
            bundleIdentifier: bundleId,
            appName: name,
            category: category,
            isCustomOverride: true
        )
        classifier.setCustomRule(rule)
        customRules.removeAll(where: { $0.bundleIdentifier == bundleId })
        customRules.append(rule)
        try? storage.saveCustomRules(customRules)
        refreshRunningApps()
    }

    private func addCustomRule() {
        let rule = AppFilterRule(
            bundleIdentifier: newBundleId.trimmingCharacters(in: .whitespacesAndNewlines),
            appName: newAppName.trimmingCharacters(in: .whitespacesAndNewlines),
            category: newCategory,
            isCustomOverride: true
        )
        classifier.setCustomRule(rule)
        customRules.append(rule)
        try? storage.saveCustomRules(customRules)

        newBundleId = ""
        newAppName = ""
        refreshRunningApps()
    }

    private func removeRule(_ bundleId: String) {
        classifier.removeCustomRule(bundleIdentifier: bundleId)
        customRules.removeAll(where: { $0.bundleIdentifier == bundleId })
        try? storage.saveCustomRules(customRules)
        refreshRunningApps()
    }

    private func categoryColor(_ category: AppFocusCategory) -> Color {
        switch category {
        case .focusWorkspace: return Color(hex: 0x10B981)
        case .distractionHazard: return Color(hex: 0xEF4444)
        case .neutralUtility: return Color(hex: 0x3B82F6)
        }
    }
}
