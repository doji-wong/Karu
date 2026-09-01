import Foundation

/// Handles 100% local-first atomic JSON and Markdown persistence for Karu.
public final class LocalStorageManager: @unchecked Sendable {
    
    public let baseDirectory: URL
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let lock = NSLock()

    // In-Memory Read Caches
    private var cachedHabits: [Habit]?
    private var cachedTripHistory: [TripSession]?
    private var cachedCustomRules: [AppFilterRule]?
    private var cachedVehicleProfile: VehicleProfile?
    private var cachedWidgetSnapshot: WidgetTelemetrySnapshot?
    private var cachedPreferences: KaruPreferences?

    /// Default production initializer pointing to ~/Library/Application Support/Karu/
    public init(baseDirectory: URL? = nil) {
        if let dir = baseDirectory {
            self.baseDirectory = dir
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.baseDirectory = appSupport.appendingPathComponent("Karu", isDirectory: true)
        }

        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        ensureDirectoryExists()
    }

    // MARK: - File Paths
    public var habitsFileURL: URL { baseDirectory.appendingPathComponent("habits.json") }
    public var tripsFileURL: URL { baseDirectory.appendingPathComponent("trip_history.json") }
    public var filtersFileURL: URL { baseDirectory.appendingPathComponent("app_filters.json") }
    public var vehicleFileURL: URL { baseDirectory.appendingPathComponent("vehicle_profile.json") }
    public var widgetSnapshotFileURL: URL { baseDirectory.appendingPathComponent("widget_snapshot.json") }
    public var preferencesFileURL: URL { baseDirectory.appendingPathComponent("preferences.json") }

    // MARK: - Generic Atomic Read/Write

    public func save<T: Encodable>(_ object: T, to fileURL: URL) throws {
        lock.lock()
        defer { lock.unlock() }

        ensureDirectoryExists()
        let data = try encoder.encode(object)
        try data.write(to: fileURL, options: [.atomic])
    }

    public func load<T: Decodable>(from fileURL: URL, defaultValue: T) -> T {
        lock.lock()
        defer { lock.unlock() }

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return defaultValue
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(T.self, from: data)
        } catch {
            print("[KaruStorage] Error decoding \(fileURL.lastPathComponent): \(error). Falling back to default.")
            return defaultValue
        }
    }

    // MARK: - Entity Helpers with O(1) In-Memory Cache

    public func saveHabits(_ habits: [Habit]) throws {
        lock.lock()
        self.cachedHabits = habits
        lock.unlock()
        try save(habits, to: habitsFileURL)
    }

    public func loadHabits() -> [Habit] {
        lock.lock()
        if let cached = cachedHabits {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let loaded: [Habit] = load(from: habitsFileURL, defaultValue: [])
        lock.lock()
        self.cachedHabits = loaded
        lock.unlock()
        return loaded
    }

    public func saveTripHistory(_ trips: [TripSession]) throws {
        lock.lock()
        self.cachedTripHistory = trips
        lock.unlock()
        try save(trips, to: tripsFileURL)
    }

    public func loadTripHistory() -> [TripSession] {
        lock.lock()
        if let cached = cachedTripHistory {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let loaded: [TripSession] = load(from: tripsFileURL, defaultValue: [])
        lock.lock()
        self.cachedTripHistory = loaded
        lock.unlock()
        return loaded
    }

    public func appendTripSession(_ session: TripSession) throws {
        var trips = loadTripHistory()
        trips.append(session)
        try saveTripHistory(trips)
    }

    public func saveCustomRules(_ rules: [AppFilterRule]) throws {
        lock.lock()
        self.cachedCustomRules = rules
        lock.unlock()
        try save(rules, to: filtersFileURL)
    }

    public func loadCustomRules() -> [AppFilterRule] {
        lock.lock()
        if let cached = cachedCustomRules {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let loaded: [AppFilterRule] = load(from: filtersFileURL, defaultValue: [])
        lock.lock()
        self.cachedCustomRules = loaded
        lock.unlock()
        return loaded
    }

    public func saveVehicleProfile(_ profile: VehicleProfile) throws {
        lock.lock()
        self.cachedVehicleProfile = profile
        lock.unlock()
        try save(profile, to: vehicleFileURL)
    }

    public func loadVehicleProfile() -> VehicleProfile {
        lock.lock()
        if let cached = cachedVehicleProfile {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let loaded: VehicleProfile = load(from: vehicleFileURL, defaultValue: VehicleProfile())
        lock.lock()
        self.cachedVehicleProfile = loaded
        lock.unlock()
        return loaded
    }

    public func saveWidgetSnapshot(_ snapshot: WidgetTelemetrySnapshot) throws {
        lock.lock()
        self.cachedWidgetSnapshot = snapshot
        lock.unlock()
        try save(snapshot, to: widgetSnapshotFileURL)
    }

    public func loadWidgetSnapshot() -> WidgetTelemetrySnapshot {
        lock.lock()
        if let cached = cachedWidgetSnapshot {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let loaded: WidgetTelemetrySnapshot = load(from: widgetSnapshotFileURL, defaultValue: .idleMock)
        lock.lock()
        self.cachedWidgetSnapshot = loaded
        lock.unlock()
        return loaded
    }

    public func savePreferences(_ preferences: KaruPreferences) throws {
        lock.lock()
        self.cachedPreferences = preferences
        lock.unlock()
        try save(preferences, to: preferencesFileURL)
    }

    public func loadPreferences() -> KaruPreferences {
        lock.lock()
        if let cached = cachedPreferences {
            lock.unlock()
            return cached
        }
        lock.unlock()

        let loaded: KaruPreferences = load(from: preferencesFileURL, defaultValue: KaruPreferences())
        lock.lock()
        self.cachedPreferences = loaded
        lock.unlock()
        return loaded
    }

    // MARK: - Directory Management

    private func ensureDirectoryExists() {
        if !fileManager.fileExists(atPath: baseDirectory.path) {
            try? fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }
}
