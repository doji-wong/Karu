import AppKit
import SwiftUI
import KaruCore

/// Custom NSHostingView subclass that accepts the first mouse click immediately
/// from any background workspace without dropping clicks.
private final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

/// Floating HUD Window Controller for Karu Focus Flight.
/// Anchors an ultra-compact minimalist plane progress bar HUD on top of any workspace with optional full card expansion.
@MainActor
public final class FloatingHUDPanel: NSPanel {
    public private(set) var isUserSuppressed: Bool = false
    
    // Enable borderless panel to receive keyboard focus for TextFields (search & custom seat)
    public override var canBecomeKey: Bool {
        return true
    }
    
    public init(
        engine: TransitEngine,
        audioEngine: AudioEngine? = nil,
        onOpenGarage: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil,
        onOpenLogbook: (() -> Void)? = nil,
        onOpenWidgetSimulator: (() -> Void)? = nil
    ) {
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
            audioEngine: audioEngine,
            onClose: { [weak self] in
                self?.userDismiss()
            },
            onSizeChange: { [weak self] width, height in
                self?.updatePanelSize(width: width, height: height, animated: true)
            },
            onOpenGarage: onOpenGarage,
            onOpenSettings: onOpenSettings,
            onOpenLogbook: onOpenLogbook,
            onOpenWidgetSimulator: onOpenWidgetSimulator
        )

        let hostingView = FirstMouseHostingView(rootView: hudView)
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
        
        // When expanding or collapsing drawers (both > 50pt tall), anchor to top edge
        // so the accordion opens downward without shifting header buttons away from the cursor
        if currentFrame.height > 50 && height > 50 {
            newY = currentFrame.maxY - height
        }
        
        if let screen = self.screen ?? NSScreen.main {
            let visible = screen.visibleFrame
            if newY + height > visible.maxY - 12 {
                newY = visible.maxY - height - 12
            }
            if newY < visible.minY + 12 {
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
