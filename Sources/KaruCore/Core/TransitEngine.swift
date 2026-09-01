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

    // MARK: - Seat & Mission Configuration

    /// Update active seat and task mission telemetry (updates ongoing session in real-time).
    public func updateSeat(seatCode: String, taskTitle: String, seatIcon: String) {
        self.activeSeatCode = seatCode
        self.activeTaskTitle = taskTitle
        self.activeSeatIcon = seatIcon
        
        if var session = activeSession {
            session.seatCode = seatCode
            session.taskTitle = taskTitle
            session.seatIcon = seatIcon
            self.activeSession = session
        }
    }

    /// Update active seat using a standard FocusSeatClass.
    public func updateSeat(seatClass: FocusSeatClass) {
        updateSeat(
            seatCode: seatClass.rawValue,
            taskTitle: seatClass.shortTaskTitle,
            seatIcon: seatClass.iconSymbol
        )
    }

    // MARK: - Route Configuration

    /// Update active flight route (updates ongoing session in real-time).
    public func updateRoute(origin: String, destination: String) {
        self.activeOrigin = origin
        self.activeDestination = destination
        
        if var session = activeSession {
            session.originAirportCode = origin
            session.destinationAirportCode = destination
            self.activeSession = session
        }
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

    // MARK: - Widget Telemetry & Control Helpers

    /// Start standard flight with current origin, destination, seat, and aircraft.
    public func startFlight() {
        startTrip(
            preset: .sprint25,
            customDuration: nil,
            habit: currentHabit,
            aircraft: activeAircraft,
            origin: activeOrigin,
            destination: activeDestination,
            seatCode: activeSeatCode,
            taskTitle: activeTaskTitle,
            seatIcon: activeSeatIcon
        )
    }

    /// Enter gate hold / pause if in-flight.
    public func enterGateHold() {
        if state == .cruising || state == .trafficStalled {
            toggleGateHold()
        }
    }

    /// Resume from gate hold / pause.
    public func resumeFromGateHold() {
        if state == .pitStop {
            toggleGateHold()
        }
    }

    /// Generate an immutable, curated WidgetTelemetrySnapshot from active state and historical logs.
    public func generateWidgetSnapshot(
        dailyHabits: [Habit] = [],
        todayTrips: [TripSession] = []
    ) -> WidgetTelemetrySnapshot {
        let originCity = DestinationAirport.find(code: activeOrigin).cityName
        let destinationCity = DestinationAirport.find(code: activeDestination).cityName

        let completedMins = todayTrips.reduce(0) { $0 + Int($1.cruisingDuration / 60) } + Int((activeSession?.cruisingDuration ?? 0) / 60)
        let goalMins = currentHabit?.targetDailyMinutes ?? dailyHabits.first?.targetDailyMinutes ?? 300
        let distanceNM = todayTrips.reduce(0.0) { $0 + $1.distanceTraveledNM } + (activeSession?.distanceTraveledNM ?? 0.0)
        
        let totalCruising = todayTrips.reduce(0.0) { $0 + $1.cruisingDuration } + (activeSession?.cruisingDuration ?? 0.0)
        let totalStalled = todayTrips.reduce(0.0) { $0 + $1.stalledDuration } + (activeSession?.stalledDuration ?? 0.0)
        let totalDuration = totalCruising + totalStalled
        let efficiency = totalDuration > 0 ? (totalCruising / totalDuration) * 100.0 : 100.0
        let streak = currentHabit?.currentStreakDays ?? dailyHabits.first?.currentStreakDays ?? 0

        let badge: String
        switch state {
        case .cruising:
            badge = "CRUISING \(Int(currentVelocity)) KTS"
        case .trafficStalled:
            badge = "TURBULENCE STALL"
        case .pitStop:
            badge = "GATE HOLD"
        case .completed:
            badge = "TOUCHDOWN"
        case .idle:
            badge = "GATE STANDBY"
        }

        return WidgetTelemetrySnapshot(
            state: state,
            currentAirspeedKts: Int(currentVelocity),
            originIATA: activeOrigin,
            originCity: originCity,
            destinationIATA: activeDestination,
            destinationCity: destinationCity,
            statusBadgeText: badge,
            dailyCompletedMinutes: completedMins,
            dailyGoalMinutes: goalMins,
            dailyDistanceNM: distanceNM,
            dailyEfficiencyPercentage: efficiency,
            currentStreakDays: streak,
            activeAircraftName: activeAircraft.aircraftCode,
            lastUpdated: Date()
        )
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
