import AppKit
import SwiftUI
import KaruCore

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    
    // Core Services
    public let storage: LocalStorageManager
    public let scratchpadStore: ScratchpadStore
    public let classifier: AppClassifier
    public let distractionMonitor: DistractionMonitor
    public let transitEngine: TransitEngine
    public let audioEngine: AudioEngine
    
    // Window & HUD Controllers
    public private(set) var menuBarController: MenuBarController?
    public private(set) var notchController: NotchWindowController?
    public private(set) var floatingHUDPanel: FloatingHUDPanel?
    
    // Secondary Windows
    private var garageWindow: NSWindow?
    private var settingsWindow: NSWindow?

    public override init() {
        let storage = LocalStorageManager()
        self.storage = storage
        self.scratchpadStore = ScratchpadStore(storage: storage)
        
        let customRules = storage.loadCustomRules()
        let classifier = AppClassifier(activePreset: .developer, customRules: customRules)
        self.classifier = classifier
        self.distractionMonitor = DistractionMonitor(classifier: classifier)
        
        self.transitEngine = TransitEngine()
        self.audioEngine = AudioEngine()
        
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize menu bar HUD
        let menuBar = MenuBarController(
            engine: transitEngine,
            scratchpadStore: scratchpadStore,
            audioEngine: audioEngine,
            storage: storage
        )
        menuBar.onToggleFloatingHUD = { [weak self] in self?.toggleFloatingHUD() }
        menuBar.onOpenGarage = { [weak self] in self?.openGarageWindow() }
        menuBar.onOpenSettings = { [weak self] in self?.openSettingsWindow() }
        self.menuBarController = menuBar

        // Initialize Notch Wings
        self.notchController = NotchWindowController(engine: transitEngine)

        // Initialize Floating HUD
        self.floatingHUDPanel = FloatingHUDPanel(engine: transitEngine, scratchpadStore: scratchpadStore)

        // Wire Event-Driven Services
        distractionMonitor.onAppActivated = { [weak self] category, name, bundleId in
            Task { @MainActor in
                self?.transitEngine.handleAppCategoryChange(
                    category: category,
                    appName: name,
                    bundleIdentifier: bundleId
                )
            }
        }
        distractionMonitor.start()

        // Wire Transit State Changes to Audio and Storage
        transitEngine.onStateChanged = { [weak self] _, newState in
            Task { @MainActor in
                self?.audioEngine.updateState(newState)
            }
        }

        transitEngine.onTripCompleted = { [weak self] completedSession in
            Task { @MainActor in
                var sessionWithNotes = completedSession
                if let notes = self?.scratchpadStore.notes, !notes.isEmpty {
                    sessionWithNotes.scratchpadNotes = notes
                }
                try? self?.storage.appendTripSession(sessionWithNotes)
            }
        }

        print("[Karu] Cockpit & Transit Engine initialized successfully.")
    }

    public func applicationWillTerminate(_ notification: Notification) {
        distractionMonitor.stop()
        audioEngine.stop()
        scratchpadStore.flush()
    }

    // MARK: - Window Management Actions

    public func toggleFloatingHUD() {
        floatingHUDPanel?.toggleVisibility()
    }

    public func openGarageWindow() {
        if garageWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 460, height: 440),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Karu Garage"
            window.center()
            let garageView = GarageHangarView(
                engine: transitEngine,
                audioEngine: audioEngine,
                storage: storage
            )
            window.contentView = NSHostingView(rootView: garageView)
            self.garageWindow = window
        }
        garageWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func openSettingsWindow() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 540, height: 480),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Karu Preferences & App Rules"
            window.center()
            let settingsView = AppFilterSettingsView(
                classifier: classifier,
                storage: storage
            )
            window.contentView = NSHostingView(rootView: settingsView)
            self.settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
