import AppKit
import SwiftUI
import KaruCore

/// Manages the macOS NSStatusItem in the top menu bar and its dropdown popover.
@MainActor
public final class MenuBarController: NSObject {
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    private let engine: TransitEngine
    private let scratchpadStore: ScratchpadStore
    private let audioEngine: AudioEngine
    private let storage: LocalStorageManager
    
    public var onToggleFloatingHUD: (() -> Void)?
    public var onOpenGarage: (() -> Void)?
    public var onOpenSettings: (() -> Void)?

    public init(
        engine: TransitEngine,
        scratchpadStore: ScratchpadStore,
        audioEngine: AudioEngine,
        storage: LocalStorageManager
    ) {
        self.engine = engine
        self.scratchpadStore = scratchpadStore
        self.audioEngine = audioEngine
        self.storage = storage
        super.init()

        setupStatusItem()
        setupPopover()
        observeEngine()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.target = self
            button.action = #selector(togglePopover(_:))
            updateStatusItemVisuals()
        }
    }

    private func setupPopover() {
        let pop = NSPopover()
        pop.behavior = .transient
        pop.animates = true

        let rootView = DiagnosticPopoverView(
            engine: engine,
            scratchpadStore: scratchpadStore,
            audioEngine: audioEngine,
            storage: storage,
            onToggleFloatingHUD: { [weak self] in self?.onToggleFloatingHUD?() },
            onOpenGarage: { [weak self] in self?.onOpenGarage?() },
            onOpenSettings: { [weak self] in self?.onOpenSettings?() }
        )

        pop.contentViewController = NSHostingController(rootView: rootView)
        self.popover = pop
    }

    private func observeEngine() {
        // Update menu bar display whenever engine state or velocity changes
        engine.onStateChanged = { [weak self] _, _ in
            Task { @MainActor in
                self?.updateStatusItemVisuals()
            }
        }
    }

    // MARK: - Actions

    @objc public func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button, let pop = popover else { return }

        if pop.isShown {
            pop.performClose(sender)
        } else {
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            pop.contentViewController?.view.window?.makeKey()
        }
    }

    public func updateStatusItemVisuals() {
        guard let button = statusItem?.button else { return }

        // Use racing-themed SF Symbols as menu bar icon
        switch engine.state {
        case .idle:
            button.image = NSImage(systemSymbolName: "hare.fill", accessibilityDescription: "Karu — Idle")
            button.title = ""

        case .cruising:
            button.image = NSImage(systemSymbolName: "hare.fill", accessibilityDescription: "Karu — Cruising")
            button.title = " \(Int(engine.currentVelocity)) km/h"

        case .trafficStalled:
            button.image = NSImage(systemSymbolName: "tortoise.fill", accessibilityDescription: "Karu — Gridlock")
            button.title = " GRIDLOCK"

        case .pitStop:
            button.image = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: "Karu — Pit Stop")
            button.title = " PIT STOP"

        case .completed:
            button.image = NSImage(systemSymbolName: "flag.checkered", accessibilityDescription: "Karu — Arrived!")
            button.title = " 🏆 Arrived!"
        }
    }
}
