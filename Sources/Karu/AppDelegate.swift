import AppKit
import SwiftUI
import KaruCore

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    
    // Core Services
    public let storage: LocalStorageManager
    public let classifier: AppClassifier
    public let distractionMonitor: DistractionMonitor
    public let transitEngine: TransitEngine
    public let audioEngine: AudioEngine
    
    // Window & HUD Controllers
    public private(set) var menuBarController: MenuBarController?
    public private(set) var notchController: NotchWindowController?
    public private(set) var floatingHUDPanel: FloatingHUDPanel?
    public private(set) var dockTelemetryManager: DockTelemetryManager?
    public private(set) var onboardingController: OnboardingWindowController?
    
    // Secondary Windows
    private var garageWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var logbookWindow: NSWindow?
    private var widgetSimulatorWindow: NSWindow?

    public override init() {
        let storage = LocalStorageManager()
        self.storage = storage
        
        let customRules = storage.loadCustomRules()
        let classifier = AppClassifier(activePreset: .developer, customRules: customRules)
        self.classifier = classifier
        self.distractionMonitor = DistractionMonitor(classifier: classifier)
        
        self.transitEngine = TransitEngine()
        self.audioEngine = AudioEngine()
        
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        let prefs = storage.loadPreferences()

        // 1. Configure presentation mode (Regular vs Accessory)
        applyPresentationMode(prefs.presentationMode)

        // 1b. Configure & Start In-Flight Audio Engine with saved vehicle profile
        let vehicleProfile = storage.loadVehicleProfile()
        audioEngine.setVehicle(vehicleProfile.type)
        audioEngine.masterVolume = Float(vehicleProfile.ambientVolume)
        audioEngine.setMuted(!vehicleProfile.isSoundEnabled)
        audioEngine.start()

        // 2. Initialize Dock Telemetry Manager
        let dockManager = DockTelemetryManager(engine: transitEngine, storage: storage)
        dockManager.start()
        self.dockTelemetryManager = dockManager

        // 3. Initialize Onboarding Controller
        self.onboardingController = OnboardingWindowController(classifier: classifier, storage: storage)

        // 4. Initialize menu bar HUD
        let menuBar = MenuBarController(
            engine: transitEngine,
            audioEngine: audioEngine,
            storage: storage
        )
        menuBar.onToggleFloatingHUD = { [weak self] in self?.toggleFloatingHUD() }
        menuBar.onOpenGarage = { [weak self] in self?.openGarageWindow() }
        menuBar.onOpenSettings = { [weak self] in self?.openSettingsWindow() }
        menuBar.onOpenLogbook = { [weak self] in self?.openLogbookWindow() }
        menuBar.onOpenWidgetSimulator = { [weak self] in self?.openWidgetSimulatorWindow() }
        menuBar.onPopoverDismissed = { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                if self.transitEngine.state == .cruising ||
                   self.transitEngine.state == .trafficStalled ||
                   self.transitEngine.state == .pitStop {
                    self.floatingHUDPanel?.showFloating(force: false)
                }
            }
        }
        self.menuBarController = menuBar

        // 5. Initialize Notch Wings
        self.notchController = NotchWindowController(engine: transitEngine)

        // 6. Initialize Floating HUD
        self.floatingHUDPanel = FloatingHUDPanel(
            engine: transitEngine,
            audioEngine: audioEngine,
            onOpenGarage: { [weak self] in self?.openGarageWindow() },
            onOpenSettings: { [weak self] in self?.openSettingsWindow() },
            onOpenLogbook: { [weak self] in self?.openLogbookWindow() },
            onOpenWidgetSimulator: { [weak self] in self?.openWidgetSimulatorWindow() }
        )

        // 7. Wire Event-Driven Services
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

        // 8. Wire Transit State Changes to Audio, Storage, HUD & Dock
        transitEngine.onStateChanged = { [weak self] oldState, newState in
            Task { @MainActor in
                guard let self = self else { return }
                self.audioEngine.updateState(newState)
                self.menuBarController?.updateStatusItemVisuals()
                self.dockTelemetryManager?.updateDockTile(force: true)
                self.exportWidgetSnapshot()

                let destCity = DestinationAirport.find(code: self.transitEngine.activeDestination).cityName
                let seatCode = self.transitEngine.activeSeatCode
                let seatClass = FocusSeatClass.find(code: seatCode)
                let taskTitle = seatClass?.shortTaskTitle.capitalized ?? (self.transitEngine.activeTaskTitle.isEmpty ? "Deep Work" : self.transitEngine.activeTaskTitle)

                if oldState == .idle && newState == .cruising {
                    // Flight started! Dismiss menu dropdown, show floating HUD, and announce takeoff
                    self.menuBarController?.hidePopover()
                    self.floatingHUDPanel?.resetSuppression()
                    self.floatingHUDPanel?.showFloating(force: true)
                    self.audioEngine.announceTakeoff(destinationCity: destCity, seatCode: seatCode, taskTitle: taskTitle)
                } else if oldState == .cruising && newState == .trafficStalled {
                    // Distraction app entered turbulence!
                    self.audioEngine.announceTurbulence()
                } else if newState == .pitStop {
                    // Gate hold paused flight
                    self.audioEngine.announceGateHold(isHolding: true)
                } else if oldState == .pitStop && newState == .cruising {
                    // Resumed cruising from gate hold
                    self.audioEngine.announceGateHold(isHolding: false)
                } else if newState == .completed {
                    // Flight touchdown!
                    self.audioEngine.announceTouchdown(destinationCity: destCity)
                    self.floatingHUDPanel?.hideFloating()
                } else if newState == .idle {
                    // Aborted or reset
                    self.floatingHUDPanel?.hideFloating()
                }
            }
        }

        transitEngine.onTripCompleted = { [weak self] completedSession in
            Task { @MainActor in
                try? self?.storage.appendTripSession(completedSession)
                self?.exportWidgetSnapshot()
                self?.dockTelemetryManager?.updateDockTile(force: true)
            }
        }

        // Listen for Widget AppIntent triggers
        NotificationCenter.default.addObserver(forName: .karuWidgetDidRequestTakeoff, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                if self?.transitEngine.state == .idle {
                    self?.transitEngine.startFlight()
                } else if self?.transitEngine.state == .pitStop {
                    self?.transitEngine.resumeFromGateHold()
                }
            }
        }

        NotificationCenter.default.addObserver(forName: .karuWidgetDidRequestGateHold, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.transitEngine.enterGateHold()
            }
        }

        // Export initial snapshot on startup
        exportWidgetSnapshot()

        // 9. First-Time Pilot Onboarding Launch Check
        if !prefs.hasCompletedOnboarding {
            onboardingController?.showOnboarding { [weak self] updatedPrefs in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.applyPresentationMode(updatedPrefs.presentationMode)
                    self.dockTelemetryManager?.updateDockTile(force: true)
                    self.transitEngine.startFlight()
                }
            }
        }

        print("[Karu] Cockpit, Dock Telemetry & Focus Flight Engine initialized successfully.")
    }

    public func applyPresentationMode(_ mode: AppPresentationMode) {
        switch mode {
        case .standardDock:
            NSApp.setActivationPolicy(.regular)
        case .menuBarOnly:
            NSApp.setActivationPolicy(.accessory)
        }
    }

    public func replayOnboarding() {
        onboardingController?.showOnboarding { [weak self] updatedPrefs in
            Task { @MainActor in
                guard let self = self else { return }
                self.applyPresentationMode(updatedPrefs.presentationMode)
                self.dockTelemetryManager?.updateDockTile(force: true)
            }
        }
    }

    public func exportWidgetSnapshot() {
        let habits = storage.loadHabits()
        let trips = storage.loadTripHistory()
        let todayTrips = trips.filter { Calendar.current.isDateInToday($0.startDate) }
        let snapshot = transitEngine.generateWidgetSnapshot(dailyHabits: habits, todayTrips: todayTrips)
        try? storage.saveWidgetSnapshot(snapshot)
    }

    public func applicationWillTerminate(_ notification: Notification) {
        distractionMonitor.stop()
        audioEngine.stop()
    }

    // MARK: - Dynamic macOS Dock Context Menu

    public func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()

        // 1. Live Telemetry Readout
        let stateTitle: String
        switch transitEngine.state {
        case .cruising:
            stateTitle = "⚡ AIRSPEED: \(Int(transitEngine.currentVelocity)) KTS • CRUISING"
        case .trafficStalled:
            stateTitle = "⚠️ AIRSPEED: 0 KTS • TURBULENCE STALL"
        case .pitStop:
            stateTitle = "⏸ AIRSPEED: 0 KTS • GATE HOLD"
        case .completed:
            stateTitle = "✓ STATUS: TOUCHDOWN / COMPLETED"
        case .idle:
            stateTitle = "✈ STATUS: GATE STANDBY"
        }

        let telemetryItem = NSMenuItem(title: stateTitle, action: nil, keyEquivalent: "")
        telemetryItem.isEnabled = false
        menu.addItem(telemetryItem)

        if let session = transitEngine.activeSession {
            let target = session.targetDuration ?? 1500
            let cruising = session.cruisingDuration
            let remainingMins = max(0, Int(ceil((target - cruising) / 60.0)))
            let progressPct = Int((cruising / max(1, target)) * 100)
            let routeItem = NSMenuItem(
                title: "📍 Route: \(session.originAirportCode) ✈ \(session.destinationAirportCode) (\(progressPct)% • \(remainingMins)m left)",
                action: nil,
                keyEquivalent: ""
            )
            routeItem.isEnabled = false
            menu.addItem(routeItem)
        }

        menu.addItem(NSMenuItem.separator())

        // 2. Flight Dispatch Controls
        if transitEngine.state == .idle {
            let takeoffItem = NSMenuItem(title: "🛫 Takeoff Focus Flight (540 kts)", action: #selector(dockTakeoff), keyEquivalent: "")
            takeoffItem.target = self
            menu.addItem(takeoffItem)
        } else if transitEngine.state == .cruising || transitEngine.state == .trafficStalled {
            let holdItem = NSMenuItem(title: "⏸ Enter Gate Hold", action: #selector(dockToggleGateHold), keyEquivalent: "")
            holdItem.target = self
            menu.addItem(holdItem)

            let completeItem = NSMenuItem(title: "🛬 Touchdown / Complete Flight", action: #selector(dockCompleteFlight), keyEquivalent: "")
            completeItem.target = self
            menu.addItem(completeItem)

            let abortItem = NSMenuItem(title: "❌ Abort Flight", action: #selector(dockAbortFlight), keyEquivalent: "")
            abortItem.target = self
            menu.addItem(abortItem)
        } else if transitEngine.state == .pitStop {
            let resumeItem = NSMenuItem(title: "▶ Resume Cruising (540 kts)", action: #selector(dockToggleGateHold), keyEquivalent: "")
            resumeItem.target = self
            menu.addItem(resumeItem)

            let completeItem = NSMenuItem(title: "🛬 Touchdown / Complete Flight", action: #selector(dockCompleteFlight), keyEquivalent: "")
            completeItem.target = self
            menu.addItem(completeItem)
        }

        menu.addItem(NSMenuItem.separator())

        // 3. Cockpit Window Shortcuts
        let toggleHudItem = NSMenuItem(title: "Toggle Floating Cockpit HUD", action: #selector(dockToggleHUD), keyEquivalent: "")
        toggleHudItem.target = self
        menu.addItem(toggleHudItem)

        let logbookItem = NSMenuItem(title: "Pilot's Flight Logbook", action: #selector(dockOpenLogbook), keyEquivalent: "")
        logbookItem.target = self
        menu.addItem(logbookItem)

        let garageItem = NSMenuItem(title: "Aircraft Fleet Hangar", action: #selector(dockOpenGarage), keyEquivalent: "")
        garageItem.target = self
        menu.addItem(garageItem)

        let simulatorItem = NSMenuItem(title: "Desktop Widgets Simulator", action: #selector(dockOpenWidgets), keyEquivalent: "")
        simulatorItem.target = self
        menu.addItem(simulatorItem)

        let settingsItem = NSMenuItem(title: "Preferences & App Rules...", action: #selector(dockOpenSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let briefingItem = NSMenuItem(title: "Pre-Flight Cockpit Briefing...", action: #selector(dockOpenBriefing), keyEquivalent: "")
        briefingItem.target = self
        menu.addItem(briefingItem)

        return menu
    }

    // MARK: - Dock Action Handlers
    @objc private func dockTakeoff() { transitEngine.startFlight() }
    @objc private func dockToggleGateHold() { transitEngine.toggleGateHold() }
    @objc private func dockCompleteFlight() { transitEngine.completeTrip() }
    @objc private func dockAbortFlight() { transitEngine.cancelTrip() }
    @objc private func dockToggleHUD() { toggleFloatingHUD() }
    @objc private func dockOpenLogbook() { openLogbookWindow() }
    @objc private func dockOpenGarage() { openGarageWindow() }
    @objc private func dockOpenWidgets() { openWidgetSimulatorWindow() }
    @objc private func dockOpenSettings() { openSettingsWindow() }
    @objc private func dockOpenBriefing() { replayOnboarding() }

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
            window.title = "Karu Aircraft Hangar"
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
                contentRect: NSRect(x: 0, y: 0, width: 560, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Karu Preferences & App Rules"
            window.center()
            let settingsView = AppFilterSettingsView(
                classifier: classifier,
                storage: storage,
                onReplayOnboarding: { [weak self] in
                    self?.replayOnboarding()
                },
                onPresentationModeChanged: { [weak self] mode in
                    self?.applyPresentationMode(mode)
                    self?.dockTelemetryManager?.updateDockTile(force: true)
                }
            )
            window.contentView = NSHostingView(rootView: settingsView)
            self.settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func openLogbookWindow() {
        if logbookWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 580, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Pilot's Flight Logbook"
            window.center()
            let logbookView = LogbookView(storage: storage)
            window.contentView = NSHostingView(rootView: logbookView)
            self.logbookWindow = window
        }
        logbookWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func openWidgetSimulatorWindow() {
        if widgetSimulatorWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 580, height: 560),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Avionics Desktop Widget Simulator"
            window.center()
            let simulatorView = WidgetSimulatorView(engine: transitEngine)
            window.contentView = NSHostingView(rootView: simulatorView)
            self.widgetSimulatorWindow = window
        }
        widgetSimulatorWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
