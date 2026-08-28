import Testing
@testable import KaruCore
import Foundation

@Suite("App Classifier & Distraction Monitor Tests")
struct AppClassifierTests {

    @Test("AppClassifier evaluates developer preset accurately")
    func developerPresetEvaluation() {
        let classifier = AppClassifier(activePreset: .developer)

        #expect(classifier.classify(bundleIdentifier: "com.apple.dt.Xcode") == .focusWorkspace)
        #expect(classifier.classify(bundleIdentifier: "com.microsoft.VSCode") == .focusWorkspace)
        #expect(classifier.classify(bundleIdentifier: "com.apple.Terminal") == .focusWorkspace)

        #expect(classifier.classify(bundleIdentifier: "com.hnc.Discord") == .distractionHazard)
        #expect(classifier.classify(bundleIdentifier: "com.valvesoftware.steam") == .distractionHazard)

        #expect(classifier.classify(bundleIdentifier: "com.apple.finder") == .neutralUtility)
    }

    @Test("User custom rule overrides preset category")
    func customRuleOverride() {
        let classifier = AppClassifier(activePreset: .developer)

        // By default, Discord is distractionHazard
        #expect(classifier.classify(bundleIdentifier: "com.hnc.Discord") == .distractionHazard)

        // Community manager marks Discord as focusWorkspace
        let overrideRule = AppFilterRule(
            bundleIdentifier: "com.hnc.Discord",
            appName: "Discord",
            category: .focusWorkspace
        )
        classifier.setCustomRule(overrideRule)

        #expect(classifier.classify(bundleIdentifier: "com.hnc.Discord") == .focusWorkspace)

        // Remove override
        classifier.removeCustomRule(bundleIdentifier: "com.hnc.Discord")
        #expect(classifier.classify(bundleIdentifier: "com.hnc.Discord") == .distractionHazard)
    }

    @Test("Strict mode treats unlisted applications as distraction hazards")
    func strictModeBehavior() {
        let classifier = AppClassifier(activePreset: .developer)
        let unknownBundle = "com.unknown.randomapp"

        // Default: neutral utility
        #expect(classifier.classify(bundleIdentifier: unknownBundle) == .neutralUtility)

        // Enable strict mode
        classifier.isStrictModeEnabled = true
        #expect(classifier.classify(bundleIdentifier: unknownBundle) == .distractionHazard)
    }

    @Test("Preset switching updates evaluation rules")
    func presetSwitching() {
        let classifier = AppClassifier(activePreset: .developer)
        
        // In Developer preset, Ulysses is not listed -> neutral
        #expect(classifier.classify(bundleIdentifier: "com.ulyssesapp.mac") == .neutralUtility)

        // Switch to Writer preset
        classifier.setPreset(.writer)
        #expect(classifier.classify(bundleIdentifier: "com.ulyssesapp.mac") == .focusWorkspace)
    }

    @Test("DistractionMonitor simulation dispatches category and metadata")
    @MainActor
    func distractionMonitorSimulation() {
        let classifier = AppClassifier(activePreset: .developer)
        let monitor = DistractionMonitor(classifier: classifier)

        var receivedCategory: AppFocusCategory?
        var receivedAppName: String?
        var receivedBundleId: String?

        monitor.onAppActivated = { category, name, bundle in
            receivedCategory = category
            receivedAppName = name
            receivedBundleId = bundle
        }

        monitor.simulateApplicationSwitch(
            bundleIdentifier: "com.apple.dt.Xcode",
            appName: "Xcode"
        )

        #expect(receivedCategory == .focusWorkspace)
        #expect(receivedAppName == "Xcode")
        #expect(receivedBundleId == "com.apple.dt.Xcode")
    }
}
