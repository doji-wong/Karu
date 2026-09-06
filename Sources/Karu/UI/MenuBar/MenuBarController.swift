import AppKit
import SwiftUI
import KaruCore

/// Custom borderless transparent dropdown panel for the macOS Menu Bar.
/// Eliminates macOS NSPopover frosted grey background shell and renders pure dark flight HUD.
@MainActor
public final class MenuBarPanel: NSPanel {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private weak var statusButton: NSStatusBarButton?
    public private(set) var showTimestamp: TimeInterval = 0

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
        self.statusButton = button
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
        self.showTimestamp = CACurrentMediaTime()
        startMonitoring()
    }

    public func hide() {
        self.orderOut(nil)
        stopMonitoring()
        onDidHide?()
    }

    private func startMonitoring() {
        stopMonitoring()
        
        // Global monitor: handles clicks outside the app
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self else { return }
            // Ignore events within 150ms of show to avoid closing on the initial menu bar click
            guard CACurrentMediaTime() - self.showTimestamp > 0.15 else { return }
            
            let mouseLoc = NSEvent.mouseLocation
            
            // If click is on the status bar button, let the button's action handler manage toggling
            if let button = self.statusButton, let btnWindow = button.window {
                let btnScreenRect = btnWindow.convertToScreen(button.bounds)
                if btnScreenRect.contains(mouseLoc) {
                    return
                }
            }
            
            // If click is inside the panel, do not dismiss
            if self.frame.contains(mouseLoc) {
                return
            }
            
            Task { @MainActor in
                self.hide()
            }
        }
        
        // Local monitor: handles clicks inside the app but outside this panel
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return event }
            if event.window == self {
                return event
            }
            if let button = self.statusButton, event.window == button.window {
                return event
            }
            if CACurrentMediaTime() - self.showTimestamp > 0.15 {
                Task { @MainActor in
                    self.hide()
                }
            }
            return event
        }
    }

    private func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    deinit {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMonitor {
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
    public var onOpenWidgetSimulator: (() -> Void)?
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
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.sendAction(on: [.leftMouseDown, .leftMouseUp])
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
            },
            onOpenWidgetSimulator: { [weak self] in
                self?.menuBarPanel?.hide()
                self?.onOpenWidgetSimulator?()
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

    // MARK: - Actions

    @objc public func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem?.button, let panel = menuBarPanel else { return }

        if panel.isVisible {
            if CACurrentMediaTime() - panel.showTimestamp < 0.2 {
                return
            }
            panel.hide()
        } else {
            panel.show(relativeTo: button)
        }
    }

    private var lastSetSymbol: String?
    private var lastSetTitle: String?

    public func updateStatusItemVisuals() {
        guard let button = statusItem?.button else { return }

        let symbol: String
        let desc: String
        let title: String

        switch engine.state {
        case .idle:
            symbol = "airplane"
            desc = "Karu — Flight Standby"
            title = ""

        case .cruising:
            symbol = "airplane.departure"
            desc = "Karu — Cruising Flight"
            if let session = engine.activeSession, let target = session.targetDuration {
                let remaining = max(0, target - session.cruisingDuration)
                let mins = Int(remaining) / 60
                title = " \(mins)m"
            } else {
                title = " 540 kts"
            }

        case .trafficStalled:
            symbol = "wind"
            desc = "Karu — In Turbulence"
            title = " [TURBULENCE]"

        case .pitStop:
            symbol = "pause.circle.fill"
            desc = "Karu — Gate Hold"
            title = " [HOLD]"

        case .completed:
            symbol = "airplane.arrival"
            desc = "Karu — Landed"
            title = " LANDED"
        }

        if symbol != lastSetSymbol {
            button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: desc)
            lastSetSymbol = symbol
        }
        if title != lastSetTitle {
            button.title = title
            lastSetTitle = title
        }
    }
}
