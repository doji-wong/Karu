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
                engine: engine,
                audioEngine: audioEngine,
                onToggleFloatingHUD: onToggleFloatingHUD,
                onOpenGarage: onOpenGarage,
                onOpenSettings: onOpenSettings,
                onOpenLogbook: onOpenLogbook
            )
            Spacer(minLength: 0)
        }
    }
}
