import SwiftUI
import KaruCore

/// Stealth Pure Monochrome FocusFlight Popover Dashboard for macOS Menu Bar.
public struct DiagnosticPopoverView: View {
    @Bindable public var engine: TransitEngine
    public var audioEngine: AudioEngine
    public var storage: LocalStorageManager
    public var onToggleFloatingHUD: (() -> Void)?
    public var onOpenGarage: (() -> Void)?
    public var onOpenSettings: (() -> Void)?
    public var onOpenLogbook: (() -> Void)?

    public init(
        engine: TransitEngine,
        audioEngine: AudioEngine,
        storage: LocalStorageManager,
        onToggleFloatingHUD: (() -> Void)? = nil,
        onOpenGarage: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil,
        onOpenLogbook: (() -> Void)? = nil
    ) {
        self.engine = engine
        self.audioEngine = audioEngine
        self.storage = storage
        self.onToggleFloatingHUD = onToggleFloatingHUD
        self.onOpenGarage = onOpenGarage
        self.onOpenSettings = onOpenSettings
        self.onOpenLogbook = onOpenLogbook
    }

    public var body: some View {
        VStack(spacing: 0) {
            FocusFlightCard(
                state: engine.state,
                velocity: engine.currentVelocity,
                activeSession: engine.activeSession,
                aircraft: engine.activeAircraft,
                audioEngine: audioEngine,
                onStart: { preset, customDuration in
                    engine.startTrip(preset: preset, customDuration: customDuration)
                    audioEngine.start()
                },
                onStartFlight: { preset, customDuration, origin, destination, seatCode, taskTitle, seatIcon in
                    engine.startTrip(
                        preset: preset,
                        customDuration: customDuration,
                        origin: origin,
                        destination: destination,
                        seatCode: seatCode,
                        taskTitle: taskTitle,
                        seatIcon: seatIcon
                    )
                    audioEngine.start()
                },
                onHold: {
                    engine.toggleGateHold()
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
                },
                onOpenLogbook: {
                    onOpenLogbook?()
                }
            )
            Spacer(minLength: 0)
        }
    }
}
