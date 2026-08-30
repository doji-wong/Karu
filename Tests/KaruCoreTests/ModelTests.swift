import Testing
@testable import KaruCore
import Foundation

@Suite("Domain Model Tests")
struct ModelTests {
    
    @Test("TransitState target velocity and display properties")
    func transitStateProperties() {
        #expect(TransitState.idle.targetVelocity == 0.0)
        #expect(TransitState.cruising.targetVelocity == 540.0)
        #expect(TransitState.trafficStalled.targetVelocity == 0.0)
        #expect(TransitState.pitStop.targetVelocity == 0.0)
        #expect(TransitState.completed.targetVelocity == 0.0)
        
        #expect(TransitState.cruising.displayTitle == "On Time")
        #expect(TransitState.trafficStalled.displayTitle == "In Turbulence")
    }

    @Test("FlightBoardingInfo and AirportRoutePreset logic")
    func flightBoardingInfoAndPresets() {
        let boarding = FlightBoardingInfo()
        #expect(boarding.flightNumber == "FL 288")
        #expect(boarding.seatNumber == "Seat 1A")
        #expect(boarding.seatClass == .deepWork)
        #expect(boarding.originAirport.code == "SIN")
        #expect(boarding.destinationAirport.code == "LHR")
        #expect(boarding.aircraftType == "A350F")

        let sinLhr = AirportRoutePreset.sinLhr
        #expect(sinLhr.originCode == "SIN")
        #expect(sinLhr.destinationCode == "LHR")
        #expect(sinLhr.defaultAircraft == "A350F")

        // Test destination airport timezone lookup
        let tokyo = DestinationAirport.find(code: "HND")
        #expect(tokyo.cityName == "Tokyo")
        #expect(tokyo.countryFlag == "🇯🇵")
        #expect(tokyo.timeZoneCode == "JST")
        #expect(tokyo.utcOffsetHours == 9.0)

        // Test FocusSeatClass
        let codeSeat = FocusSeatClass.code
        #expect(codeSeat.seatCode == "Seat 5F")
        #expect(codeSeat.title == "Coding & Ship")
    }

    @Test("TripPreset duration and target distance math")
    func tripPresetCalculations() {
        #expect(TripPreset.sprint25.targetDuration == TimeInterval(25 * 60))
        #expect(TripPreset.cruise50.targetDuration == TimeInterval(50 * 60))
        #expect(TripPreset.longHaul90.targetDuration == TimeInterval(90 * 60))
        #expect(TripPreset.openFlight.targetDuration == nil)
        
        let expectedNM = ((25.0 * 60.0) / 3600.0) * 540.0
        let actualNM = TripPreset.sprint25.targetDistanceNM ?? 0
        #expect(abs(actualNM - expectedNM) < 0.001)
    }

    @Test("TripSession efficiency calculation and Codable roundtrip")
    func tripSessionCalculationsAndSerialization() throws {
        var session = TripSession(
            preset: .cityDash25,
            cruisingDuration: 1200, // 20 min
            stalledDuration: 300,   // 5 min
            pausedDuration: 60      // 1 min
        )
        
        #expect(session.activeTransitDuration == 1500)
        #expect(session.totalElapsedDuration == 1560)
        
        // Efficiency = 1200 / 1500 * 100 = 80.0%
        #expect(abs(session.cruiseEfficiency - 80.0) < 0.001)
        
        // Progress = 1200 / 1500 = 0.8
        #expect(abs(session.progressFraction - 0.8) < 0.001)
        
        // Add traffic incident
        let incident = TrafficIncident(appName: "Discord", bundleIdentifier: "com.hnc.Discord", duration: 180)
        session.incidents.append(incident)
        
        // Verify Codable roundtrip
        let encoder = JSONEncoder()
        let data = try encoder.encode(session)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TripSession.self, from: data)
        
        #expect(session.id == decoded.id)
        #expect(abs(decoded.cruiseEfficiency - 80.0) < 0.001)
        #expect(decoded.incidents.count == 1)
        #expect(decoded.incidents.first?.appName == "Discord")
    }

    @Test("Habit streak increment and tracking")
    func habitStreakUpdates() {
        var habit = Habit(name: "Daily Coding", targetDailyMinutes: 50)
        #expect(habit.currentStreakDays == 0)
        #expect(habit.longestStreakDays == 0)
        
        habit.recordTripCompletion(duration: 3000)
        #expect(habit.currentStreakDays == 1)
        #expect(habit.longestStreakDays == 1)
        #expect(habit.totalCompletedTrips == 1)
        #expect(habit.totalFocusSeconds == 3000)
    }

    @Test("FocusPresets contain curated focus tools and distractions")
    func focusPresetsContainRequiredRules() {
        let devRules = FocusPreset.developer.defaultRules
        #expect(devRules.contains(where: { $0.bundleIdentifier == "com.apple.dt.Xcode" && $0.category == .focusWorkspace }))
        #expect(devRules.contains(where: { $0.bundleIdentifier == "com.hnc.Discord" && $0.category == .distractionHazard }))
        #expect(devRules.contains(where: { $0.bundleIdentifier == "com.apple.finder" && $0.category == .neutralUtility }))
        
        let studentRules = FocusPreset.student.defaultRules
        #expect(studentRules.contains(where: { $0.bundleIdentifier == "md.obsidian" && $0.category == .focusWorkspace }))
        
        let writerRules = FocusPreset.writer.defaultRules
        #expect(writerRules.contains(where: { $0.bundleIdentifier == "com.ulyssesapp.mac" && $0.category == .focusWorkspace }))
    }

    @Test("Vehicle profiles and audio configuration")
    func vehicleProfiles() {
        let ev = VehicleType.midnightEV
        #expect(ev.themeColorHex == "#FF5C00")
        #expect(!ev.soundProfileId.isEmpty)
        #expect(!ev.stallSoundProfileId.isEmpty)

        let profile = VehicleProfile(type: .classicSarao, isSoundEnabled: true, ambientVolume: 0.8)
        #expect(profile.type == .classicSarao)
        #expect(profile.ambientVolume == 0.8)
    }

    @Test("FlightPreset and AircraftType decode legacy raw values correctly")
    func legacyEnumDecoding() throws {
        let decoder = JSONDecoder()

        // FlightPreset legacy mappings
        let cityDash = try decoder.decode(FlightPreset.self, from: Data("\"cityDash25\"".utf8))
        #expect(cityDash == .sprint25)

        let expressway = try decoder.decode(FlightPreset.self, from: Data("\"expressway50\"".utf8))
        #expect(expressway == .cruise50)

        let interstate = try decoder.decode(FlightPreset.self, from: Data("\"interstate90\"".utf8))
        #expect(interstate == .longHaul90)

        let openHwy = try decoder.decode(FlightPreset.self, from: Data("\"openHighway\"".utf8))
        #expect(openHwy == .openFlight)

        // AircraftType legacy mappings
        let midnight = try decoder.decode(AircraftType.self, from: Data("\"midnightEV\"".utf8))
        #expect(midnight == .a350F)

        let sarao = try decoder.decode(AircraftType.self, from: Data("\"classicSarao\"".utf8))
        #expect(sarao == .b787Dreamliner)

        let rainHatchback = try decoder.decode(AircraftType.self, from: Data("\"nightRainHatchback\"".utf8))
        #expect(rainHatchback == .concordeSST)

        let shinkansen = try decoder.decode(AircraftType.self, from: Data("\"shinkansenExpress\"".utf8))
        #expect(shinkansen == .gulfstreamG650)

        let bus = try decoder.decode(AircraftType.self, from: Data("\"coastalBus\"".utf8))
        #expect(bus == .cessna172)
    }
}
