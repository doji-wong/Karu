import AppKit
import SwiftUI
import KaruCore

/// Floating HUD Window Controller for Karu macOS.
/// Anchors a draggable high-contrast flight card HUD on top of any workspace with dynamic hover expansion.
public final class FloatingHUDPanel: NSPanel {
    
    public init(engine: TransitEngine, scratchpadStore: ScratchpadStore) {
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 372, height: 156),
            styleMask: [.nonactivatingPanel, .borderless, .hudWindow],
            backing: .buffered,
            defer: false
        )
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true

        let hudView = FloatingHUDView(
            engine: engine,
            scratchpadStore: scratchpadStore,
            onClose: { [weak self] in
                self?.orderOut(nil)
            }
        )

        let hostingView = NSHostingView(rootView: hudView)
        hostingView.wantsLayer = true
        hostingView.layer?.allowsEdgeAntialiasing = true
        hostingView.layer?.edgeAntialiasingMask = [.layerLeftEdge, .layerRightEdge, .layerTopEdge, .layerBottomEdge]
        self.contentView = hostingView
        centerOnScreen()
    }

    private func centerOnScreen() {
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - 186
            let y = screenRect.minY + 60
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    public func toggleVisibility() {
        if self.isVisible {
            self.orderOut(nil)
        } else {
            self.orderFront(nil)
        }
    }
}
