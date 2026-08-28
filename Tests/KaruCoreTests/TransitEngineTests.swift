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

    @Test("Starting a trip sets cruising state and 100 km/h velocity")
    @MainActor
    func startTrip() {
        let engine = TransitEngine()
        var stateChanges: [(TransitState, TransitState)] = []
        engine.onStateChanged = { old, new in
            stateChanges.append((old, new))
        }

        engine.startTrip(preset: .cityDash25)

        #expect(engine.state == .cruising)
        #expect(engine.currentVelocity == 100.0)
        #expect(engine.activeSession != nil)
        #expect(engine.activeSession?.preset == .cityDash25)
        #expect(stateChanges.count == 1)
        #expect(stateChanges.first?.0 == .idle)
        #expect(stateChanges.first?.1 == .cruising)
    }

    @Test("Switching into distraction app stalls velocity to 0 km/h and logs incident")
    @MainActor
    func distractionSwitchAndRecovery() {
        let engine = TransitEngine()
        engine.startTrip(preset: .cityDash25)

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
        #expect(engine.currentVelocity == 100.0)
        #expect(engine.activeSession?.incidents.count == 1)
        #expect(engine.activeSession?.incidents.first?.appName == "Discord")
        #expect(engine.activeSession?.incidents.first?.duration == 5.0)
    }

    @Test("Pit stop pauses trip and preserves incident tracking")
    @MainActor
    func pitStopBehavior() {
        let engine = TransitEngine()
        engine.startTrip(preset: .cityDash25)

        engine.togglePitStop()
        #expect(engine.state == .pitStop)
        #expect(engine.currentVelocity == 0.0)

        engine.tick(seconds: 15.0)
        #expect(engine.activeSession?.pausedDuration == 15.0)

        engine.togglePitStop()
        #expect(engine.state == .cruising)
        #expect(engine.currentVelocity == 100.0)
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
        engine.startTrip(preset: .cityDash25)
        
        // Fast-forward tick to completion (1500s)
        engine.tick(seconds: 1500.0)

        #expect(engine.state == .completed)
        #expect(engine.currentVelocity == 0.0)
        #expect(completedSession != nil)
        #expect(completedSession?.isCompleted == true)
        #expect(completedSession?.cruisingDuration == 1500.0)
    }
}
