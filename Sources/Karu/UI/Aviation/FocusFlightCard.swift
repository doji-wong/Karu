import SwiftUI
import KaruCore

/// Drawer state for inline accordion expansion in FocusFlightCard.
public enum FlightCardDrawer: Equatable {
    case preFlightDispatch
    case originPicker
    case destinationPicker
    case seatPicker
}

/// Target airport selection mode inside Pre-Flight Dispatch.
public enum AirportPickerTarget: Equatable {
    case origin
    case destination
}

/// Ultra-Sleek Avionics Telemetry Flight Card — Direction A Monochrome Edition.
/// High-contrast luxury black & white flight deck interface with dynamic inline accordion expansion:
/// - Idle Height: 122px (Compact 16px equal margins on all sides)
/// - Hover/Active Height: 156px (Reveals action controls)
/// - Drawer Open Height: 348px (Inline airport and seat class drawers)
/// - Pre-Flight Dispatch Height: 396px (Complete route clearance & destination time control)
/// - Pure Jet Black base (#08080A), Obsidian containers (#151518), and Crisp White highlights (#FFFFFF)
public struct FocusFlightCard: View {
    @Bindable public var engine: TransitEngine
    public var audioEngine: AudioEngine?
    public var storage: LocalStorageManager?
    public var onToggleFloatingHUD: (() -> Void)?
    public var onOpenGarage: (() -> Void)?
    public var onOpenSettings: (() -> Void)?
    public var onOpenLogbook: (() -> Void)?
    public var onOpenWidgetSimulator: (() -> Void)?
    public var onClose: (() -> Void)?
    public var onHeightChange: ((CGFloat) -> Void)?
    
    // Flight Route & Destination (Directly bound to engine)
    public var originAirport: DestinationAirport {
        DestinationAirport.find(code: engine.activeOrigin)
    }
    public var destinationAirport: DestinationAirport {
        DestinationAirport.find(code: engine.activeDestination)
    }
    @State private var selectedSeat: FocusSeatClass = .code
    
    // Custom Mission / Seat
    @State private var isCustomSeatSelected: Bool = false
    @State private var customSeatCode: String = "7X"
    @State private var customTaskName: String = "AUTH ENGINE"
    @State private var customSeatIcon: String = "terminal"
    
    // User-Selected Flight Duration in Minutes & Persistent Per-Destination Memory
    @State private var selectedDurationMinutes: Int = 25
    @State private var destinationDurations: [String: Int] = KaruPreferences.defaultDestinationDurations
    @State private var isHovering: Bool = false
    @State private var showDestinationTime: Bool = true
    
    // Inline Accordion Drawer (Replacing clipping popovers)
    @State private var activeDrawer: FlightCardDrawer? = nil
    @State private var dispatchAirportTarget: AirportPickerTarget? = nil
    @State private var airportSearchQuery: String = ""
    
    public init(
        engine: TransitEngine,
        audioEngine: AudioEngine? = nil,
        storage: LocalStorageManager? = nil,
        onToggleFloatingHUD: (() -> Void)? = nil,
        onOpenGarage: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil,
        onOpenLogbook: (() -> Void)? = nil,
        onOpenWidgetSimulator: (() -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        onHeightChange: ((CGFloat) -> Void)? = nil
    ) {
        self.engine = engine
        self.audioEngine = audioEngine
        self.storage = storage
        self.onToggleFloatingHUD = onToggleFloatingHUD
        self.onOpenGarage = onOpenGarage
        self.onOpenSettings = onOpenSettings
        self.onOpenLogbook = onOpenLogbook
        self.onOpenWidgetSimulator = onOpenWidgetSimulator
        self.onClose = onClose
        self.onHeightChange = onHeightChange
    }
    
    // MARK: - Seat & Mission Helpers
    
    public var currentSeatCode: String {
        if isCustomSeatSelected {
            return customSeatCode.isEmpty ? "7X" : customSeatCode.uppercased()
        }
        let code = engine.activeSeatCode.replacingOccurrences(of: "Seat ", with: "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return code.isEmpty ? selectedSeat.rawValue : code
    }

    public var currentTaskTitle: String {
        if isCustomSeatSelected {
            return customTaskName.isEmpty ? "CUSTOM" : customTaskName.uppercased()
        }
        return engine.activeTaskTitle.isEmpty ? selectedSeat.shortTaskTitle : engine.activeTaskTitle.uppercased()
    }

    public var currentSeatIcon: String {
        if isCustomSeatSelected {
            return customSeatIcon
        }
        return engine.activeSeatIcon.isEmpty ? selectedSeat.iconSymbol : engine.activeSeatIcon
    }
    
    // MARK: - Telemetry Calculations
    
    private var progress: Double {
        if let session = engine.activeSession {
            return min(1.0, max(0.0, session.progressFraction))
        }
        return engine.state == .cruising ? 0.42 : (engine.state == .completed ? 1.0 : 0.0)
    }
    
    private var isExpanded: Bool {
        isHovering || engine.state != .idle || activeDrawer != nil
    }
    
    private var currentCardHeight: CGFloat {
        if activeDrawer == .preFlightDispatch {
            return 396
        } else if activeDrawer != nil {
            return 348
        } else if isExpanded {
            return 156
        } else {
            return 122
        }
    }
    
    private var remainingTimeNegativeFormatted: String {
        if let session = engine.activeSession, let target = session.targetDuration {
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
        let date = engine.activeSession?.startDate ?? Date()
        return KaruFormatters.formatFlightTimestamp(date, timeZoneIdentifier: originAirport.timeZoneIdentifier)
    }
    
    private var arrivalTimeString: String {
        let durationSecs: TimeInterval
        if let session = engine.activeSession, let target = session.targetDuration {
            durationSecs = max(0.0, target - session.cruisingDuration)
        } else {
            durationSecs = TimeInterval(selectedDurationMinutes * 60)
        }
        let arrivalDate = Date().addingTimeInterval(durationSecs)
        return KaruFormatters.formatFlightTimestamp(arrivalDate, timeZoneIdentifier: destinationAirport.timeZoneIdentifier)
    }

    private var destinationAirportLocalTimeString: String {
        KaruFormatters.formatFlightTimestamp(Date(), timeZoneIdentifier: destinationAirport.timeZoneIdentifier)
    }

    private var routeDistanceNM: Int {
        Int(Double(originAirport.distanceKm(to: destinationAirport)) / 1.852)
    }

    private var timezoneDeltaString: String {
        let delta = destinationAirport.utcOffsetHours - originAirport.utcOffsetHours
        if delta == 0 {
            return "Same Timezone"
        } else if delta > 0 {
            return String(format: "+%.0fH Timezone", delta)
        } else {
            return String(format: "%.0fH Timezone", delta)
        }
    }

    private func loadPreferences() {
        let store = storage ?? LocalStorageManager()
        let prefs = store.loadPreferences()
        self.destinationDurations = prefs.destinationDurations
        let target = prefs.targetDurationMinutes(for: destinationAirport.code)
        self.selectedDurationMinutes = target
        engine.setTargetDurationMinutes(target)
    }

    private func saveDurationForCurrentDestination(_ minutes: Int) {
        let clean = max(5, min(180, minutes))
        self.selectedDurationMinutes = clean
        self.destinationDurations[destinationAirport.code] = clean
        engine.setTargetDurationMinutes(clean)

        let store = storage ?? LocalStorageManager()
        var prefs = store.loadPreferences()
        prefs.setTargetDurationMinutes(clean, for: destinationAirport.code)
        try? store.savePreferences(prefs)
    }

    private func loadDurationForDestination(_ code: String) {
        let saved = destinationDurations[code.uppercased()] ?? KaruPreferences.defaultDestinationDurations[code.uppercased()] ?? 25
        self.selectedDurationMinutes = saved
        engine.setTargetDurationMinutes(saved)
    }
    
    private var etaDisplayString: String {
        let durationSecs: TimeInterval
        if let session = engine.activeSession, let target = session.targetDuration {
            durationSecs = max(0.0, target - session.cruisingDuration)
        } else {
            durationSecs = TimeInterval(selectedDurationMinutes * 60)
        }
        let etaDate = Date().addingTimeInterval(durationSecs)
        let activeAirport = showDestinationTime ? destinationAirport : originAirport
        return KaruFormatters.formatETA(etaDate, timeZoneIdentifier: activeAirport.timeZoneIdentifier)
    }
    
    private var timezoneDisplayString: String {
        if showDestinationTime {
            return "\(destinationAirport.cityName) Time"
        } else {
            return "\(originAirport.cityName) Time"
        }
    }
    
    private var eventBadgeText: String {
        switch engine.state {
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
        .onChange(of: activeDrawer) { _, newDrawer in
            let newHeight: CGFloat
            if newDrawer == .preFlightDispatch {
                newHeight = 396
            } else if newDrawer != nil {
                newHeight = 348
            } else if isExpanded {
                newHeight = 156
            } else {
                newHeight = 122
            }
            onHeightChange?(newHeight)
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isHovering = hovering
            }
        }
        .onAppear {
            loadPreferences()
            onHeightChange?(currentCardHeight)
            if let seatClass = FocusSeatClass.find(code: engine.activeSeatCode) {
                selectedSeat = seatClass
                isCustomSeatSelected = false
            } else if !engine.activeSeatCode.isEmpty {
                isCustomSeatSelected = true
                customSeatCode = engine.activeSeatCode
                customTaskName = engine.activeTaskTitle
                customSeatIcon = engine.activeSeatIcon
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
                        if engine.state == .idle {
                            dispatchAirportTarget = .origin
                            activeDrawer = .preFlightDispatch
                        } else {
                            activeDrawer = (activeDrawer == .originPicker ? nil : .originPicker)
                        }
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
                        if engine.state == .idle {
                            dispatchAirportTarget = .destination
                            activeDrawer = .preFlightDispatch
                        } else {
                            activeDrawer = (activeDrawer == .destinationPicker ? nil : .destinationPicker)
                        }
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
            state: engine.state,
            remainingText: remainingTimeNegativeFormatted,
            onDragChanged: { frac in
                if engine.state == .idle {
                    let mins = max(5, Int(frac * 90.0))
                    saveDurationForCurrentDestination(mins)
                }
            },
            onDragEnded: { frac in
                if engine.state == .idle {
                    let mins = max(5, Int(frac * 90.0))
                    saveDurationForCurrentDestination(mins)
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
            
            if engine.state == .idle {
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        dispatchAirportTarget = nil
                        airportSearchQuery = ""
                        activeDrawer = (activeDrawer == .preFlightDispatch ? nil : .preFlightDispatch)
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
                .help("Pre-Flight Clearance: Configure Route & Takeoff")
            } else {
                HStack(spacing: 4.5) {
                    Button {
                        engine.toggleGateHold()
                    } label: {
                        Image(systemName: engine.state == .pitStop ? "play.fill" : "pause.fill")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(Color.white)
                            .padding(4)
                            .background(Circle().fill(KaruTheme.recessedTray))
                            .clipShape(Circle(), style: FillStyle(antialiased: true))
                    }
                    .buttonStyle(.plain)
                    .help(engine.state == .pitStop ? "Resume Cruise" : "Gate Hold")
                    
                    Button {
                        engine.completeTrip()
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
                        engine.cancelTrip()
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
                if let onOpenGarage = onOpenGarage {
                    Button {
                        onOpenGarage()
                    } label: {
                        Image(systemName: "airplane")
                            .font(.system(size: 8.5))
                            .foregroundStyle(KaruTheme.textMuted)
                            .padding(3)
                    }
                    .buttonStyle(.plain)
                    .help("Aircraft Fleet & Audio")
                }

                Button {
                    onOpenLogbook?()
                } label: {
                    Image(systemName: "book.pages")
                        .font(.system(size: 8.5))
                        .foregroundStyle(KaruTheme.textMuted)
                        .padding(3)
                }
                .buttonStyle(.plain)
                .help("Pilot's Flight Logbook (Cmd + L)")

                Button {
                    onOpenWidgetSimulator?()
                } label: {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 8.5))
                        .foregroundStyle(KaruTheme.textMuted)
                        .padding(3)
                }
                .buttonStyle(.plain)
                .help("Desktop Widgets Simulator (Cmd + Shift + W)")

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
                
                if let onClose = onClose {
                    Button {
                        onClose()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(KaruTheme.textMuted)
                            .padding(3)
                    }
                    .buttonStyle(.plain)
                    .help("Dismiss Floating HUD")
                }
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
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.9))
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        activeDrawer = nil
                        dispatchAirportTarget = nil
                        airportSearchQuery = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(KaruTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
            
            switch drawer {
            case .preFlightDispatch:
                preFlightDispatchView
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
        case .preFlightDispatch: return "PRE-FLIGHT CLEARANCE · ROUTE & TIME"
        case .originPicker: return "SELECT DEPARTURE AIRPORT (ORIGIN)"
        case .destinationPicker: return "SELECT ARRIVAL AIRPORT (DESTINATION)"
        case .seatPicker: return "SELECT CABIN CLASS & TASK MODE"
        }
    }

    // MARK: - Pre-Flight Dispatch & Route Clearance View

    @ViewBuilder
    private var preFlightDispatchView: some View {
        if let target = dispatchAirportTarget {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            dispatchAirportTarget = nil
                            airportSearchQuery = ""
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 8, weight: .bold))
                            Text("BACK TO CLEARANCE")
                                .font(.system(size: 8.5, weight: .black, design: .monospaced))
                        }
                        .foregroundStyle(Color(hex: 0xFF5C00))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(target == .origin ? "DEPARTURE (ORIGIN)" : "ARRIVAL (DESTINATION)")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                .padding(.bottom, 2)

                airportListView(isOrigin: target == .origin)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                // 1. Dual Route Corridor Card (Departure & Destination with Swap)
                HStack(spacing: 6) {
                    // Origin Box
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            airportSearchQuery = ""
                            dispatchAirportTarget = .origin
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 1.5) {
                            Text("01 / DEPARTURE")
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundStyle(KaruTheme.textMuted)

                            HStack(spacing: 4) {
                                Text(originAirport.countryFlag)
                                    .font(.system(size: 11))
                                Text(originAirport.code)
                                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(Color.white)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(KaruTheme.textMuted)
                            }

                            Text("\(originAirport.cityName) · \(departureTimeString)")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(KaruTheme.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(KaruTheme.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Change Departure Airport")

                    // Corridor Swap Button
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            let oldOrigin = originAirport.code
                            let oldDest = destinationAirport.code
                            engine.updateRoute(origin: oldDest, destination: oldOrigin)
                            loadDurationForDestination(oldOrigin)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(KaruTheme.surfaceElevated)
                                .frame(width: 24, height: 24)
                                .overlay(Circle().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundStyle(Color.white.opacity(0.7))
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Swap Departure and Destination")

                    // Destination Box
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            airportSearchQuery = ""
                            dispatchAirportTarget = .destination
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 1.5) {
                            Text("02 / DESTINATION")
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color(hex: 0xFF5C00).opacity(0.85))

                            HStack(spacing: 4) {
                                Text(destinationAirport.countryFlag)
                                    .font(.system(size: 11))
                                Text(destinationAirport.code)
                                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(Color(hex: 0xFF5C00))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(Color(hex: 0xFF5C00).opacity(0.6))
                            }

                            Text("\(destinationAirport.cityName) · \(destinationAirportLocalTimeString)")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(KaruTheme.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(KaruTheme.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color(hex: 0xFF5C00).opacity(0.2), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Change Arrival Destination")
                }

                // 2. Dedicated Destination Time Control Box
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("03 / TIME CONTROL (\(destinationAirport.code) · \(destinationAirport.cityName.uppercased()))")
                            .font(.system(size: 7.5, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.9))

                        Spacer()

                        Text("ETA \(arrivalTimeString)")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: 0xFF5C00))
                    }

                    // Duration Preset Pills
                    HStack(spacing: 4) {
                        ForEach([15, 25, 45, 60, 90], id: \.self) { mins in
                            let isSelected = (selectedDurationMinutes == mins)
                            Button {
                                saveDurationForCurrentDestination(mins)
                            } label: {
                                Text("\(mins)M")
                                    .font(.system(size: 8.5, weight: isSelected ? .black : .bold, design: .monospaced))
                                    .foregroundStyle(isSelected ? Color.black : Color.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 3.5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                            .fill(isSelected ? Color.white : Color.white.opacity(0.08))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Precision Stepper & Slider
                    HStack(spacing: 6) {
                        Button {
                            saveDurationForCurrentDestination(max(5, selectedDurationMinutes - 5))
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(Color.white)
                                .frame(width: 20, height: 20)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Slider(
                            value: Binding(
                                get: { Double(selectedDurationMinutes) },
                                set: { saveDurationForCurrentDestination(Int($0)) }
                            ),
                            in: 5...120,
                            step: 5
                        )
                        .tint(Color.white)

                        Button {
                            saveDurationForCurrentDestination(min(180, selectedDurationMinutes + 5))
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 8, weight: .black))
                                .foregroundStyle(Color.white)
                                .frame(width: 20, height: 20)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        Text("\(selectedDurationMinutes)M")
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Color.white)
                            .frame(width: 32, alignment: .trailing)
                    }

                    // Telemetry Status Strip
                    HStack {
                        Text("\(routeDistanceNM) NM CORRIDOR")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundStyle(KaruTheme.textMuted)

                        Spacer()

                        Text("\(timezoneDeltaString) · \(destinationAirport.timeZoneCode)")
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundStyle(KaruTheme.textSecondary)
                    }
                }
                .padding(8)
                .background(KaruTheme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
                )

                // 3. Clear For Takeoff Action
                Button {
                    engine.startTrip(
                        preset: .sprint25,
                        customDuration: TimeInterval(selectedDurationMinutes * 60),
                        origin: originAirport.code,
                        destination: destinationAirport.code,
                        seatCode: currentSeatCode,
                        taskTitle: currentTaskTitle,
                        seatIcon: currentSeatIcon
                    )
                    audioEngine?.start()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        activeDrawer = nil
                        dispatchAirportTarget = nil
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 9.5, weight: .heavy))
                        Text("CLEAR FOR TAKEOFF")
                            .font(.system(size: 9.5, weight: .black, design: .monospaced))
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6.5)
                    .background(
                        Capsule()
                            .fill(Color.white)
                    )
                    .shadow(color: Color.white.opacity(0.3), radius: 3)
                }
                .buttonStyle(.plain)
            }
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
                                engine.updateRoute(origin: airport.code, destination: destinationAirport.code)
                            } else {
                                engine.updateRoute(origin: originAirport.code, destination: airport.code)
                                loadDurationForDestination(airport.code)
                            }
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                if activeDrawer == .preFlightDispatch {
                                    dispatchAirportTarget = nil
                                    airportSearchQuery = ""
                                } else {
                                    activeDrawer = nil
                                }
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
            .frame(maxHeight: (activeDrawer == .preFlightDispatch) ? 175 : 120)
        }
    }
    
    // MARK: - Seat Class Drawer
    
    @ViewBuilder
    private var seatClassListView: some View {
        ScrollView {
            VStack(spacing: 4) {
                ForEach(FocusSeatClass.allCases) { seat in
                    let isSelected = !isCustomSeatSelected && (currentSeatCode == seat.rawValue || selectedSeat == seat)
                    
                    Button {
                        selectedSeat = seat
                        isCustomSeatSelected = false
                        engine.updateSeat(seatClass: seat)
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
                    let isSelectedCustom = isCustomSeatSelected || (FocusSeatClass.find(code: currentSeatCode) == nil)
                    
                    Button {
                        isCustomSeatSelected = true
                        let code = customSeatCode.isEmpty ? "7X" : customSeatCode.uppercased()
                        let title = customTaskName.isEmpty ? "CUSTOM" : customTaskName.uppercased()
                        engine.updateSeat(seatCode: code, taskTitle: title, seatIcon: customSeatIcon)
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
                            
                            if isSelectedCustom {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color(hex: 0xFF5C00))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(isSelectedCustom ? KaruTheme.surfaceElevated : Color.white.opacity(0.03))
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
                            let code = customSeatCode.isEmpty ? "7X" : customSeatCode.uppercased()
                            let title = customTaskName.isEmpty ? "CUSTOM" : customTaskName.uppercased()
                            engine.updateSeat(seatCode: code, taskTitle: title, seatIcon: customSeatIcon)
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
