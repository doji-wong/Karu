import Foundation

/// Fast O(1) rule evaluation engine for categorizing active macOS applications.
public final class AppClassifier: @unchecked Sendable {
    
    // MARK: - Configuration
    public private(set) var activePreset: FocusPreset
    public private(set) var customRules: [String: AppFilterRule] = [:]
    public var isStrictModeEnabled: Bool = false
    
    // Internal cache combining preset rules + custom overrides for O(1) lookup
    private var ruleCache: [String: AppFocusCategory] = [:]
    private let lock = NSLock()

    public init(activePreset: FocusPreset = .developer, customRules: [AppFilterRule] = []) {
        self.activePreset = activePreset
        for rule in customRules {
            self.customRules[rule.bundleIdentifier] = rule
        }
        rebuildCache()
    }

    // MARK: - Classification

    /// Classify a macOS application bundle identifier into its AppFocusCategory.
    public func classify(bundleIdentifier: String?) -> AppFocusCategory {
        guard let bundleId = bundleIdentifier, !bundleId.isEmpty else {
            return .neutralUtility
        }

        lock.lock()
        defer { lock.unlock() }

        // 1. Direct cache lookup (User override > Preset rule)
        if let category = ruleCache[bundleId] {
            return category
        }

        // 2. Fallback heuristic
        if isStrictModeEnabled {
            return .distractionHazard
        } else {
            return .neutralUtility
        }
    }

    // MARK: - Rule Management

    /// Change the active preset and rebuild the evaluation cache.
    public func setPreset(_ preset: FocusPreset) {
        lock.lock()
        self.activePreset = preset
        lock.unlock()
        rebuildCache()
    }

    /// Add or update a custom rule override for a bundle identifier.
    public func setCustomRule(_ rule: AppFilterRule) {
        lock.lock()
        var updated = rule
        updated.isCustomOverride = true
        customRules[rule.bundleIdentifier] = updated
        lock.unlock()
        rebuildCache()
    }

    /// Remove a custom rule override.
    public func removeCustomRule(bundleIdentifier: String) {
        lock.lock()
        customRules.removeValue(forKey: bundleIdentifier)
        lock.unlock()
        rebuildCache()
    }

    /// Export all current active rules (presets + overrides).
    public func allActiveRules() -> [AppFilterRule] {
        lock.lock()
        defer { lock.unlock() }
        
        var results = activePreset.defaultRules
        for (_, custom) in customRules {
            if let index = results.firstIndex(where: { $0.bundleIdentifier == custom.bundleIdentifier }) {
                results[index] = custom
            } else {
                results.append(custom)
            }
        }
        return results
    }

    // MARK: - Internal Helpers

    private func rebuildCache() {
        lock.lock()
        defer { lock.unlock() }

        var newCache: [String: AppFocusCategory] = [:]

        // Populate from active preset
        for rule in activePreset.defaultRules {
            newCache[rule.bundleIdentifier] = rule.category
        }

        // Apply user overrides on top of preset
        for (_, rule) in customRules {
            newCache[rule.bundleIdentifier] = rule.category
        }

        self.ruleCache = newCache
    }
}
