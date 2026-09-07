import Testing
@testable import KaruCore
import Foundation

@Suite("Transit Engine Tests")
struct TransitEngineTests {

    @Test("TransitEngine initial state is idle")
    @MainActor
    func initialState() {
        let engine = TransitEngine()
        #expect(engine.state == .idle)
        #expect(engine.currentVelocity == 0.0)
        #expect(engine.activeSession == nil)
    }

    @Test("Starting a flight sets cruising state and 540 kts velocity")
    @MainActor
    func startTrip() {
        let engine = TransitEngine()
        var stateChanges: [(TransitState, TransitState)] = []
        engine.onStateChanged = { old, new in
            stateChanges.append((old, new))
        }

        engine.startTrip(preset: .sprint25)

        #expect(engine.state == .cruising)
        #expect(engine.currentVelocity == 540.0)
        #expect(engine.activeSession != nil)
        #expect(engine.activeSession?.preset == .sprint25)
        #expect(stateChanges.count == 1)
        #expect(stateChanges.first?.0 == .idle)
        #expect(stateChanges.first?.1 == .cruising)
    }

    @Test("Switching into distraction app enters turbulence and logs encounter")
    @MainActor
    func distractionSwitchAndRecovery() {
        let engine = TransitEngine()
        engine.startTrip(preset: .sprint25)

        // Cruise for 10 seconds
        for _ in 0..<10 {
            engine.tick(seconds: 1.0)
        }
        #expect(engine.activeSession?.cruisingDuration == 10.0)

        // Switch to distraction
        engine.handleAppCategoryChange(
            category: .distractionHazard,
            appName: "Discord",
            bundleIdentifier: "com.hnc.Discord"
        )

        #expect(engine.state == .trafficStalled)
        #expect(engine.currentVelocity == 0.0)

        // Stall for 5 seconds
        for _ in 0..<5 {
            engine.tick(seconds: 1.0)
        }
        #expect(engine.activeSession?.stalledDuration == 5.0)

        // Neutral utility should not alter stall state
        engine.handleAppCategoryChange(
            category: .neutralUtility,
            appName: "Finder",
            bundleIdentifier: "com.apple.finder"
        )
        #expect(engine.state == .trafficStalled)

        // Switch back to focus workspace
        engine.handleAppCategoryChange(
            category: .focusWorkspace,
            appName: "Xcode",
            bundleIdentifier: "com.apple.dt.Xcode"
        )

        #expect(engine.state == .cruising)
        #expect(engine.currentVelocity == 540.0)
        #expect(engine.activeSession?.turbulenceLogs.count == 1)
        #expect(engine.activeSession?.turbulenceLogs.first?.appName == "Discord")
        #expect(engine.activeSession?.turbulenceLogs.first?.duration == 5.0)
    }

    @Test("Gate hold pauses flight and preserves turbulence tracking")
    @MainActor
    func pitStopBehavior() {
        let engine = TransitEngine()
        engine.startTrip(preset: .sprint25)

        engine.toggleGateHold()
        #expect(engine.state == .pitStop)
        #expect(engine.currentVelocity == 0.0)

        engine.tick(seconds: 15.0)
        #expect(engine.activeSession?.pausedDuration == 15.0)

        engine.toggleGateHold()
        #expect(engine.state == .cruising)
        #expect(engine.currentVelocity == 540.0)
    }

    @Test("Trip auto-completes upon reaching target distance / duration")
    @MainActor
    func tripAutoCompletion() {
        let engine = TransitEngine()
        var completedSession: TripSession?
        engine.onTripCompleted = { session in
            completedSession = session
        }

        // Start 25m trip (1500s)
        engine.startTrip(preset: .sprint25)
        
        // Fast-forward tick to completion (1500s)
        engine.tick(seconds: 1500.0)

        #expect(engine.state == .completed)
        #expect(engine.currentVelocity == 0.0)
        #expect(completedSession != nil)
        #expect(completedSession?.isCompleted == true)
        #expect(completedSession?.cruisingDuration == 1500.0)
    }

    @Test("Seat updates mutate engine properties and active trip session in real-time")
    @MainActor
    func seatUpdatesInIdleAndInFlight() {
        let engine = TransitEngine()
        
        // 1. Idle seat update
        engine.updateSeat(seatClass: .deepWork)
        #expect(engine.activeSeatCode == "1A")
        #expect(engine.activeTaskTitle == "DEEP WORK")
        #expect(engine.activeSeatIcon == "brain.head.profile")
        
        // 2. Start trip and verify session inherits active seat
        engine.startTrip(preset: .sprint25, seatCode: engine.activeSeatCode, taskTitle: engine.activeTaskTitle, seatIcon: engine.activeSeatIcon)
        #expect(engine.activeSession?.seatCode == "1A")
        #expect(engine.activeSession?.taskTitle == "DEEP WORK")
        
        // 3. In-flight seat update to Study
        engine.updateSeat(seatClass: .study)
        #expect(engine.activeSeatCode == "2B")
        #expect(engine.activeTaskTitle == "STUDY")
        #expect(engine.activeSeatIcon == "graduationcap.fill")
        #expect(engine.activeSession?.seatCode == "2B")
        #expect(engine.activeSession?.taskTitle == "STUDY")
        #expect(engine.activeSession?.seatIcon == "graduationcap.fill")
        
        // 4. Custom seat in-flight update
        engine.updateSeat(seatCode: "7X", taskTitle: "AUTH ENGINE", seatIcon: "terminal")
        #expect(engine.activeSeatCode == "7X")
        #expect(engine.activeTaskTitle == "AUTH ENGINE")
        #expect(engine.activeSeatIcon == "terminal")
        #expect(engine.activeSession?.seatCode == "7X")
        #expect(engine.activeSession?.taskTitle == "AUTH ENGINE")
    }

    @Test("Route updates mutate engine origin/destination and active trip session")
    @MainActor
    func routeUpdatesInIdleAndInFlight() {
        let engine = TransitEngine()
        
        // 1. Idle route update
        engine.updateRoute(origin: "SFO", destination: "HND")
        #expect(engine.activeOrigin == "SFO")
        #expect(engine.activeDestination == "HND")
        
        // 2. Start flight and verify session
        engine.startTrip(preset: .sprint25, origin: engine.activeOrigin, destination: engine.activeDestination)
        #expect(engine.activeSession?.originAirportCode == "SFO")
        #expect(engine.activeSession?.destinationAirportCode == "HND")
        
        // 3. In-flight route update
        engine.updateRoute(origin: "SIN", destination: "LHR")
        #expect(engine.activeOrigin == "SIN")
        #expect(engine.activeDestination == "LHR")
        #expect(engine.activeSession?.originAirportCode == "SIN")
        #expect(engine.activeSession?.destinationAirportCode == "LHR")
    }

    @Test("Target duration updates mutate activeTargetDurationMinutes and startFlight respects custom duration")
    @MainActor
    func targetDurationAndFlightDispatch() {
        let engine = TransitEngine()
        #expect(engine.activeTargetDurationMinutes == 25)

        // 1. Update target duration while idle
        engine.setTargetDurationMinutes(45)
        #expect(engine.activeTargetDurationMinutes == 45)

        // 2. Start flight via startFlight() and verify target duration is 45 minutes (2700s)
        engine.startFlight()
        #expect(engine.state == .cruising)
        #expect(engine.activeSession?.targetDuration == 2700.0)

        // 3. Update target duration while in flight
        engine.setTargetDurationMinutes(60)
        #expect(engine.activeTargetDurationMinutes == 60)
        #expect(engine.activeSession?.targetDuration == 3600.0)
    }
}
