import AppKit
import SwiftUI
import KaruCore

/// Custom borderless transparent dropdown panel for the macOS Menu Bar.
/// Eliminates macOS NSPopover frosted grey background shell and renders pure dark flight HUD.
@MainActor
public final class MenuBarPanel: NSPanel {
    private var globalMonitor: Any?
    private var localMonitor: Any?

    public var onDidHide: (() -> Void)?

    public init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 372, height: 156),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        self.level = .popUpMenu
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.contentView = contentView
    }

    public func show(relativeTo button: NSStatusBarButton) {
        guard let buttonWindow = button.window else { return }
        let buttonScreenRect = buttonWindow.convertToScreen(button.bounds)
        let panelWidth: CGFloat = 372
        let panelHeight: CGFloat = 156
        
        var x = buttonScreenRect.midX - (panelWidth / 2)
        if let screen = buttonWindow.screen {
            let maxRight = screen.visibleFrame.maxX - panelWidth - 8
            let minLeft = screen.visibleFrame.minX + 8
            x = max(minLeft, min(x, maxRight))
        }
        let y = buttonScreenRect.minY - panelHeight - 6
        
        self.setFrameOrigin(NSPoint(x: x, y: y))
        self.makeKeyAndOrderFront(nil)
        startMonitoring(buttonWindow: buttonWindow)
    }

    public func hide() {
        self.orderOut(nil)
        stopMonitoring()
        onDidHide?()
    }

    private func startMonitoring(buttonWindow: NSWindow) {
        stopMonitoring()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.hide()
            }
        }
    }

    private func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }

    deinit {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

/// Manages the macOS NSStatusItem in the top menu bar and its pure transparent dropdown panel.
@MainActor
public final class MenuBarController: NSObject {
    
    private var statusItem: NSStatusItem?
    private var menuBarPanel: MenuBarPanel?
    
    private let engine: TransitEngine
    private let audioEngine: AudioEngine
    private let storage: LocalStorageManager
    
    public var onToggleFloatingHUD: (() -> Void)?
    public var onOpenGarage: (() -> Void)?
    public var onOpenSettings: (() -> Void)?
    public var onOpenLogbook: (() -> Void)?
    public var onPopoverDismissed: (() -> Void)?

    public init(
        engine: TransitEngine,
        audioEngine: AudioEngine,
        storage: LocalStorageManager
    ) {
        self.engine = engine
        self.audioEngine = audioEngine
        self.storage = storage
        super.init()

        setupStatusItem()
        setupPanel()
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

    private func setupPanel() {
        let rootView = DiagnosticPopoverView(
            engine: engine,
            audioEngine: audioEngine,
            storage: storage,
            onToggleFloatingHUD: { [weak self] in 
                self?.menuBarPanel?.hide()
                self?.onToggleFloatingHUD?() 
            },
            onOpenGarage: { [weak self] in 
                self?.menuBarPanel?.hide()
                self?.onOpenGarage?() 
            },
            onOpenSettings: { [weak self] in 
                self?.menuBarPanel?.hide()
                self?.onOpenSettings?() 
            },
            onOpenLogbook: { [weak self] in
                self?.menuBarPanel?.hide()
                self?.onOpenLogbook?()
            }
        )

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layer?.allowsEdgeAntialiasing = true
        hostingView.layer?.edgeAntialiasingMask = [.layerLeftEdge, .layerRightEdge, .layerTopEdge, .layerBottomEdge]
        
        let panel = MenuBarPanel(contentView: hostingView)
        panel.onDidHide = { [weak self] in
            self?.onPopoverDismissed?()
        }
        self.menuBarPanel = panel
    }

    public func hidePopover() {
        menuBarPanel?.hide()
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
        guard let button = statusItem?.button, let panel = menuBarPanel else { return }

        if panel.isVisible {
            panel.hide()
        } else {
            panel.show(relativeTo: button)
        }
    }

    public func updateStatusItemVisuals() {
        guard let button = statusItem?.button else { return }

        switch engine.state {
        case .idle:
            button.image = NSImage(systemSymbolName: "airplane", accessibilityDescription: "Karu — Flight Standby")
            button.title = ""

        case .cruising:
            button.image = NSImage(systemSymbolName: "airplane.departure", accessibilityDescription: "Karu — Cruising Flight")
            if let session = engine.activeSession, let target = session.targetDuration {
                let remaining = max(0, target - session.cruisingDuration)
                let mins = Int(remaining) / 60
                button.title = " 🛬 \(mins)m"
            } else {
                button.title = " 540 kts"
            }

        case .trafficStalled:
            button.image = NSImage(systemSymbolName: "wind", accessibilityDescription: "Karu — In Turbulence")
            button.title = " [TURBULENCE]"

        case .pitStop:
            button.image = NSImage(systemSymbolName: "pause.circle.fill", accessibilityDescription: "Karu — Gate Hold")
            button.title = " [HOLD]"

        case .completed:
            button.image = NSImage(systemSymbolName: "airplane.arrival", accessibilityDescription: "Karu — Landed")
            button.title = " LANDED"
        }
    }
}
