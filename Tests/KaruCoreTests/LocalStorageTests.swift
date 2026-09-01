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

    @Test("Legacy trip_history.json with cityDash25 and incidents decodes seamlessly")
    func legacyTripHistoryDecoding() throws {
        let (storage, tempDir) = createTestStorage()
        defer { cleanupTestStorage(url: tempDir) }

        let legacyJSON = """
        [
          {
            "id": "11111111-2222-3333-4444-555555555555",
            "preset": "cityDash25",
            "targetDuration": 1500,
            "startDate": "2026-08-29T10:00:00Z",
            "endDate": "2026-08-29T10:25:00Z",
            "cruisingDuration": 1200,
            "stalledDuration": 300,
            "pausedDuration": 0,
            "distanceTraveledKm": 37.04,
            "incidents": [
              {
                "id": "66666666-7777-8888-9999-000000000000",
                "timestamp": "2026-08-29T10:10:00Z",
                "appName": "Discord",
                "bundleIdentifier": "com.hnc.Discord",
                "duration": 300
              }
            ],
            "isCompleted": true
          }
        ]
        """.data(using: .utf8)!

        try legacyJSON.write(to: storage.tripsFileURL)

        let loaded = storage.loadTripHistory()
        #expect(loaded.count == 1)
        guard let session = loaded.first else { return }
        #expect(session.preset == .sprint25)
        #expect(session.cruisingDuration == 1200)
        #expect(session.stalledDuration == 300)
        #expect(abs(session.distanceTraveledNM - 20.0) < 0.1)
        #expect(session.turbulenceLogs.count == 1)
        #expect(session.turbulenceLogs.first?.appName == "Discord")
        #expect(session.isCompleted == true)
    }

    @Test("Legacy vehicle_profile.json with midnightEV decodes to a350F")
    func legacyVehicleProfileDecoding() throws {
        let (storage, tempDir) = createTestStorage()
        defer { cleanupTestStorage(url: tempDir) }

        let legacyVehicleJSON = """
        {
          "type": "midnightEV",
          "isSoundEnabled": true,
          "ambientVolume": 0.75
        }
        """.data(using: .utf8)!

        try legacyVehicleJSON.write(to: storage.vehicleFileURL)

        let loaded = storage.loadVehicleProfile()
        #expect(loaded.type == .a350F)
        #expect(loaded.isSoundEnabled == true)
        #expect(loaded.ambientVolume == 0.75)
    }

    @Test("LocalStorageManager persists and retrieves KaruPreferences accurately")
    func preferencesPersistence() throws {
        let (storage, tempDir) = createTestStorage()
        defer { cleanupTestStorage(url: tempDir) }

        let defaultPrefs = storage.loadPreferences()
        #expect(defaultPrefs.hasCompletedOnboarding == false)
        #expect(defaultPrefs.presentationMode == .standardDock)
        #expect(defaultPrefs.dockBadgeStyle == .timeRemaining)

        let customPrefs = KaruPreferences(
            hasCompletedOnboarding: true,
            presentationMode: .menuBarOnly,
            dockBadgeStyle: .airspeedKts,
            enableDockTileGraphics: false,
            dailyFlightGoalMinutes: 360,
            selectedMissionRole: .writer,
            launchAtLogin: true
        )

        try storage.savePreferences(customPrefs)

        let loaded = storage.loadPreferences()
        #expect(loaded == customPrefs)
        #expect(loaded.hasCompletedOnboarding == true)
        #expect(loaded.presentationMode == .menuBarOnly)
        #expect(loaded.dockBadgeStyle == .airspeedKts)
        #expect(loaded.dailyFlightGoalMinutes == 360)
        #expect(loaded.selectedMissionRole == .writer)
    }
}
