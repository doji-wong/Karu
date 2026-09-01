import AppKit
import SwiftUI
import KaruCore

/// Coordinates dynamic macOS Dock Icon graphics and telemetry badges.
@MainActor
public final class DockTelemetryManager {
    
    private let engine: TransitEngine
    private let storage: LocalStorageManager
    private var hostingView: NSHostingView<DynamicDockTileView>?
    private var lastDisplayedMinute: Int = -1
    private var lastState: TransitState?

    public init(engine: TransitEngine, storage: LocalStorageManager) {
        self.engine = engine
        self.storage = storage
    }

    /// Initializes dock tile listeners and performs initial rendering.
    public func start() {
        updateDockTile(force: true)
    }

    /// Updates the dock tile view and badge text.
    public func updateDockTile(force: Bool = false) {
        let prefs = storage.loadPreferences()
        
        let currentState = engine.state
        let session = engine.activeSession
        let targetDuration = session?.targetDuration ?? 1500
        let cruisingDuration = session?.cruisingDuration ?? 0
        let remainingSeconds = max(0, targetDuration - cruisingDuration)
        let remainingMinutes = Int(ceil(remainingSeconds / 60.0))
        let progress = targetDuration > 0 ? (cruisingDuration / targetDuration) : 0.0

        // Throttle check: only redraw if forced, state changed, or remaining minute changed
        let shouldRedraw = force || (currentState != lastState) || (remainingMinutes != lastDisplayedMinute)
        guard shouldRedraw else { return }

        self.lastState = currentState
        self.lastDisplayedMinute = remainingMinutes

        // 1. Update Graphics Content View if enabled
        if prefs.enableDockTileGraphics && prefs.presentationMode == .standardDock {
            let dockView = DynamicDockTileView(
                state: currentState,
                velocityKts: Int(engine.currentVelocity),
                progressFraction: progress,
                remainingMinutes: remainingMinutes,
                originCode: engine.activeOrigin,
                destinationCode: engine.activeDestination,
                aircraftCode: engine.activeAircraft.aircraftCode
            )

            if let existingHosting = hostingView {
                existingHosting.rootView = dockView
            } else {
                let newHosting = NSHostingView(rootView: dockView)
                newHosting.frame = NSRect(x: 0, y: 0, width: 128, height: 128)
                self.hostingView = newHosting
                NSApp.dockTile.contentView = newHosting
            }
        } else {
            if hostingView != nil {
                NSApp.dockTile.contentView = nil
                self.hostingView = nil
            }
        }

        // 2. Update Dock Badge
        if prefs.presentationMode == .standardDock {
            updateBadgeLabel(style: prefs.dockBadgeStyle, state: currentState, remainingMinutes: remainingMinutes)
        } else {
            NSApp.dockTile.badgeLabel = nil
        }

        // 3. Request Dock Display Refresh
        NSApp.dockTile.display()
    }

    private func updateBadgeLabel(style: DockBadgeStyle, state: TransitState, remainingMinutes: Int) {
        switch style {
        case .none:
            NSApp.dockTile.badgeLabel = nil

        case .timeRemaining:
            switch state {
            case .cruising:
                NSApp.dockTile.badgeLabel = "\(remainingMinutes)m"
            case .trafficStalled:
                NSApp.dockTile.badgeLabel = "STALL"
            case .pitStop:
                NSApp.dockTile.badgeLabel = "HOLD"
            case .completed:
                NSApp.dockTile.badgeLabel = "✓"
            case .idle:
                NSApp.dockTile.badgeLabel = nil
            }

        case .airspeedKts:
            switch state {
            case .cruising:
                NSApp.dockTile.badgeLabel = "\(Int(engine.currentVelocity))"
            case .trafficStalled:
                NSApp.dockTile.badgeLabel = "0"
            case .pitStop:
                NSApp.dockTile.badgeLabel = "HOLD"
            case .completed:
                NSApp.dockTile.badgeLabel = "✓"
            case .idle:
                NSApp.dockTile.badgeLabel = nil
            }
        }
    }
}
