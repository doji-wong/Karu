import SwiftUI
import KaruCore

/// Preferences view for managing Focus presets, custom whitelist/blacklist rules, and strict mode.
public struct AppFilterSettingsView: View {
    public var classifier: AppClassifier
    public var storage: LocalStorageManager

    @State private var selectedPreset: FocusPreset
    @State private var isStrictMode: Bool
    @State private var customRules: [AppFilterRule] = []
    
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
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TRAFFIC & DISTRACTION RULES")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.navCyan)
                    Text("App Classification Rules")
                        .font(KaruTheme.headerTitle)
                        .foregroundStyle(KaruTheme.textPrimary)
                }
                Spacer()
                Image(systemName: "shield.lefthalf.filled")
                    .font(.title2)
                    .foregroundStyle(KaruTheme.textMuted)
            }

            Divider().background(KaruTheme.cardBorder)

            // Preset Selector
            VStack(alignment: .leading, spacing: 6) {
                Text("WORKFLOW PRESET")
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
                }
            }

            // Strict Mode Toggle
            Toggle(isOn: $isStrictMode) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Strict Distraction Mode")
                        .font(KaruTheme.subheadline)
                        .foregroundStyle(KaruTheme.textPrimary)
                    Text("Treat all unlisted applications as distraction hazards (0 km/h stall)")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.textMuted)
                }
            }
            .onChange(of: isStrictMode) { _, newValue in
                classifier.isStrictModeEnabled = newValue
            }

            Divider().background(KaruTheme.cardBorder)

            // Add Custom Rule Form
            VStack(alignment: .leading, spacing: 8) {
                Text("ADD CUSTOM APP RULE")
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
            VStack(alignment: .leading, spacing: 6) {
                Text("ACTIVE APP RULES")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.textSecondary)

                ScrollView {
                    VStack(spacing: 6) {
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
                            .padding(8)
                            .background(KaruTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .frame(maxHeight: 180)
            }
        }
        .padding(20)
        .frame(width: 520)
        .background(KaruTheme.background)
        .onAppear {
            self.customRules = storage.loadCustomRules()
        }
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
    }

    private func removeRule(_ bundleId: String) {
        classifier.removeCustomRule(bundleIdentifier: bundleId)
        customRules.removeAll(where: { $0.bundleIdentifier == bundleId })
        try? storage.saveCustomRules(customRules)
    }

    private func categoryColor(_ category: AppFocusCategory) -> Color {
        switch category {
        case .focusWorkspace: return KaruTheme.cruiseEmerald
        case .distractionHazard: return KaruTheme.hazardAmber
        case .neutralUtility: return KaruTheme.navCyan
        }
    }
}
