import Testing
import Foundation
@testable import KaruCore

@Suite("Widget Telemetry & Snapshot Tests")
struct WidgetTelemetryTests {

    @Test("WidgetTelemetrySnapshot Codable serialization roundtrip")
    func snapshotCodableRoundtrip() throws {
        let original = WidgetTelemetrySnapshot(
            state: .cruising,
            currentAirspeedKts: 540,
            originIATA: "JFK",
            originCity: "New York",
            destinationIATA: "LHR",
            destinationCity: "London",
            statusBadgeText: "CRUISING 540 KTS",
            dailyCompletedMinutes: 240,
            dailyGoalMinutes: 300,
            dailyDistanceNM: 2160.0,
            dailyEfficiencyPercentage: 96.5,
            currentStreakDays: 15,
            activeAircraftName: "B787",
            lastUpdated: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(WidgetTelemetrySnapshot.self, from: data)

        #expect(decoded.state == .cruising)
        #expect(decoded.currentAirspeedKts == 540)
        #expect(decoded.originIATA == "JFK")
        #expect(decoded.destinationIATA == "LHR")
        #expect(decoded.dailyCompletedMinutes == 240)
        #expect(decoded.dailyGoalMinutes == 300)
        #expect(decoded.dailyDistanceNM == 2160.0)
        #expect(decoded.dailyEfficiencyPercentage == 96.5)
        #expect(decoded.currentStreakDays == 15)
        #expect(decoded.activeAircraftName == "B787")
    }

    @Test("WidgetTelemetrySnapshot presentation properties and math")
    func snapshotPresentationProperties() {
        let snapshot = WidgetTelemetrySnapshot(
            state: .cruising,
            currentAirspeedKts: 540,
            originIATA: "SFO",
            originCity: "San Francisco",
            destinationIATA: "HND",
            destinationCity: "Tokyo",
            statusBadgeText: "CRUISING 540 KTS",
            dailyCompletedMinutes: 210,
            dailyGoalMinutes: 300,
            dailyDistanceNM: 1890.0,
            dailyEfficiencyPercentage: 94.2,
            currentStreakDays: 12,
            activeAircraftName: "A350F"
        )

        #expect(snapshot.dailyProgressFraction == 0.7)
        #expect(snapshot.formattedCompletedHours == "3.5h")
        #expect(snapshot.formattedGoalHours == "5.0h")
        #expect(snapshot.formattedDistanceNM.contains("1 890 NM") || snapshot.formattedDistanceNM.contains("1890 NM"))
        #expect(snapshot.formattedEfficiency == "94%")
    }

    @Test("LocalStorageManager saves and loads widget telemetry snapshot atomically")
    func localStorageManagerWidgetSnapshotRoundtrip() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("KaruWidgetTest_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let storage = LocalStorageManager(baseDirectory: tempDir)
        let sampleSnapshot = WidgetTelemetrySnapshot.previewMock

        try storage.saveWidgetSnapshot(sampleSnapshot)

        #expect(FileManager.default.fileExists(atPath: storage.widgetSnapshotFileURL.path))

        let loaded = storage.loadWidgetSnapshot()
        #expect(loaded.originIATA == "SFO")
        #expect(loaded.destinationIATA == "HND")
        #expect(loaded.currentAirspeedKts == 540)
        #expect(loaded.dailyCompletedMinutes == 210)
        #expect(loaded.currentStreakDays == 12)
    }

    @Test("LocalStorageManager recovers from corrupted widget_snapshot.json with idleMock")
    func corruptedWidgetSnapshotRecovery() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("KaruCorruptedWidgetTest_\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let storage = LocalStorageManager(baseDirectory: tempDir)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let badData = "INVALID_JSON_STREAM_###".data(using: .utf8)!
        try badData.write(to: storage.widgetSnapshotFileURL)

        let recovered = storage.loadWidgetSnapshot()
        #expect(recovered.state == .idle)
        #expect(recovered.currentAirspeedKts == 0)
        #expect(recovered.statusBadgeText == "GATE STANDBY")
    }
}
