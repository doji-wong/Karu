import Testing
@testable import KaruCore
import Foundation

@Suite("Local Storage Tests")
struct LocalStorageTests {

    private func createTestStorage() -> (LocalStorageManager, URL) {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("KaruTest-\(UUID().uuidString)")
        let storage = LocalStorageManager(baseDirectory: tempDir)
        return (storage, tempDir)
    }

    private func cleanupTestStorage(url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    @Test("LocalStorageManager saves and loads habits accurately")
    func habitPersistence() throws {
        let (storage, tempDir) = createTestStorage()
        defer { cleanupTestStorage(url: tempDir) }

        #expect(storage.loadHabits().isEmpty)

        var habit = Habit(name: "Daily SwiftUI", targetDailyMinutes: 30)
        habit.recordTripCompletion(duration: 1800)

        try storage.saveHabits([habit])

        let loaded = storage.loadHabits()
        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Daily SwiftUI")
        #expect(loaded.first?.currentStreakDays == 1)
    }

    @Test("LocalStorageManager appends and retrieves trip sessions")
    func tripSessionPersistence() throws {
        let (storage, tempDir) = createTestStorage()
        defer { cleanupTestStorage(url: tempDir) }

        #expect(storage.loadTripHistory().isEmpty)

        let trip = TripSession(
            preset: .expressway50,
            cruisingDuration: 3000,
            stalledDuration: 0,
            isCompleted: true
        )

        try storage.appendTripSession(trip)

        let loaded = storage.loadTripHistory()
        #expect(loaded.count == 1)
        #expect(loaded.first?.preset == .expressway50)
        #expect(loaded.first?.isCompleted == true)
    }

    @Test("LocalStorageManager persists custom filter rules and aircraft profile")
    func rulesAndVehiclePersistence() throws {
        let (storage, tempDir) = createTestStorage()
        defer { cleanupTestStorage(url: tempDir) }

        let rule = AppFilterRule(
            bundleIdentifier: "com.sublimetext.4",
            appName: "Sublime",
            category: .focusWorkspace,
            isCustomOverride: true
        )
        try storage.saveCustomRules([rule])

        let loadedRules = storage.loadCustomRules()
        #expect(loadedRules.count == 1)
        #expect(loadedRules.first?.bundleIdentifier == "com.sublimetext.4")

        let vehicle = AircraftProfile(type: .concordeSST, isSoundEnabled: false, ambientVolume: 0.4)
        try storage.saveVehicleProfile(vehicle)

        let loadedVehicle = storage.loadVehicleProfile()
        #expect(loadedVehicle.type == .concordeSST)
        #expect(loadedVehicle.isSoundEnabled == false)
        #expect(loadedVehicle.ambientVolume == 0.4)
    }

    @Test("Corrupted JSON files recover with safe defaults without crashing")
    func corruptionRecovery() throws {
        let (storage, tempDir) = createTestStorage()
        defer { cleanupTestStorage(url: tempDir) }

        // Write invalid JSON bytes directly to habits file
        let invalidJSON = "{ bad_json: broken [".data(using: .utf8)!
        try invalidJSON.write(to: storage.habitsFileURL)

        // Should return empty array default without throwing or crashing
        let recoveredHabits = storage.loadHabits()
        #expect(recoveredHabits.isEmpty)
    }
}
