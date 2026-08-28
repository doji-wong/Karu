import Foundation
import Observation

/// The central state machine and velocity telemetry engine for Karu.
@Observable
@MainActor
public final class TransitEngine {
    
    // MARK: - Published State
    public private(set) var state: TransitState = .idle
    public private(set) var currentVelocity: Double = 0.0 // km/h
    public private(set) var activeSession: TripSession?
    public private(set) var currentHabit: Habit?
    public private(set) var activeVehicle: VehicleType = .midnightEV
    
    // Active stall incident tracker
    private var activeIncident: TrafficIncident?
    
    // Internal timer for live trips
    private var timer: Timer?
    
    // Callbacks for decoupled listeners (AudioEngine, UI, Storage)
    public var onStateChanged: ((TransitState, TransitState) -> Void)?
    public var onTripCompleted: ((TripSession) -> Void)?
    public var onIncidentLogged: ((TrafficIncident) -> Void)?

    public init() {}

    // MARK: - Trip Lifecycle Controls

    /// Start a new focus journey with a given preset and optional linked habit.
    public func startTrip(
        preset: TripPreset = .cityDash25,
        habit: Habit? = nil,
        vehicle: VehicleType = .midnightEV
    ) {
        // Reset any existing session
        stopTimer()
        activeIncident = nil
        
        let session = TripSession(
            habitId: habit?.id,
            habitName: habit?.name,
            preset: preset,
            targetDuration: preset.targetDuration,
            startDate: Date()
        )
        
        self.activeSession = session
        self.currentHabit = habit
        self.activeVehicle = vehicle
        
        let oldState = self.state
        self.state = .cruising
        self.currentVelocity = 100.0
        
        onStateChanged?(oldState, .cruising)
        startTimer()
    }

    /// Pause the trip for a pit stop.
    public func togglePitStop() {
        guard activeSession != nil else { return }
        let oldState = self.state
        
        if state == .pitStop {
            // Resume to cruising (or stalled if frontmost is hazard)
            state = .cruising
            currentVelocity = 100.0
            onStateChanged?(oldState, .cruising)
        } else if state == .cruising || state == .trafficStalled {
            // Close any open incident before entering pit stop
            closeActiveIncident()
            state = .pitStop
            currentVelocity = 0.0
            onStateChanged?(oldState, .pitStop)
        }
    }

    /// Complete the current trip early or upon destination arrival.
    public func completeTrip() {
        guard var session = activeSession else { return }
        stopTimer()
        closeActiveIncident()
        
        let oldState = self.state
        state = .completed
        currentVelocity = 0.0
        
        session.endDate = Date()
        session.isCompleted = true
        self.activeSession = session
        
        // Update linked habit streak if present
        if var habit = currentHabit {
            habit.recordTripCompletion(duration: session.cruisingDuration)
            self.currentHabit = habit
        }
        
        onStateChanged?(oldState, .completed)
        onTripCompleted?(session)
    }

    /// Cancel the active trip without saving as completed.
    public func cancelTrip() {
        stopTimer()
        closeActiveIncident()
        
        let oldState = self.state
        state = .idle
        currentVelocity = 0.0
        activeSession = nil
        currentHabit = nil
        
        onStateChanged?(oldState, .idle)
    }

    // MARK: - App Category Context Switching

    /// Handle application focus changes dispatched from DistractionMonitor.
    public func handleAppCategoryChange(
        category: AppFocusCategory,
        appName: String,
        bundleIdentifier: String
    ) {
        guard activeSession != nil else { return }
        guard state != .pitStop && state != .completed && state != .idle else { return }

        let oldState = self.state

        switch category {
        case .focusWorkspace:
            if state == .trafficStalled {
                closeActiveIncident()
                state = .cruising
                currentVelocity = 100.0
                onStateChanged?(oldState, .cruising)
            }
            
        case .distractionHazard:
            if state == .cruising {
                state = .trafficStalled
                currentVelocity = 0.0
                activeIncident = TrafficIncident(
                    appName: appName,
                    bundleIdentifier: bundleIdentifier
                )
                onStateChanged?(oldState, .trafficStalled)
            }
            
        case .neutralUtility:
            // Neutral utility: do not alter cruising vs stalled state
            break
        }
    }

    // MARK: - Tick & Telemetry Calculations

    /// Advance elapsed time by a given delta (called by internal timer or test runner).
    public func tick(seconds: TimeInterval = 1.0) {
        guard var session = activeSession else { return }
        guard state != .idle && state != .completed else { return }

        switch state {
        case .cruising:
            session.cruisingDuration += seconds
            // Distance (km) = (seconds / 3600) * velocity (100km/h)
            let distanceDelta = (seconds / 3600.0) * currentVelocity
            session.distanceTraveledKm += distanceDelta
            
            // Check if destination is reached for fixed routes
            if let target = session.targetDuration, session.cruisingDuration >= target {
                self.activeSession = session
                completeTrip()
                return
            }

        case .trafficStalled:
            session.stalledDuration += seconds
            if activeIncident != nil {
                activeIncident?.duration += seconds
            }

        case .pitStop:
            session.pausedDuration += seconds

        case .idle, .completed:
            break
        }

        self.activeSession = session
    }

    // MARK: - Helper Methods

    private func closeActiveIncident() {
        if let incident = activeIncident {
            if incident.duration > 0, var session = activeSession {
                session.incidents.append(incident)
                self.activeSession = session
                onIncidentLogged?(incident)
            }
            activeIncident = nil
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick(seconds: 1.0)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
