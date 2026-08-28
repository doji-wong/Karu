import AppKit
import SwiftUI
import KaruCore

/// Manages dual NSPanels positioned in the auxiliary areas flanking the MacBook hardware notch.
@MainActor
public final class NotchWindowController: NSObject {
    
    private var leftWingPanel: NSPanel?
    private var rightWingPanel: NSPanel?
    
    private let engine: TransitEngine
    private var screenObserver: NSObjectProtocol?

    public init(engine: TransitEngine) {
        self.engine = engine
        super.init()

        setupNotchPanels()
        observeScreenChanges()
    }

    deinit {
        if let obs = screenObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    // MARK: - Notch Layout & Geometry

    public func setupNotchPanels() {
        guard let mainScreen = NSScreen.main else { return }

        // Check if current display has hardware notch auxiliary areas
        guard let leftArea = mainScreen.auxiliaryTopLeftArea,
              let rightArea = mainScreen.auxiliaryTopRightArea,
              leftArea.width > 0, rightArea.width > 0 else {
            // Non-notch Mac or external monitor -> Close wings safely
            closeNotchPanels()
            return
        }

        // Left Wing Panel (Velocity)
        if leftWingPanel == nil {
            let panel = createNotchPanel()
            let leftView = NotchLeftWingView(engine: engine)
            panel.contentView = NSHostingView(rootView: leftView)
            self.leftWingPanel = panel
        }

        // Right Wing Panel (Route Progress)
        if rightWingPanel == nil {
            let panel = createNotchPanel()
            let rightView = NotchRightWingView(engine: engine)
            panel.contentView = NSHostingView(rootView: rightView)
            self.rightWingPanel = panel
        }

        // Position panels in the auxiliary areas
        let wingWidth: CGFloat = 110
        let wingHeight: CGFloat = 28
        let screenFrame = mainScreen.frame

        // Left wing sits on the right side of the left auxiliary area (flanking the notch)
        let leftX = leftArea.maxX - wingWidth - 4
        let leftY = screenFrame.maxY - wingHeight - 2
        leftWingPanel?.setFrame(NSRect(x: leftX, y: leftY, width: wingWidth, height: wingHeight), display: true)

        // Right wing sits on the left side of the right auxiliary area
        let rightX = rightArea.minX + 4
        let rightY = screenFrame.maxY - wingHeight - 2
        rightWingPanel?.setFrame(NSRect(x: rightX, y: rightY, width: wingWidth, height: wingHeight), display: true)

        leftWingPanel?.orderFront(nil)
        rightWingPanel?.orderFront(nil)
    }

    public func closeNotchPanels() {
        leftWingPanel?.close()
        rightWingPanel?.close()
        leftWingPanel = nil
        rightWingPanel = nil
    }

    private func observeScreenChanges() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.setupNotchPanels()
            }
        }
    }

    private func createNotchPanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        return panel
    }
}
