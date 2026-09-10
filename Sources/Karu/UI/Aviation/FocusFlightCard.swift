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

    // Standard Spring Animation Token
    private static let cardSpring = Animation.spring(response: 0.32, dampingFraction: 0.82)
    
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
            if dispatchAirportTarget != nil {
                return 440
            }
            return isCustomSeatSelected ? 518 : 486
        } else if activeDrawer != nil {
            return 368
        } else if isExpanded {
            return 156
        } else {
            return 122
        }
    }

    private var remainingDurationSeconds: TimeInterval {
        if let session = engine.activeSession, let target = session.targetDuration {
            return max(0.0, target - session.cruisingDuration)
        }
        return TimeInterval(selectedDurationMinutes * 60)
    }
    
    private var remainingTimeNegativeFormatted: String {
        let remaining = remainingDurationSeconds
        let hours = Int(remaining) / 3600
        let mins = (Int(remaining) % 3600) / 60
        let secs = Int(remaining) % 60
        if hours > 0 {
            return String(format: "-%dH %02dM", hours, mins)
        } else {
            return String(format: "-%02dM %02dS", mins, secs)
        }
    }
    
    private var departureTimeString: String {
        let date = engine.activeSession?.startDate ?? Date()
        return KaruFormatters.formatFlightTimestamp(date, timeZoneIdentifier: originAirport.timeZoneIdentifier)
    }
    
    private var arrivalTimeString: String {
        let arrivalDate = Date().addingTimeInterval(remainingDurationSeconds)
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

    private var etaDisplayString: String {
        let etaDate = Date().addingTimeInterval(remainingDurationSeconds)
        let activeAirport = showDestinationTime ? destinationAirport : originAirport
        return KaruFormatters.formatETA(etaDate, timeZoneIdentifier: activeAirport.timeZoneIdentifier)
    }
    
    private var timezoneDisplayString: String {
        showDestinationTime ? "\(destinationAirport.cityName) Time" : "\(originAirport.cityName) Time"
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
        let query = airportSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            return DestinationAirport.worldwideDestinations
        }
        return DestinationAirport.worldwideDestinations.filter {
            $0.code.lowercased().contains(query) ||
            $0.cityName.lowercased().contains(query) ||
            $0.countryName.lowercased().contains(query)
        }
    }

    // MARK: - State Mutation & Preferences Helpers

    private func withCardAnimation(_ action: () -> Void) {
        withAnimation(Self.cardSpring, action)
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

    private func handleSliderDrag(fraction: Double) {
        guard engine.state == .idle else { return }
        let mins = max(5, Int(fraction * 90.0))
        saveDurationForCurrentDestination(mins)
    }

    private func selectStandardSeat(_ seat: FocusSeatClass) {
        selectedSeat = seat
        isCustomSeatSelected = false
        engine.updateSeat(seatClass: seat)
    }

    private func syncCustomSeat(code: String? = nil, title: String? = nil) {
        if let code {
            customSeatCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        }
        if let title {
            customTaskName = title.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        }
        isCustomSeatSelected = true
        let finalCode = customSeatCode.isEmpty ? "7X" : customSeatCode
        let finalTitle = customTaskName.isEmpty ? "CUSTOM" : customTaskName
        engine.updateSeat(seatCode: finalCode, taskTitle: finalTitle, seatIcon: customSeatIcon)
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
                
                // 3. Inline Accordion Drawer
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
        .frame(width: 372, height: currentCardHeight, alignment: .top)
        .clipShape(
            RoundedRectangle(cornerRadius: KaruTheme.radiusCard, style: .continuous),
            style: FillStyle(antialiased: true)
        )
        .animation(Self.cardSpring, value: isExpanded)
        .animation(Self.cardSpring, value: activeDrawer)
        .animation(Self.cardSpring, value: dispatchAirportTarget)
        .animation(Self.cardSpring, value: isCustomSeatSelected)
        .onChange(of: activeDrawer) { _, _ in
            onHeightChange?(currentCardHeight)
        }
        .onChange(of: dispatchAirportTarget) { _, _ in
            if activeDrawer == .preFlightDispatch {
                onHeightChange?(currentCardHeight)
            }
        }
        .onChange(of: isCustomSeatSelected) { _, _ in
            if activeDrawer == .preFlightDispatch {
                onHeightChange?(currentCardHeight)
            }
        }
        .onHover { hovering in
            withCardAnimation {
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
    
    // MARK: - Subviews & Route Columns
    
    @ViewBuilder
    private var topRouteRow: some View {
        HStack(alignment: .center, spacing: 8) {
            // Symmetrical Aligned Monochrome Route Display with Dual Selectors
            HStack(alignment: .center, spacing: 7) {
                airportColumn(isOrigin: true)
                
                // Route Arrow centered in Crisp White
                DotMatrixArrowView(
                    color: .white,
                    dotSize: 2.1,
                    dotSpacing: 1.0
                )
                .padding(.horizontal, 1)
                
                airportColumn(isOrigin: false)
            }
            
            Spacer(minLength: 8)
            
            // Compact Inset ETA Pod
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
    private func airportColumn(isOrigin: Bool) -> some View {
        let airport = isOrigin ? originAirport : destinationAirport
        let timeString = isOrigin ? departureTimeString : arrivalTimeString
        let drawer: FlightCardDrawer = isOrigin ? .originPicker : .destinationPicker
        let isDrawerActive = activeDrawer == drawer
        let target: AirportPickerTarget = isOrigin ? .origin : .destination

        Button {
            withCardAnimation {
                airportSearchQuery = ""
                if engine.state == .idle {
                    dispatchAirportTarget = target
                    activeDrawer = .preFlightDispatch
                } else {
                    activeDrawer = (isDrawerActive ? nil : drawer)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 1.5) {
                DotMatrixTextView(
                    text: airport.code,
                    dotSize: 2.1,
                    dotSpacing: 1.0,
                    activeColor: isDrawerActive ? Color(hex: 0xFF5C00) : .white
                )
                
                Text(airport.cityName)
                    .font(KaruTheme.cityTitle)
                    .foregroundStyle(isDrawerActive ? Color(hex: 0xFF5C00) : Color.white)
                    .lineLimit(1)
                
                Text(timeString)
                    .font(KaruTheme.flightTimestamp)
                    .foregroundStyle(KaruTheme.textMuted)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(isDrawerActive ? Color.white.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(isOrigin ? "Select Departure Airport" : "Select Destination Airport")
    }
    
    @ViewBuilder
    private var bottomSliderRow: some View {
        LuminousSliderTrackView(
            progress: progress,
            state: engine.state,
            remainingText: remainingTimeNegativeFormatted,
            onDragChanged: { frac in
                handleSliderDrag(fraction: frac)
            },
            onDragEnded: { frac in
                handleSliderDrag(fraction: frac)
            }
        )
    }
    
    @ViewBuilder
    private var quickActionBar: some View {
        HStack(spacing: 7) {
            // Seat Selector Trigger
            Button {
                withCardAnimation {
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
                    withCardAnimation {
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
                    .background(Capsule().fill(Color.white))
                    .clipShape(Capsule(), style: FillStyle(antialiased: true))
                    .shadow(color: Color.white.opacity(0.3), radius: 2.5)
                }
                .buttonStyle(.plain)
                .help("Pre-Flight Clearance: Configure Route & Takeoff")
            } else {
                HStack(spacing: 4.5) {
                    quickCircleButton(
                        icon: engine.state == .pitStop ? "play.fill" : "pause.fill",
                        help: engine.state == .pitStop ? "Resume Cruise" : "Gate Hold"
                    ) {
                        engine.toggleGateHold()
                    }
                    
                    quickCircleButton(icon: "checkmark", help: "Touchdown / Complete Flight") {
                        engine.completeTrip()
                    }
                    
                    quickCircleButton(icon: "xmark", color: Color(hex: 0x71717A), help: "Abort Flight") {
                        engine.cancelTrip()
                    }
                }
            }
            
            HStack(spacing: 2.5) {
                if let onOpenGarage {
                    toolbarIconButton(icon: "airplane", help: "Aircraft Fleet & Audio", action: onOpenGarage)
                }

                toolbarIconButton(icon: "book.pages", help: "Pilot's Flight Logbook (Cmd + L)") {
                    onOpenLogbook?()
                }

                toolbarIconButton(icon: "square.grid.2x2", help: "Desktop Widgets Simulator (Cmd + Shift + W)") {
                    onOpenWidgetSimulator?()
                }

                toolbarIconButton(icon: "pip", help: "Toggle Floating Flight Card") {
                    onToggleFloatingHUD?()
                }
                
                toolbarIconButton(icon: "gearshape.fill", help: "Settings & App Rules") {
                    onOpenSettings?()
                }
                
                if let onClose {
                    toolbarIconButton(icon: "xmark", weight: .bold, help: "Dismiss Floating HUD", action: onClose)
                }
            }
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private func quickCircleButton(
        icon: String,
        color: Color = .white,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 8.5, weight: .bold))
                .foregroundStyle(color)
                .padding(4)
                .background(Circle().fill(KaruTheme.recessedTray))
                .clipShape(Circle(), style: FillStyle(antialiased: true))
        }
        .buttonStyle(.plain)
        .help(help)
    }

    @ViewBuilder
    private func toolbarIconButton(
        icon: String,
        weight: Font.Weight = .regular,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 8.5, weight: weight))
                .foregroundStyle(KaruTheme.textMuted)
                .padding(3)
        }
        .buttonStyle(.plain)
        .help(help)
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
                    withCardAnimation {
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
                        withCardAnimation {
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
                    corridorAirportBox(isOrigin: true)

                    // Corridor Swap Button
                    Button {
                        withCardAnimation {
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

                    corridorAirportBox(isOrigin: false)
                }

                // 2. Seat & Cabin Class Selection Strip
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("03 / SEAT & CABIN CLASS")
                            .font(.system(size: 7.5, weight: .black, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.9))

                        Spacer()

                        Text("SEAT \(currentSeatCode) · \(currentTaskTitle)")
                            .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: 0xFF5C00))
                            .lineLimit(1)
                    }

                    // Horizontal Seat Selector Strip
                    HStack(spacing: 3) {
                        ForEach(FocusSeatClass.allCases) { seat in
                            let isSelected = !isCustomSeatSelected && (currentSeatCode == seat.rawValue || selectedSeat == seat)
                            seatPill(
                                title: seat.rawValue,
                                icon: seat.iconSymbol,
                                isSelected: isSelected,
                                help: "\(seat.title) (\(seat.seatCode)) — \(seat.cabinClass)"
                            ) {
                                withCardAnimation {
                                    selectStandardSeat(seat)
                                }
                            }
                        }

                        // Custom Seat Pill
                        let isSelectedCustom = isCustomSeatSelected || (FocusSeatClass.find(code: currentSeatCode) == nil)
                        seatPill(
                            title: customSeatCode.isEmpty ? "7X" : customSeatCode.uppercased(),
                            icon: customSeatIcon,
                            isSelected: isSelectedCustom,
                            help: "Custom Seat & Mission Objective"
                        ) {
                            withCardAnimation {
                                syncCustomSeat()
                            }
                        }
                    }

                    // Expandable Custom Mission Deck
                    if isCustomSeatSelected {
                        HStack(spacing: 6) {
                            HStack(spacing: 3) {
                                Text("SEAT")
                                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                                    .foregroundStyle(KaruTheme.textMuted)
                                TextField("7X", text: $customSeatCode)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                    .foregroundStyle(Color.white)
                                    .frame(width: 28)
                                    .onChange(of: customSeatCode) { _, newCode in
                                        syncCustomSeat(code: newCode)
                                    }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                            HStack(spacing: 3) {
                                Text("MISSION")
                                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                                    .foregroundStyle(KaruTheme.textMuted)
                                TextField("Task title / objective...", text: $customTaskName)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 8.5, weight: .medium))
                                    .foregroundStyle(Color.white)
                                    .onChange(of: customTaskName) { _, newTitle in
                                        syncCustomSeat(title: newTitle)
                                    }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                        .padding(.top, 1)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .modifier(DispatchCardModifier())

                // 3. Dedicated Destination Time Control Box
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("04 / TIME CONTROL (\(destinationAirport.code) · \(destinationAirport.cityName.uppercased()))")
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
                        stepperButton(systemName: "minus", delta: -5)

                        Slider(
                            value: Binding(
                                get: { Double(selectedDurationMinutes) },
                                set: { saveDurationForCurrentDestination(Int($0)) }
                            ),
                            in: 5...120,
                            step: 5
                        )
                        .tint(Color.white)

                        stepperButton(systemName: "plus", delta: 5)

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
                .modifier(DispatchCardModifier())

                // 4. Clear For Takeoff Action
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
                    withCardAnimation {
                        activeDrawer = nil
                        dispatchAirportTarget = nil
                    }
                } label: {
                    HStack(spacing: 5.5) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 9.5, weight: .heavy))
                        Text("CLEAR FOR TAKEOFF")
                            .font(.system(size: 9.5, weight: .black, design: .monospaced))
                    }
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7.5)
                    .background(Capsule().fill(Color.white))
                    .shadow(color: Color.white.opacity(0.3), radius: 3)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func corridorAirportBox(isOrigin: Bool) -> some View {
        let airport = isOrigin ? originAirport : destinationAirport
        let timeStr = isOrigin ? departureTimeString : destinationAirportLocalTimeString
        let header = isOrigin ? "01 / DEPARTURE" : "02 / DESTINATION"
        let accentColor = isOrigin ? Color.white : Color(hex: 0xFF5C00)
        let borderColor = isOrigin ? Color.white.opacity(0.06) : Color(hex: 0xFF5C00).opacity(0.2)
        let headerColor = isOrigin ? KaruTheme.textMuted : Color(hex: 0xFF5C00).opacity(0.85)

        Button {
            withCardAnimation {
                airportSearchQuery = ""
                dispatchAirportTarget = isOrigin ? .origin : .destination
            }
        } label: {
            VStack(alignment: .leading, spacing: 1.5) {
                Text(header)
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(headerColor)

                HStack(spacing: 4) {
                    Text(airport.countryFlag)
                        .font(.system(size: 11))
                    Text(airport.code)
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundStyle(accentColor)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(isOrigin ? KaruTheme.textMuted : Color(hex: 0xFF5C00).opacity(0.6))
                }

                Text("\(airport.cityName) · \(timeStr)")
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
                    .strokeBorder(borderColor, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .help(isOrigin ? "Change Departure Airport" : "Change Arrival Destination")
    }

    @ViewBuilder
    private func seatPill(
        title: String,
        icon: String,
        isSelected: Bool,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 7.5, weight: .bold))
                Text(title)
                    .font(.system(size: 8, weight: isSelected ? .black : .bold, design: .monospaced))
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.08))
            )
            .foregroundStyle(isSelected ? Color.black : Color.white)
        }
        .buttonStyle(.plain)
        .help(help)
    }

    @ViewBuilder
    private func stepperButton(systemName: String, delta: Int) -> some View {
        Button {
            let target = min(180, max(5, selectedDurationMinutes + delta))
            saveDurationForCurrentDestination(target)
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(Color.white)
                .frame(width: 20, height: 20)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .buttonStyle(.plain)
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
                            withCardAnimation {
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
                    seatClassRow(
                        icon: seat.iconSymbol,
                        title: seat.title,
                        badge: "[\(seat.seatCode)]",
                        subtitle: seat.subtitle,
                        isSelected: isSelected
                    ) {
                        selectStandardSeat(seat)
                        withCardAnimation {
                            activeDrawer = nil
                        }
                    }
                }

                // Custom Mission & Seat Option
                VStack(spacing: 5) {
                    let isSelectedCustom = isCustomSeatSelected || (FocusSeatClass.find(code: currentSeatCode) == nil)
                    
                    seatClassRow(
                        icon: customSeatIcon,
                        title: customTaskName.isEmpty ? "CUSTOM MISSION" : customTaskName.uppercased(),
                        badge: "[Seat \(customSeatCode.isEmpty ? "7X" : customSeatCode.uppercased())]",
                        subtitle: "Custom Objective · User-Defined Seat Code",
                        isSelected: isSelectedCustom
                    ) {
                        syncCustomSeat()
                        withCardAnimation {
                            activeDrawer = nil
                        }
                    }

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
                            syncCustomSeat()
                            withCardAnimation {
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

    @ViewBuilder
    private func seatClassRow(
        icon: String,
        title: String,
        badge: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 22, height: 22)
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(title)
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundStyle(Color.white)
                        Text(badge)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    Text(subtitle)
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
}

// MARK: - Reusable Pre-Flight Dispatch Card Modifier

private struct DispatchCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(8)
            .background(KaruTheme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
            )
    }
}
