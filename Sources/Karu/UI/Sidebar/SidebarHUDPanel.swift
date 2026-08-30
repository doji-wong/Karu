import AppKit
import SwiftUI
import KaruCore

/// Floating non-activating edge-docked NSPanel hosting the Aviation Cockpit HUD.
@MainActor
public final class SidebarHUDPanel: NSPanel {
    
    private var screenObserver: NSObjectProtocol?
    
    public init(
        engine: TransitEngine,
        scratchpadStore: ScratchpadStore,
        audioEngine: AudioEngine,
        storage: LocalStorageManager,
        onOpenGarage: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil
    ) {
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 340, height: 480),
            styleMask: [.nonactivatingPanel, .borderless, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        
        let sidebarView = SidebarHUDView(
            engine: engine,
            scratchpadStore: scratchpadStore,
            audioEngine: audioEngine,
            storage: storage,
            onOpenGarage: onOpenGarage,
            onOpenSettings: onOpenSettings
        )
        
        self.contentView = NSHostingView(rootView: sidebarView)
        positionFlushToBezel()
        observeScreenChanges()
    }
    
    deinit {
        if let obs = screenObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
    
    public func positionFlushToBezel() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        
        let width: CGFloat = 340
        let height: CGFloat = 480
        
        // Align right edge of panel flush against screen right bezel
        let x = screenFrame.maxX - width - 12
        let y = screenFrame.midY - (height / 2)
        
        self.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true, animate: false)
    }
    
    public func toggleVisibility() {
        if self.isVisible {
            self.orderOut(nil)
        } else {
            positionFlushToBezel()
            self.orderFront(nil)
        }
    }
    
    private func observeScreenChanges() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.positionFlushToBezel()
            }
        }
    }
}

