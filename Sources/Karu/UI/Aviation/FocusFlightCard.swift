import SwiftUI
import KaruCore

/// Drawer state for inline accordion expansion in FocusFlightCard.
public enum FlightCardDrawer: Equatable {
    case originPicker
    case destinationPicker
    case seatPicker
}

/// Ultra-Sleek Avionics Telemetry Flight Card — Direction A Monochrome Edition.
/// High-contrast luxury black & white flight deck interface with dynamic inline accordion expansion:
/// - Idle Height: 122px (Compact 16px equal margins on all sides)
/// - Hover/Active Height: 156px (Reveals action controls)
/// - Drawer Open Height: 348px (Inline airport and seat class drawers without window clipping)
/// - Pure Jet Black base (#08080A), Obsidian containers (#151518), and Crisp White highlights (#FFFFFF)
public struct FocusFlightCard: View {
    public var state: TransitState
    public var velocity: Double
    public var activeSession: TripSession?
    public var aircraft: AircraftType
    public var audioEngine: AudioEngine?
    public var onStart: ((FlightPreset, TimeInterval?) -> Void)?
    public var onStartFlight: ((FlightPreset, TimeInterval?, String, String, String, String, String) -> Void)?
    public var onHold: (() -> Void)?
    public var onDock: (() -> Void)?
    public var onAbort: (() -> Void)?
    public var onToggleFloatingHUD: (() -> Void)?
    public var onOpenGarage: (() -> Void)?
    public var onOpenSettings: (() -> Void)?
    public var onOpenLogbook: (() -> Void)?
    
    // Flight Route & Destination (Default YYZ ➔ HND)
    @State private var originAirport: DestinationAirport = DestinationAirport.find(code: "YYZ")
    @State private var destinationAirport: DestinationAirport = DestinationAirport.find(code: "HND")
    @State private var selectedSeat: FocusSeatClass = .code
    
    // Custom Mission / Seat
    @State private var isCustomSeatSelected: Bool = false
    @State private var customSeatCode: String = "7X"
    @State private var customTaskName: String = "AUTH ENGINE"
    @State private var customSeatIcon: String = "terminal"
    
    // User-Selected Flight Duration in Minutes
    @State private var selectedDurationMinutes: Int = 25
    @State private var isHovering: Bool = false
    @State private var showDestinationTime: Bool = true
    
    // Inline Accordion Drawer (Replacing clipping popovers)
    @State private var activeDrawer: FlightCardDrawer? = nil
    @State private var airportSearchQuery: String = ""
    
    public init(
        state: TransitState,
        velocity: Double,
        activeSession: TripSession? = nil,
        aircraft: AircraftType = .a350F,
        audioEngine: AudioEngine? = nil,
        onStart: ((FlightPreset, TimeInterval?) -> Void)? = nil,
        onStartFlight: ((FlightPreset, TimeInterval?, String, String, String, String, String) -> Void)? = nil,
        onHold: (() -> Void)? = nil,
        onDock: (() -> Void)? = nil,
        onAbort: (() -> Void)? = nil,
        onToggleFloatingHUD: (() -> Void)? = nil,
        onOpenGarage: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil,
        onOpenLogbook: (() -> Void)? = nil
    ) {
        self.state = state
        self.velocity = velocity
        self.activeSession = activeSession
        self.aircraft = aircraft
        self.audioEngine = audioEngine
        self.onStart = onStart
        self.onStartFlight = onStartFlight
        self.onHold = onHold
        self.onDock = onDock
        self.onAbort = onAbort
        self.onToggleFloatingHUD = onToggleFloatingHUD
        self.onOpenGarage = onOpenGarage
        self.onOpenSettings = onOpenSettings
        self.onOpenLogbook = onOpenLogbook
    }
    
    // MARK: - Seat & Mission Helpers
    
    public var currentSeatCode: String {
        if let session = activeSession {
            return session.seatCode
        }
        return isCustomSeatSelected ? (customSeatCode.isEmpty ? "7X" : customSeatCode.uppercased()) : selectedSeat.rawValue
    }

    public var currentTaskTitle: String {
        if let session = activeSession {
            return session.taskTitle.uppercased()
        }
        if isCustomSeatSelected {
            return customTaskName.isEmpty ? "CUSTOM" : customTaskName.uppercased()
        }
        switch selectedSeat {
        case .deepWork: return "DEEP WORK"
        case .study: return "STUDY"
        case .research: return "RESEARCH"
        case .read: return "READING"
        case .code: return "CODING"
        }
    }

    public var currentSeatIcon: String {
        if let session = activeSession {
            return session.seatIcon
        }
        return isCustomSeatSelected ? customSeatIcon : selectedSeat.iconSymbol
    }
    
    // MARK: - Telemetry Calculations
    
    private var progress: Double {
        if let session = activeSession {
            return min(1.0, max(0.0, session.progressFraction))
        }
        return state == .cruising ? 0.42 : (state == .completed ? 1.0 : 0.0)
    }
    
    private var isExpanded: Bool {
        isHovering || state != .idle || activeDrawer != nil
    }
    
    private var currentCardHeight: CGFloat {
        if activeDrawer != nil {
            return 348
        } else if isExpanded {
            return 156
        } else {
            return 122
        }
    }
    
    private var remainingTimeNegativeFormatted: String {
        if let session = activeSession, let target = session.targetDuration {
            let remaining: Double = max(0.0, target - session.cruisingDuration)
            let hours: Int = Int(remaining) / 3600
            let mins: Int = (Int(remaining) % 3600) / 60
            let secs: Int = Int(remaining) % 60
            if hours > 0 {
                return String(format: "-%dH %02dM", hours, mins)
            } else {
                return String(format: "-%02dM %02dS", mins, secs)
            }
        }
        let totalSecs: Int = selectedDurationMinutes * 60
        let hours: Int = totalSecs / 3600
        let mins: Int = (totalSecs % 3600) / 60
        if hours > 0 {
            return String(format: "-%dH %02dM", hours, mins)
        } else {
            return String(format: "-%02dM 00S", mins)
        }
    }
    
    private var departureTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, h:mm a"
        if let session = activeSession {
            return formatter.string(from: session.startDate).uppercased()
        }
        return formatter.string(from: Date()).uppercased()
    }
    
    private var arrivalTimeString: String {
        let durationSecs: TimeInterval
        if let session = activeSession, let target = session.targetDuration {
            durationSecs = max(0.0, target - session.cruisingDuration)
        } else {
            durationSecs = TimeInterval(selectedDurationMinutes * 60)
        }
        let arrivalDate = Date().addingTimeInterval(durationSecs)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, h:mm a"
        return formatter.string(from: arrivalDate).uppercased()
    }
    
    private var etaDisplayString: String {
        let durationSecs: TimeInterval
        if let session = activeSession, let target = session.targetDuration {
            durationSecs = max(0.0, target - session.cruisingDuration)
        } else {
            durationSecs = TimeInterval(selectedDurationMinutes * 60)
        }
        let etaDate = Date().addingTimeInterval(durationSecs)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "ETA \(formatter.string(from: etaDate))"
    }
    
    private var timezoneDisplayString: String {
        if showDestinationTime {
            return "\(destinationAirport.cityName) Time"
        } else {
            return "\(originAirport.cityName) Time"
        }
    }
    
    private var eventBadgeText: String {
        switch state {
        case .idle:
            return "READY IN \(selectedDurationMinutes)M"
        case .cruising:
            return "CRUISING FL380"
        case .trafficStalled:
            return "IN TURBULENCE"
        case .pitStop:
            return "GATE HOLD"
        case .completed:
            return "TOUCHDOWN"
        }
    }
    
    private var filteredAirports: [DestinationAirport] {
        if airportSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return DestinationAirport.worldwideDestinations
        }
        let query = airportSearchQuery.lowercased()
        return DestinationAirport.worldwideDestinations.filter {
            $0.code.lowercased().contains(query) ||
            $0.cityName.lowercased().contains(query) ||
            $0.countryName.lowercased().contains(query)
        }
    }
    
    // MARK: - Main Card View Body
    
    public var body: some View {
        ZStack(alignment: .top) {
            // 1. Jet Black Carbon Surface (Anti-Aliased Continuous Squircle)
            RoundedRectangle(cornerRadius: KaruTheme.radiusCard, style: .continuous)
                .fill(KaruTheme.carbonMatte)
                .overlay(
                    RoundedRectangle(cornerRadius: KaruTheme.radiusCard, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.04), lineWidth: 0.5, antialiased: true)
                )
            
            // 2. Content Stack
            VStack(spacing: 10) {
                topRouteRow
                    .frame(height: 48)
                
                bottomSliderRow
                    .frame(height: 28)
                
                if isExpanded {
                    quickActionBar
                        .frame(height: 24)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // 3. Inline Accordion Drawer (Replacing popovers)
                if let drawer = activeDrawer {
                    Divider()
                        .background(Color.white.opacity(0.08))
                        .padding(.vertical, 2)
                    
                    inlineDrawerContent(drawer)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
        }
        .frame(width: 372, height: currentCardHeight)
        .clipShape(
            RoundedRectangle(cornerRadius: KaruTheme.radiusCard, style: .continuous),
            style: FillStyle(antialiased: true)
        )
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isExpanded)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: activeDrawer)
        .onHover { hovering in
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isHovering = hovering
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var topRouteRow: some View {
        HStack(alignment: .center, spacing: 8) {
            // ── Left: Symmetrical Aligned Monochrome Route Display with Dual Selectors ──
            HStack(alignment: .center, spacing: 7) {
                // Departure / Origin Column
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        airportSearchQuery = ""
                        activeDrawer = (activeDrawer == .originPicker ? nil : .originPicker)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 1.5) {
                        DotMatrixTextView(
                            text: originAirport.code,
                            dotSize: 2.1,
                            dotSpacing: 1.0,
                            activeColor: activeDrawer == .originPicker ? Color(hex: 0xFF5C00) : .white
                        )
                        
                        Text(originAirport.cityName)
                            .font(KaruTheme.cityTitle)
                            .foregroundStyle(activeDrawer == .originPicker ? Color(hex: 0xFF5C00) : Color.white)
                            .lineLimit(1)
                        
                        Text(departureTimeString)
                            .font(KaruTheme.flightTimestamp)
                            .foregroundStyle(KaruTheme.textMuted)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(activeDrawer == .originPicker ? Color.white.opacity(0.08) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Select Departure Airport")
                
                // Route Arrow centered in Crisp White
                DotMatrixArrowView(
                    color: .white,
                    dotSize: 2.1,
                    dotSpacing: 1.0
                )
                .padding(.horizontal, 1)
                
                // Arrival / Destination Column
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        airportSearchQuery = ""
                        activeDrawer = (activeDrawer == .destinationPicker ? nil : .destinationPicker)
                    }
                } label: {
                    VStack(alignment: .leading, spacing: 1.5) {
                        DotMatrixTextView(
                            text: destinationAirport.code,
                            dotSize: 2.1,
                            dotSpacing: 1.0,
                            activeColor: activeDrawer == .destinationPicker ? Color(hex: 0xFF5C00) : .white
                        )
                        
                        Text(destinationAirport.cityName)
                            .font(KaruTheme.cityTitle)
                            .foregroundStyle(activeDrawer == .destinationPicker ? Color(hex: 0xFF5C00) : Color.white)
                            .lineLimit(1)
                        
                        Text(arrivalTimeString)
                            .font(KaruTheme.flightTimestamp)
                            .foregroundStyle(KaruTheme.textMuted)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(activeDrawer == .destinationPicker ? Color.white.opacity(0.08) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Select Destination Airport")
            }
            
            Spacer(minLength: 8)
            
            // ── Right: Compact Inset ETA Pod ──
            AvionicsInsetPodView(
                etaText: etaDisplayString,
                timezoneText: timezoneDisplayString,
                alertBadgeText: eventBadgeText,
                onToggleTimezone: {
                    showDestinationTime.toggle()
                }
            )
            .frame(width: 124)
        }
    }
    
    @ViewBuilder
    private var bottomSliderRow: some View {
        LuminousSliderTrackView(
            progress: progress,
            state: state,
            remainingText: remainingTimeNegativeFormatted,
            onDragChanged: { frac in
                if state == .idle {
                    selectedDurationMinutes = max(5, Int(frac * 90.0))
                }
            },
            onDragEnded: { frac in
                if state == .idle {
                    selectedDurationMinutes = max(5, Int(frac * 90.0))
                }
            }
        )
    }
    
    @ViewBuilder
    private var quickActionBar: some View {
        HStack(spacing: 7) {
            // Seat Selector Trigger
            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    activeDrawer = (activeDrawer == .seatPicker ? nil : .seatPicker)
                }
            } label: {
                HStack(spacing: 3.5) {
                    Image(systemName: currentSeatIcon)
                        .font(.system(size: 8, weight: .bold))
                    Text("SEAT \(currentSeatCode) · \(currentTaskTitle)")
                        .font(.system(size: 8.5, weight: .black, design: .monospaced))
                }
                .foregroundStyle(activeDrawer == .seatPicker ? Color.white : KaruTheme.textSecondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .background(
                    Capsule()
                        .fill(activeDrawer == .seatPicker ? KaruTheme.surfaceElevated : KaruTheme.recessedTray)
                        .overlay(
                            Capsule().strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5, antialiased: true)
                        )
                )
                .clipShape(Capsule(), style: FillStyle(antialiased: true))
            }
            .buttonStyle(.plain)
            .help("Choose Task / Seat Class")
            
            // Audio Mute Quick Toggle
            if let audio = audioEngine {
                Button {
                    audio.toggleMute()
                } label: {
                    Image(systemName: audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundStyle(audio.isMuted ? KaruTheme.textMuted : Color.white)
                        .padding(3.5)
                        .background(Circle().fill(KaruTheme.recessedTray))
                        .clipShape(Circle(), style: FillStyle(antialiased: true))
                }
                .buttonStyle(.plain)
                .help(audio.isMuted ? "Unmute Cabin Ambient Audio" : "Mute Cabin Ambient Audio")
            }
            
            Spacer()
            
            if state == .idle {
                Button {
                    if let onStartFlight = onStartFlight {
                        onStartFlight(
                            .sprint25,
                            TimeInterval(selectedDurationMinutes * 60),
                            originAirport.code,
                            destinationAirport.code,
                            currentSeatCode,
                            currentTaskTitle,
                            currentSeatIcon
                        )
                    } else {
                        onStart?(.sprint25, TimeInterval(selectedDurationMinutes * 60))
                    }
                } label: {
                    HStack(spacing: 3.5) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text("TAKEOFF")
                            .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                    }
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule()
                            .fill(Color.white)
                    )
                    .clipShape(Capsule(), style: FillStyle(antialiased: true))
                    .shadow(color: Color.white.opacity(0.3), radius: 2.5)
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 4.5) {
                    Button {
                        onHold?()
                    } label: {
                        Image(systemName: state == .pitStop ? "play.fill" : "pause.fill")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(Color.white)
                            .padding(4)
                            .background(Circle().fill(KaruTheme.recessedTray))
                            .clipShape(Circle(), style: FillStyle(antialiased: true))
                    }
                    .buttonStyle(.plain)
                    .help(state == .pitStop ? "Resume Cruise" : "Gate Hold")
                    
                    Button {
                        onDock?()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(Color.white)
                            .padding(4)
                            .background(Circle().fill(KaruTheme.recessedTray))
                            .clipShape(Circle(), style: FillStyle(antialiased: true))
                    }
                    .buttonStyle(.plain)
                    .help("Touchdown / Complete Flight")
                    
                    Button {
                        onAbort?()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(Color(hex: 0x71717A))
                            .padding(4)
                            .background(Circle().fill(KaruTheme.recessedTray))
                            .clipShape(Circle(), style: FillStyle(antialiased: true))
                    }
                    .buttonStyle(.plain)
                    .help("Abort Flight")
                }
            }
            
            HStack(spacing: 2.5) {
                Button {
                    onOpenLogbook?()
                } label: {
                    Image(systemName: "book.pages")
                        .font(.system(size: 8.5))
                        .foregroundStyle(KaruTheme.textMuted)
                        .padding(3)
                }
                .buttonStyle(.plain)
                .help("Pilot's Flight Logbook")

                Button {
                    onToggleFloatingHUD?()
                } label: {
                    Image(systemName: "pip")
                        .font(.system(size: 8.5))
                        .foregroundStyle(KaruTheme.textMuted)
                        .padding(3)
                }
                .buttonStyle(.plain)
                .help("Toggle Floating Flight Card")
                
                Button {
                    onOpenSettings?()
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 8.5))
                        .foregroundStyle(KaruTheme.textMuted)
                        .padding(3)
                }
                .buttonStyle(.plain)
                .help("Settings & App Rules")
            }
        }
        .padding(.top, 2)
    }
    
    // MARK: - Inline Accordion Drawer View
    
    @ViewBuilder
    private func inlineDrawerContent(_ drawer: FlightCardDrawer) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Drawer Header
            HStack {
                Text(drawerHeaderTitle(for: drawer))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.9))
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        activeDrawer = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(KaruTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
            
            switch drawer {
            case .originPicker:
                airportListView(isOrigin: true)
            case .destinationPicker:
                airportListView(isOrigin: false)
            case .seatPicker:
                seatClassListView
            }
        }
        .padding(10)
        .background(KaruTheme.recessedTray)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    
    private func drawerHeaderTitle(for drawer: FlightCardDrawer) -> String {
        switch drawer {
        case .originPicker: return "SELECT DEPARTURE AIRPORT (ORIGIN)"
        case .destinationPicker: return "SELECT ARRIVAL AIRPORT (DESTINATION)"
        case .seatPicker: return "SELECT CABIN CLASS & TASK MODE"
        }
    }
    
    // MARK: - Airport List Drawer
    
    @ViewBuilder
    private func airportListView(isOrigin: Bool) -> some View {
        VStack(spacing: 6) {
            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 9))
                    .foregroundStyle(KaruTheme.textMuted)
                
                TextField("Search airport code or city...", text: $airportSearchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white)
            }
            .padding(6)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(filteredAirports) { airport in
                        let isSelected = isOrigin ? (originAirport.code == airport.code) : (destinationAirport.code == airport.code)
                        
                        Button {
                            if isOrigin {
                                originAirport = airport
                            } else {
                                destinationAirport = airport
                            }
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                activeDrawer = nil
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(airport.countryFlag)
                                    .font(.system(size: 14))
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    HStack(spacing: 4) {
                                        Text(airport.cityName)
                                            .font(.system(size: 10.5, weight: .bold))
                                            .foregroundStyle(Color.white)
                                        Text("(\(airport.code))")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundStyle(Color.white.opacity(0.7))
                                    }
                                    Text("\(airport.countryName) · \(airport.timeZoneCode)")
                                        .font(.system(size: 8))
                                        .foregroundStyle(KaruTheme.textSecondary)
                                }
                                
                                Spacer()
                                
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color(hex: 0xFF5C00))
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(isSelected ? KaruTheme.surfaceElevated : Color.white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 120)
        }
    }
    
    // MARK: - Seat Class Drawer
    
    @ViewBuilder
    private var seatClassListView: some View {
        ScrollView {
            VStack(spacing: 4) {
                ForEach(FocusSeatClass.allCases) { seat in
                    let isSelected = !isCustomSeatSelected && selectedSeat == seat
                    
                    Button {
                        selectedSeat = seat
                        isCustomSeatSelected = false
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            activeDrawer = nil
                        }
                    } label: {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 22, height: 22)
                                Image(systemName: seat.iconSymbol)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                HStack(spacing: 4) {
                                    Text(seat.title)
                                        .font(.system(size: 10.5, weight: .bold))
                                        .foregroundStyle(Color.white)
                                    Text("[\(seat.seatCode)]")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color.white.opacity(0.7))
                                }
                                Text(seat.subtitle)
                                    .font(.system(size: 8))
                                    .foregroundStyle(KaruTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            if isSelected {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: 0xFF5C00))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(isSelected ? KaruTheme.surfaceElevated : Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                // Custom Mission & Seat Option
                VStack(spacing: 5) {
                    Button {
                        isCustomSeatSelected = true
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            activeDrawer = nil
                        }
                    } label: {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 22, height: 22)
                                Image(systemName: customSeatIcon)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                HStack(spacing: 4) {
                                    Text(customTaskName.isEmpty ? "CUSTOM MISSION" : customTaskName.uppercased())
                                        .font(.system(size: 10.5, weight: .bold))
                                        .foregroundStyle(Color.white)
                                    Text("[Seat \(customSeatCode.isEmpty ? "7X" : customSeatCode.uppercased())]")
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color.white.opacity(0.7))
                                }
                                Text("Custom Objective · User-Defined Seat Code")
                                    .font(.system(size: 8))
                                    .foregroundStyle(KaruTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            if isCustomSeatSelected {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: 0xFF5C00))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(isCustomSeatSelected ? KaruTheme.surfaceElevated : Color.white.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    // Inline Custom Task & Seat Text Fields
                    HStack(spacing: 6) {
                        HStack(spacing: 3) {
                            Text("SEAT:")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(KaruTheme.textMuted)
                            TextField("7X", text: $customSeatCode)
                                .textFieldStyle(.plain)
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.white)
                                .frame(width: 28)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(KaruTheme.recessedTray)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                        HStack(spacing: 3) {
                            Text("TASK:")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(KaruTheme.textMuted)
                            TextField("e.g. AUTH API", text: $customTaskName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.white)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(KaruTheme.recessedTray)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                        Button {
                            isCustomSeatSelected = true
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                activeDrawer = nil
                            }
                        } label: {
                            Text("SET")
                                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                .foregroundStyle(Color.black)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3.5)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .frame(maxHeight: 145)
    }
}
