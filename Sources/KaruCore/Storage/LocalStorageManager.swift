import Foundation

/// Handles 100% local-first atomic JSON and Markdown persistence for Karu.
public final class LocalStorageManager: @unchecked Sendable {
    
    public let baseDirectory: URL
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let lock = NSLock()

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

    // MARK: - Entity Helpers

    public func saveHabits(_ habits: [Habit]) throws {
        try save(habits, to: habitsFileURL)
    }

    public func loadHabits() -> [Habit] {
        load(from: habitsFileURL, defaultValue: [])
    }

    public func saveTripHistory(_ trips: [TripSession]) throws {
        try save(trips, to: tripsFileURL)
    }

    public func loadTripHistory() -> [TripSession] {
        load(from: tripsFileURL, defaultValue: [])
    }

    public func appendTripSession(_ session: TripSession) throws {
        var trips = loadTripHistory()
        trips.append(session)
        try saveTripHistory(trips)
    }

    public func saveCustomRules(_ rules: [AppFilterRule]) throws {
        try save(rules, to: filtersFileURL)
    }

    public func loadCustomRules() -> [AppFilterRule] {
        load(from: filtersFileURL, defaultValue: [])
    }

    public func saveVehicleProfile(_ profile: VehicleProfile) throws {
        try save(profile, to: vehicleFileURL)
    }

    public func loadVehicleProfile() -> VehicleProfile {
        load(from: vehicleFileURL, defaultValue: VehicleProfile())
    }

    // MARK: - Directory Management

    private func ensureDirectoryExists() {
        if !fileManager.fileExists(atPath: baseDirectory.path) {
            try? fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }
}
