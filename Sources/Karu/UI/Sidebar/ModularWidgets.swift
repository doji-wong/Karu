import SwiftUI
import KaruCore

// MARK: - 1. Tactile Squircle Card Container
public struct TactileCardContainer<Content: View>: View {
    public let content: Content
    public var padding: CGFloat
    public var cornerRadius: CGFloat
    public var highlightBorder: Bool
    
    public init(
        padding: CGFloat = 14,
        cornerRadius: CGFloat = KaruTheme.radiusCard,
        highlightBorder: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.highlightBorder = highlightBorder
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding)
            .background(KaruTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(highlightBorder ? KaruTheme.cardBorderActive : KaruTheme.cardBorder, lineWidth: highlightBorder ? 1.5 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - 2. Aviation Route Header Widget
/// Inspired by the ABC -> XYZ Flight Departure / Arrival Telemetry Card.
public struct AviationRouteHeaderWidget: View {
    public let state: TransitState
    public let velocity: Double
    public let activeSession: TripSession?
    public var selectedCityRoute: CityRoutePreset = .manilaBGC
    
    public init(
        state: TransitState,
        velocity: Double,
        activeSession: TripSession?,
        selectedCityRoute: CityRoutePreset = .manilaBGC
    ) {
        self.state = state
        self.velocity = velocity
        self.activeSession = activeSession
        self.selectedCityRoute = selectedCityRoute
    }
    
    public var body: some View {
        TactileCardContainer(padding: 12, cornerRadius: 16) {
            VStack(spacing: 8) {
                // Top Departure / Arrival Row
                HStack {
                    Text("DEPARTURE: \(departureTimeString)")
                        .font(KaruTheme.statLabel)
                        .foregroundStyle(KaruTheme.textMuted)
                    
                    Spacer()
                    
                    Text("ARRIVAL: \(arrivalTimeString)")
                        .font(KaruTheme.statLabel)
                        .foregroundStyle(KaruTheme.textMuted)
                }
                
                // Flight Trajectory Banner: Origin -> ✈️ -> Destination
                HStack(alignment: .center, spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(originCode)
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .foregroundStyle(KaruTheme.textPrimary)
                        Text(originCity)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(KaruTheme.textMuted)
                    }
                    
                    Spacer()
                    
                    // Route Flight Line with Airplane & Pulse
                    HStack(spacing: 3) {
                        Circle()
                            .fill(KaruTheme.statusGlow(for: state))
                            .frame(width: 4, height: 4)
                        
                        Rectangle()
                            .fill(KaruTheme.statusGlow(for: state).opacity(0.8))
                            .frame(width: 28, height: 1.5)
                        
                        Image(systemName: "airplane")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(KaruTheme.statusGlow(for: state))
                            .rotationEffect(.degrees(0))
                        
                        Rectangle()
                            .fill(KaruTheme.cardBorder)
                            .frame(width: 28, height: 1.5)
                        
                        Circle()
                            .fill(KaruTheme.textMuted)
                            .frame(width: 4, height: 4)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(destinationCode)
                            .font(.system(size: 15, weight: .black, design: .monospaced))
                            .foregroundStyle(KaruTheme.textPrimary)
                        Text(destinationCity)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(KaruTheme.textMuted)
                    }
                }
                
                // Bottom Status Pill & Speed
                HStack {
                    // Status Badge (ON TIME / GRIDLOCK / STANDBY)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(KaruTheme.statusGlow(for: state))
                            .frame(width: 5, height: 5)
                        Text(statusBadgeText)
                            .font(KaruTheme.badgeText)
                            .foregroundStyle(KaruTheme.statusGlow(for: state))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(KaruTheme.surfaceElevated)
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    // Velocity readout
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(Int(velocity))")
                            .font(KaruTheme.metricMedium)
                            .foregroundStyle(KaruTheme.statusGlow(for: state))
                        Text("KM/H")
                            .font(KaruTheme.statLabel)
                            .foregroundStyle(KaruTheme.textMuted)
                    }
                }
            }
        }
    }
    
    private var departureTimeString: String {
        guard let session = activeSession else { return "09:30 AM" }
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: session.startDate)
    }
    
    private var arrivalTimeString: String {
        guard let session = activeSession, let target = session.targetDuration else { return "--:--" }
        let estArrival = session.startDate.addingTimeInterval(target)
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: estArrival)
    }
    
    private var originCode: String {
        let parts = selectedCityRoute.rawValue.components(separatedBy: " ")
        return parts.first?.prefix(3).uppercased() ?? "MNL"
    }
    
    private var originCity: String {
        let parts = selectedCityRoute.rawValue.components(separatedBy: " ")
        return parts.first ?? "Origin"
    }
    
    private var destinationCode: String {
        let parts = selectedCityRoute.rawValue.components(separatedBy: " ")
        if parts.count >= 2 {
            return parts.last?.prefix(3).uppercased() ?? "BGC"
        }
        return "DST"
    }
    
    private var destinationCity: String {
        let parts = selectedCityRoute.rawValue.components(separatedBy: " ")
        if parts.count >= 2 {
            return parts.last ?? "Destination"
        }
        return "Destination"
    }
    
    private var statusBadgeText: String {
        switch state {
        case .cruising: return "ON TIME"
        case .trafficStalled: return "GRIDLOCK"
        case .pitStop: return "REST AREA"
        case .idle: return "STANDBY"
        case .completed: return "ARRIVED"
        }
    }
}

// MARK: - 3. Turn-by-Turn Navigation & Tactile Controls Widget
/// Inspired by the "450M Manhatten Street" Navigation Card with circular buttons.
public struct TurnByTurnNavigationWidget: View {
    public let state: TransitState
    public let session: TripSession?
    public var onHold: (() -> Void)?
    public var onDock: (() -> Void)?
    public var onAbort: (() -> Void)?
    public var onLaunch: (() -> Void)?
    
    public init(
        state: TransitState,
        session: TripSession?,
        onHold: (() -> Void)? = nil,
        onDock: (() -> Void)? = nil,
        onAbort: (() -> Void)? = nil,
        onLaunch: (() -> Void)? = nil
    ) {
        self.state = state
        self.session = session
        self.onHold = onHold
        self.onDock = onDock
        self.onAbort = onAbort
        self.onLaunch = onLaunch
    }
    
    public var body: some View {
        TactileCardContainer(padding: 12, cornerRadius: 16) {
            VStack(spacing: 10) {
                // Top Milestone & Flight Action Buttons
                HStack(alignment: .center) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.turn.up.left")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(KaruTheme.solarOrange)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(milestoneDistanceText)
                                .font(KaruTheme.metricLarge)
                                .foregroundStyle(KaruTheme.textPrimary)
                            
                            Text(milestoneNameText)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(KaruTheme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    // Tactile Circular Control Buttons
                    if state == .idle {
                        Button {
                            onLaunch?()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 10, weight: .black))
                                Text("START")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(KaruTheme.solarGradient)
                            .foregroundStyle(Color.black)
                            .clipShape(Capsule())
                            .shadow(color: KaruTheme.solarOrange.opacity(0.4), radius: 6)
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 6) {
                            // Hold / Resume
                            Button {
                                onHold?()
                            } label: {
                                Image(systemName: state == .pitStop ? "play.fill" : "pause.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .frame(width: 28, height: 28)
                                    .background(KaruTheme.surfaceElevated)
                                    .foregroundStyle(state == .pitStop ? KaruTheme.telemetryAmber : KaruTheme.textPrimary)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(KaruTheme.cardBorder, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            
                            // Complete / Dock
                            Button {
                                onDock?()
                            } label: {
                                Image(systemName: "flag.checkered")
                                    .font(.system(size: 10, weight: .bold))
                                    .frame(width: 28, height: 28)
                                    .background(KaruTheme.telemetryGreen)
                                    .foregroundStyle(Color.black)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            
                            // Abort / Cancel
                            Button {
                                onAbort?()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .frame(width: 28, height: 28)
                                    .background(KaruTheme.surfaceElevated)
                                    .foregroundStyle(KaruTheme.telemetryRed)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(KaruTheme.telemetryRed.opacity(0.4), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Segmented 1px Divider
                Rectangle()
                    .fill(KaruTheme.cardBorderSubtle)
                    .frame(height: 1)
                
                // 3-Column Telemetry Row (ETA | SPEED | DISTANCE)
                HStack(spacing: 8) {
                    telemetryColumn(title: "ETA", value: etaText)
                    Divider().frame(height: 20).background(KaruTheme.cardBorder)
                    telemetryColumn(title: "SPEED", value: speedText)
                    Divider().frame(height: 20).background(KaruTheme.cardBorder)
                    telemetryColumn(title: "DISTANCE", value: distanceText)
                }
            }
        }
    }
    
    private func telemetryColumn(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 7.5, weight: .black, design: .monospaced))
                .foregroundStyle(KaruTheme.textMuted)
                .tracking(0.5)
            
            Text(value)
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundStyle(KaruTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var milestoneDistanceText: String {
        guard let s = session, let target = s.targetDuration else { return "450M" }
        let remainingSecs = max(0, target - s.cruisingDuration)
        let remainingKm = (remainingSecs / 3600.0) * 100.0
        if remainingKm >= 1.0 {
            return String(format: "%.1f KM", remainingKm)
        } else {
            return "\(Int(remainingKm * 1000))M"
        }
    }
    
    private var milestoneNameText: String {
        if state == .trafficStalled {
            let app = session?.incidents.last?.appName ?? "Distraction"
            return "GRIDLOCK AHEAD [\(app.uppercased())]"
        } else if let habit = session?.habitName {
            return habit.uppercased()
        } else {
            return "DEEP WORK EXPRESSWAY"
        }
    }
    
    private var etaText: String {
        guard let s = session, let target = s.targetDuration else { return "--:--" }
        let remaining = max(0, target - s.cruisingDuration)
        let mins = Int(remaining) / 60
        let secs = Int(remaining) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private var speedText: String {
        switch state {
        case .cruising: return "100 km/h"
        case .trafficStalled, .idle, .pitStop, .completed: return "0 km/h"
        }
    }
    
    private var distanceText: String {
        guard let s = session else { return "0.0 km" }
        return String(format: "%.1f km", s.distanceTraveledKm)
    }
}

// MARK: - 4. EV Focus & Efficiency Pod Widget
/// Inspired by the Supercar / EV Battery & Telemetry Card (72% Charge / Vehicle).
public struct EVFocusEfficiencyWidget: View {
    public let vehicle: VehicleType
    public let session: TripSession?
    public let state: TransitState
    
    public init(vehicle: VehicleType, session: TripSession?, state: TransitState) {
        self.vehicle = vehicle
        self.session = session
        self.state = state
    }
    
    public var body: some View {
        TactileCardContainer(padding: 12, cornerRadius: 16) {
            HStack(spacing: 12) {
                // Left: Lightning Bolt + Large Efficiency %
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(KaruTheme.solarOrange)
                    
                    Text("\(Int(efficiencyValue))")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(KaruTheme.textPrimary)
                    
                    Text("%")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(KaruTheme.solarOrange)
                }
                
                Spacer()
                
                // Right: Vehicle Profile & Range Metrics
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: vehicleIconName)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(KaruTheme.solarOrange)
                        
                        Text(vehicle.name.uppercased())
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundStyle(KaruTheme.textPrimary)
                    }
                    
                    HStack(spacing: 6) {
                        Text("\(Int(session?.distanceTraveledKm ?? 0)) kms")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(KaruTheme.textSecondary)
                        
                        Text("•")
                            .font(.system(size: 8))
                            .foregroundStyle(KaruTheme.textMuted)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(KaruTheme.solarOrange)
                            Text(streakText)
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(KaruTheme.solarOrange)
                        }
                    }
                }
            }
        }
    }
    
    private var efficiencyValue: Double {
        session?.cruiseEfficiency ?? 100.0
    }
    
    private var streakText: String {
        if let count = session?.incidents.count, count == 0 {
            return "CLEAN RUN"
        } else {
            return "\(session?.incidents.count ?? 0) HAZARDS"
        }
    }
    
    private var vehicleIconName: String {
        switch vehicle {
        case .midnightEV: return "bolt.car.fill"
        case .classicSarao: return "bus.fill"
        case .nightRainHatchback: return "car.side.fill"
        case .shinkansenExpress: return "tram.fill"
        case .coastalBus: return "bus.doubledecker.fill"
        }
    }
}

// MARK: - 5. Dark GPS Vector Map & Exit Badge Pod
/// Inspired by the GPS Map Widget with EXIT 5 badge.
public struct DarkGPSMiniMapWidget: View {
    @Bindable public var engine: TransitEngine
    public var selectedCityRoute: CityRoutePreset = .manilaBGC
    
    public init(engine: TransitEngine, selectedCityRoute: CityRoutePreset = .manilaBGC) {
        self.engine = engine
        self.selectedCityRoute = selectedCityRoute
    }
    
    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Live CARTO Dark Matter Real Map
            LiveRouteTrackingView(engine: engine, cityRoute: selectedCityRoute)
                .frame(height: 125)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(KaruTheme.cardBorder, lineWidth: 1)
                )
            
            // Bottom Badges Overlay: EXIT 5 / Distance
            HStack {
                // Exit Badge
                HStack(spacing: 3) {
                    Text("EXIT 5")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.black)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(KaruTheme.solarOrange)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Spacer()
                
                // Waypoint progress badge
                HStack(spacing: 3) {
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(KaruTheme.electricBlue)
                    
                    Text("\(String(format: "%.1f", engine.activeSession?.distanceTraveledKm ?? 0)) KM")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(KaruTheme.cardBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(8)
        }
    }
}

// MARK: - 6. In-Flight Scratchpad & Audio Utility Widget
public struct InFlightScratchpadWidget: View {
    @Binding public var notes: String
    public var audioEngine: AudioEngine
    public var isPinned: Binding<Bool>
    public var isRightEdge: Binding<Bool>
    
    public init(
        notes: Binding<String>,
        audioEngine: AudioEngine,
        isPinned: Binding<Bool>,
        isRightEdge: Binding<Bool>
    ) {
        self._notes = notes
        self.audioEngine = audioEngine
        self.isPinned = isPinned
        self.isRightEdge = isRightEdge
    }
    
    public var body: some View {
        TactileCardContainer(padding: 10, cornerRadius: 14) {
            VStack(spacing: 8) {
                // Scratchpad Text Area
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.system(size: 9))
                            .foregroundStyle(KaruTheme.solarOrange)
                        Text("IN-FLIGHT NOTES")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundStyle(KaruTheme.textMuted)
                        Spacer()
                    }
                    
                    TextEditor(text: $notes)
                        .font(.system(size: 10, design: .monospaced))
                        .frame(height: 48)
                        .scrollContentBackground(.hidden)
                        .background(KaruTheme.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                // Bottom Utilities Toolbar: Audio Volume + Pin Open + Edge Switcher
                HStack(spacing: 8) {
                    // Audio Mute
                    Button {
                        audioEngine.toggleMute()
                    } label: {
                        Image(systemName: audioEngine.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(audioEngine.isMuted ? KaruTheme.textMuted : KaruTheme.solarOrange)
                    }
                    .buttonStyle(.plain)
                    
                    // Volume Slider
                    Slider(
                        value: Binding(
                            get: { Double(audioEngine.masterVolume) },
                            set: { audioEngine.masterVolume = Float($0) }
                        ),
                        in: 0.0...1.0
                    )
                    .frame(width: 70)
                    
                    Spacer()
                    
                    // Pin Open Toggle
                    Button {
                        isPinned.wrappedValue.toggle()
                    } label: {
                        Image(systemName: isPinned.wrappedValue ? "pin.fill" : "pin")
                            .font(.system(size: 10))
                            .foregroundStyle(isPinned.wrappedValue ? KaruTheme.solarOrange : KaruTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                    .help("Pin Sidebar HUD Open")
                    
                    // Dock Edge Switcher (Left / Right)
                    Button {
                        isRightEdge.wrappedValue.toggle()
                    } label: {
                        Image(systemName: isRightEdge.wrappedValue ? "sidebar.right" : "sidebar.left")
                            .font(.system(size: 10))
                            .foregroundStyle(KaruTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Switch Docked Edge (Left / Right)")
                }
            }
        }
    }
}
