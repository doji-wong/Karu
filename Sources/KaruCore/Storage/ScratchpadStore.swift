import Foundation
import Observation

/// Manages live in-flight note capture with debounced auto-saving to local storage.
@Observable
@MainActor
public final class ScratchpadStore {
    
    public var notes: String = "" {
        didSet {
            scheduleDebouncedSave()
        }
    }
    
    public private(set) var lastSavedDate: Date?
    private let storage: LocalStorageManager
    private var saveTask: Task<Void, Never>?

    public init(storage: LocalStorageManager) {
        self.storage = storage
        self.notes = storage.loadScratchpadText()
    }

    /// Immediately flush pending notes to disk without waiting for debounce.
    public func flush() {
        saveTask?.cancel()
        saveTask = nil
        try? storage.saveScratchpadText(notes)
        lastSavedDate = Date()
    }

    /// Clear scratchpad notes and sync with disk.
    public func clear() {
        notes = ""
        flush()
    }

    /// Debounce saves by 500ms to minimize disk I/O on rapid typing.
    private func scheduleDebouncedSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
            guard !Task.isCancelled else { return }
            try? storage.saveScratchpadText(notes)
            lastSavedDate = Date()
        }
    }
}
