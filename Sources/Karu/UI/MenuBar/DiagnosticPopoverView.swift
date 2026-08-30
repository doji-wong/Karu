import SwiftUI
import KaruCore

/// Stealth Pure Monochrome FocusFlight Popover Dashboard for macOS Menu Bar.
public struct DiagnosticPopoverView: View {
    @Bindable public var engine: TransitEngine
    @Bindable public var scratchpadStore: ScratchpadStore
    public var audioEngine: AudioEngine
    public var storage: LocalStorageManager
    public var onToggleSidebarHUD: (() -> Void)?
    public var onToggleFloatingHUD: (() -> Void)?
    public var onOpenGarage: (() -> Void)?
    public var onOpenSettings: (() -> Void)?

    public init(
        engine: TransitEngine,
        scratchpadStore: ScratchpadStore,
        audioEngine: AudioEngine,
        storage: LocalStorageManager,
        onToggleSidebarHUD: (() -> Void)? = nil,
        onToggleFloatingHUD: (() -> Void)? = nil,
        onOpenGarage: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil
    ) {
        self.engine = engine
        self.scratchpadStore = scratchpadStore
        self.audioEngine = audioEngine
        self.storage = storage
        self.onToggleSidebarHUD = onToggleSidebarHUD
        self.onToggleFloatingHUD = onToggleFloatingHUD
        self.onOpenGarage = onOpenGarage
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        VStack(spacing: 0) {
            FocusFlightCard(
                state: engine.state,
                velocity: engine.currentVelocity,
                activeSession: engine.activeSession,
                vehicle: engine.activeVehicle,
                audioEngine: audioEngine,
                scratchpadStore: scratchpadStore,
                onStart: { preset, customDuration in
                    engine.startTrip(preset: preset, customDuration: customDuration)
                    audioEngine.start()
                },
                onHold: {
                    engine.togglePitStop()
                },
                onDock: {
                    engine.completeTrip()
                },
                onAbort: {
                    engine.cancelTrip()
                },
                onToggleFloatingHUD: {
                    onToggleFloatingHUD?()
                },
                onOpenGarage: {
                    onOpenGarage?()
                },
                onOpenSettings: {
                    onOpenSettings?()
                }
            )
            Spacer(minLength: 0)
        }
    }
}
