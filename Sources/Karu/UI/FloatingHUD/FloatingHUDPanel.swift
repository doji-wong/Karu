import AppKit
import SwiftUI
import KaruCore

/// Always-on-top, non-activating translucent floating HUD window.
@MainActor
public final class FloatingHUDPanel: NSPanel {
    
    public init(engine: TransitEngine, scratchpadStore: ScratchpadStore) {
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 260, height: 42),
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

        self.contentView = NSHostingView(rootView: hudView)
        centerOnScreen()
    }

    private func centerOnScreen() {
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.maxX - 280
            let y = screenRect.minY + 80
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
