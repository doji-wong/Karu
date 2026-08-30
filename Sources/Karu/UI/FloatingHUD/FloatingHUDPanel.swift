import AppKit
import SwiftUI
import KaruCore

/// Floating HUD Window Controller for Karu Focus Flight.
/// Anchors an ultra-compact minimalist plane progress bar HUD on top of any workspace with optional full card expansion.
public final class FloatingHUDPanel: NSPanel {
    public private(set) var isUserSuppressed: Bool = false
    
    public init(engine: TransitEngine) {
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 390, height: 40),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false

        let hudView = FloatingHUDView(
            engine: engine,
            onClose: { [weak self] in
                self?.userDismiss()
            },
            onSizeChange: { [weak self] width, height in
                self?.updatePanelSize(width: width, height: height, animated: true)
            }
        )

        let hostingView = NSHostingView(rootView: hudView)
        hostingView.wantsLayer = true
        hostingView.layer?.allowsEdgeAntialiasing = true
        hostingView.layer?.edgeAntialiasingMask = [.layerLeftEdge, .layerRightEdge, .layerTopEdge, .layerBottomEdge]
        self.contentView = hostingView
        centerOnScreen(width: 390, height: 40)
    }

    private func centerOnScreen(width: CGFloat = 390, height: CGFloat = 40) {
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - (width / 2)
            let y = screenRect.minY + 60
            self.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
        }
    }

    public func updatePanelSize(width: CGFloat, height: CGFloat, animated: Bool = true) {
        let currentFrame = self.frame
        let newX = currentFrame.midX - (width / 2)
        var newY = currentFrame.minY
        
        if let screen = self.screen ?? NSScreen.main {
            let visible = screen.visibleFrame
            if newY + height > visible.maxY {
                newY = visible.maxY - height - 12
            }
            if newY < visible.minY {
                newY = visible.minY + 12
            }
        }
        
        let newFrame = NSRect(x: newX, y: newY, width: width, height: height)
        self.setFrame(newFrame, display: true, animate: animated)
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
