import Foundation
import Observation

/// The central state machine and velocity telemetry engine for Karu Focus Flights.
@Observable
@MainActor
public final class TransitEngine {
    
    // MARK: - Published State
    public private(set) var state: TransitState = .idle
    public private(set) var currentVelocity: Double = 0.0 // kts (Knots / Ground Speed)
    public private(set) var activeSession: TripSession?
    public private(set) var currentHabit: Habit?
    public private(set) var activeAircraft: AircraftType = .a350F
    public private(set) var activeOrigin: String = "YYZ"
    public private(set) var activeDestination: String = "HND"
    public private(set) var activeSeatCode: String = "5F"
    public private(set) var activeTaskTitle: String = "CODING"
    public private(set) var activeSeatIcon: String = "curlybraces"
    
    public var activeVehicle: AircraftType {
        get { activeAircraft }
        set { activeAircraft = newValue }
    }
    
    // Active turbulence encounter tracker
    private var activeTurbulence: TurbulenceEncounter?
    
    // Internal timer for live flights
    private var timer: Timer?
    
    // Callbacks for decoupled listeners (AudioEngine, UI, Storage)
    public var onStateChanged: ((TransitState, TransitState) -> Void)?
    public var onTripCompleted: ((TripSession) -> Void)?
    public var onIncidentLogged: ((TurbulenceEncounter) -> Void)?

    public init() {}

    // MARK: - Flight Lifecycle Controls

    /// Start a new focus flight with a given preset or custom duration and optional linked habit.
    public func startTrip(
        preset: FlightPreset = .sprint25,
        customDuration: TimeInterval? = nil,
        habit: Habit? = nil,
        aircraft: AircraftType = .a350F,
        origin: String = "YYZ",
        destination: String = "HND",
        seatCode: String = "5F",
        taskTitle: String = "CODING",
        seatIcon: String = "curlybraces"
    ) {
        // Reset any existing session
        stopTimer()
        activeTurbulence = nil
        
        let target = customDuration ?? preset.targetDuration
        let session = TripSession(
            habitId: habit?.id,
            habitName: habit?.name,
            preset: preset,
            targetDuration: target,
            startDate: Date(),
            originAirportCode: origin,
            destinationAirportCode: destination,
            seatCode: seatCode,
            taskTitle: taskTitle,
            seatIcon: seatIcon
        )
        
        self.activeSession = session
        self.currentHabit = habit
        self.activeAircraft = aircraft
        self.activeOrigin = origin
        self.activeDestination = destination
        self.activeSeatCode = seatCode
        self.activeTaskTitle = taskTitle
        self.activeSeatIcon = seatIcon
        
        let oldState = self.state
        self.state = .cruising
        self.currentVelocity = 540.0 // 540 kts standard cruise
        
        onStateChanged?(oldState, .cruising)
        startTimer()
    }
    
    public func startTrip(
        preset: FlightPreset = .sprint25,
        customDuration: TimeInterval? = nil,
        habit: Habit? = nil,
        vehicle: AircraftType
    ) {
        startTrip(preset: preset, customDuration: customDuration, habit: habit, aircraft: vehicle)
    }

    /// Pause the flight for a gate hold / coffee break.
    public func toggleGateHold() {
        guard activeSession != nil else { return }
        let oldState = self.state
        
        if state == .pitStop {
            // Resume to cruising
            state = .cruising
            currentVelocity = 540.0
            onStateChanged?(oldState, .cruising)
        } else if state == .cruising || state == .trafficStalled {
            // Close any open turbulence encounter before entering gate hold
            closeActiveTurbulence()
            state = .pitStop
            currentVelocity = 0.0
            onStateChanged?(oldState, .pitStop)
        }
    }
    
    public func togglePitStop() {
        toggleGateHold()
    }

    /// Complete the current flight (touchdown) early or upon reaching destination.
    public func completeTrip() {
        guard var session = activeSession else { return }
        stopTimer()
        closeActiveTurbulence()
        
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

    /// Abort the active flight without saving as completed.
    public func cancelTrip() {
        stopTimer()
        closeActiveTurbulence()
        
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
                closeActiveTurbulence()
                state = .cruising
                currentVelocity = 540.0
                onStateChanged?(oldState, .cruising)
            }
            
        case .distractionHazard:
            if state == .cruising {
                state = .trafficStalled
                currentVelocity = 0.0
                activeTurbulence = TurbulenceEncounter(
                    appName: appName,
                    bundleIdentifier: bundleIdentifier
                )
                onStateChanged?(oldState, .trafficStalled)
            }
            
        case .neutralUtility:
            // Neutral utility: do not alter cruising vs turbulence state
            break
        }
    }

    // MARK: - Tick & Telemetry Calculations

    /// Advance elapsed flight time by a given delta (called by internal timer or test runner).
    public func tick(seconds: TimeInterval = 1.0) {
        guard var session = activeSession else { return }
        guard state != .idle && state != .completed else { return }

        switch state {
        case .cruising:
            session.cruisingDuration += seconds
            // Nautical Miles = (seconds / 3600) * velocity (540 kts)
            let distanceDelta = (seconds / 3600.0) * currentVelocity
            session.distanceTraveledNM += distanceDelta
            
            // Check if destination is reached for fixed duration flights
            if let target = session.targetDuration, session.cruisingDuration >= target {
                self.activeSession = session
                completeTrip()
                return
            }

        case .trafficStalled:
            session.stalledDuration += seconds
            if activeTurbulence != nil {
                activeTurbulence?.duration += seconds
            }

        case .pitStop:
            session.pausedDuration += seconds

        case .idle, .completed:
            break
        }

        self.activeSession = session
    }

    // MARK: - Helper Methods

    private func closeActiveTurbulence() {
        if let encounter = activeTurbulence {
            if encounter.duration > 0, var session = activeSession {
                session.turbulenceLogs.append(encounter)
                self.activeSession = session
                onIncidentLogged?(encounter)
            }
            activeTurbulence = nil
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
