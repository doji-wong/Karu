import AppKit
import SwiftUI
import KaruCore

/// Floating HUD Window Controller for Karu Focus Flight.
public final class FloatingHUDPanel: NSPanel {
    public private(set) var isUserSuppressed: Bool = false
    
    public init(engine: TransitEngine) {
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 372, height: 380),
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
            onClose: { [weak self] in
                self?.userDismiss()
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

    public func userDismiss() {
        self.isUserSuppressed = true
        self.orderOut(nil)
    }

    public func resetSuppression() {
        self.isUserSuppressed = false
    }

    public func showFloating(force: Bool = false) {
        if force {
            isUserSuppressed = false
        }
        guard !isUserSuppressed else { return }
        if !self.isVisible {
            self.orderFront(nil)
        }
    }

    public func hideFloating() {
        self.orderOut(nil)
    }

    public func toggleVisibility() {
        if self.isVisible {
            userDismiss()
        } else {
            showFloating(force: true)
        }
    }
}
