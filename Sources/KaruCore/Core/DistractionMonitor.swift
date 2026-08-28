import Foundation
import AppKit

/// Event-driven monitor that listens to macOS frontmost application switches via NSWorkspace.
public final class DistractionMonitor: @unchecked Sendable {
    
    public let classifier: AppClassifier
    public var onAppActivated: (@Sendable (AppFocusCategory, String, String) -> Void)?
    
    private var observer: NSObjectProtocol?
    private var isRunning: Bool = false
    private let lock = NSLock()

    public init(classifier: AppClassifier = AppClassifier()) {
        self.classifier = classifier
    }

    deinit {
        stop()
    }

    /// Start listening for macOS frontmost application activation events.
    public func start() {
        lock.lock()
        defer { lock.unlock() }

        guard !isRunning else { return }
        isRunning = true

        // Subscribe to NSWorkspace application activation notifications
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleActivationNotification(notification)
        }

        // Check and evaluate current frontmost application immediately
        if let frontmost = NSWorkspace.shared.frontmostApplication {
            evaluateApplication(frontmost)
        }
    }

    /// Stop listening for application activation notifications.
    public func stop() {
        lock.lock()
        defer { lock.unlock() }

        guard isRunning else { return }
        isRunning = false

        if let obs = observer {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            observer = nil
        }
    }

    /// Manual evaluation trigger for mock/test environments.
    public func simulateApplicationSwitch(bundleIdentifier: String, appName: String) {
        let category = classifier.classify(bundleIdentifier: bundleIdentifier)
        onAppActivated?(category, appName, bundleIdentifier)
    }

    // MARK: - Private Notification Handler

    private func handleActivationNotification(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        evaluateApplication(app)
    }

    private func evaluateApplication(_ app: NSRunningApplication) {
        let bundleId = app.bundleIdentifier ?? ""
        let appName = app.localizedName ?? "Unknown App"
        let category = classifier.classify(bundleIdentifier: bundleId)
        
        onAppActivated?(category, appName, bundleId)
    }
}
