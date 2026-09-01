import AppKit
import SwiftUI
import KaruCore

/// Manages the first-launch Pre-Flight Cockpit Briefing modal window.
@MainActor
public final class OnboardingWindowController {
    
    private var window: NSWindow?
    private let classifier: AppClassifier
    private let storage: LocalStorageManager

    public init(classifier: AppClassifier, storage: LocalStorageManager) {
        self.classifier = classifier
        self.storage = storage
    }

    /// Presents the onboarding briefing window centered on screen.
    public func showOnboarding(onTakeoff: @escaping (KaruPreferences) -> Void) {
        if window == nil {
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 620, height: 540),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            win.title = "Karu — Pre-Flight Cockpit Briefing"
            win.titlebarAppearsTransparent = true
            win.backgroundColor = NSColor(calibratedRed: 0.03, green: 0.03, blue: 0.05, alpha: 1.0)
            win.isReleasedWhenClosed = false
            win.center()

            let rootView = OnboardingView(
                classifier: classifier,
                storage: storage,
                onTakeoffAuthorized: { [weak self, weak win] prefs in
                    win?.close()
                    self?.window = nil
                    onTakeoff(prefs)
                }
            )
            win.contentView = NSHostingView(rootView: rootView)
            self.window = win
        }

        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func close() {
        window?.close()
        window = nil
    }
}
