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
/// - Drawer Open Height: 368px (Inline airport and seat class drawers)
/// - Pre-Flight Dispatch Height: 440px / 486px / 518px (Complete route clearance & destination time control)
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
    
    // MARK: - Persistence Helper
    
    private var persistenceStore: LocalStorageManager {
        storage ?? LocalStorageManager()
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
        KaruFormatters.formatNegativeRemainingTime(remainingDurationSeconds)
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

    // MARK: - State Mutation & Preferences Helpers

    private func withCardAnimation(_ action: () -> Void) {
        withAnimation(Self.cardSpring, action)
    }

    private func loadPreferences() {
        let prefs = persistenceStore.loadPreferences()
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

        var prefs = persistenceStore.loadPreferences()
        prefs.setTargetDurationMinutes(clean, for: destinationAirport.code)
        try? persistenceStore.savePreferences(prefs)
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
        .onChange(of: currentCardHeight) { _, newHeight in
            onHeightChange?(newHeight)
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
            HStack(alignment: .center, spacing: 7) {
                airportColumn(isOrigin: true)
                
                DotMatrixArrowView(
                    color: .white,
                    dotSize: 2.1,
                    dotSpacing: 1.0
                )
                .padding(.horizontal, 1)
                
                airportColumn(isOrigin: false)
            }
            
            Spacer(minLength: 8)
            
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
            HStack {
                Text(drawerHeaderTitle(for: drawer))
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.9))
                
                Spacer()
                
                Button {
                    withCardAnimation {
                        activeDrawer = nil
                        dispatchAirportTarget = nil
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
                PreFlightDispatchDeckView(
                    engine: engine,
                    audioEngine: audioEngine,
                    originAirport: originAirport,
                    destinationAirport: destinationAirport,
                    departureTimeString: departureTimeString,
                    arrivalTimeString: arrivalTimeString,
                    destinationAirportLocalTimeString: destinationAirportLocalTimeString,
                    routeDistanceNM: routeDistanceNM,
                    timezoneDeltaString: timezoneDeltaString,
                    currentSeatCode: currentSeatCode,
                    currentTaskTitle: currentTaskTitle,
                    currentSeatIcon: currentSeatIcon,
                    isCustomSeatSelected: $isCustomSeatSelected,
                    customSeatCode: $customSeatCode,
                    customTaskName: $customTaskName,
                    customSeatIcon: $customSeatIcon,
                    selectedDurationMinutes: $selectedDurationMinutes,
                    dispatchAirportTarget: $dispatchAirportTarget,
                    onSelectStandardSeat: { seat in
                        withCardAnimation {
                            selectStandardSeat(seat)
                        }
                    },
                    onSyncCustomSeat: {
                        withCardAnimation {
                            syncCustomSeat()
                        }
                    },
                    onSaveDuration: { mins in
                        saveDurationForCurrentDestination(mins)
                    },
                    onClearForTakeoff: {
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
                    },
                    onAirportSelected: { airport, isOrigin in
                        if isOrigin {
                            engine.updateRoute(origin: airport.code, destination: destinationAirport.code)
                        } else {
                            engine.updateRoute(origin: originAirport.code, destination: airport.code)
                            loadDurationForDestination(airport.code)
                        }
                        withCardAnimation {
                            dispatchAirportTarget = nil
                        }
                    }
                )

            case .originPicker:
                FlightCardAirportPickerDrawer(
                    isOrigin: true,
                    selectedAirportCode: originAirport.code,
                    maxHeight: 120
                ) { airport in
                    engine.updateRoute(origin: airport.code, destination: destinationAirport.code)
                    withCardAnimation {
                        activeDrawer = nil
                    }
                }

            case .destinationPicker:
                FlightCardAirportPickerDrawer(
                    isOrigin: false,
                    selectedAirportCode: destinationAirport.code,
                    maxHeight: 120
                ) { airport in
                    engine.updateRoute(origin: originAirport.code, destination: airport.code)
                    loadDurationForDestination(airport.code)
                    withCardAnimation {
                        activeDrawer = nil
                    }
                }

            case .seatPicker:
                FlightCardSeatPickerDrawer(
                    currentSeatCode: currentSeatCode,
                    isCustomSeatSelected: isCustomSeatSelected,
                    customSeatCode: $customSeatCode,
                    customTaskName: $customTaskName,
                    customSeatIcon: customSeatIcon,
                    onSelectStandardSeat: { seat in
                        selectStandardSeat(seat)
                        withCardAnimation {
                            activeDrawer = nil
                        }
                    },
                    onSyncCustomSeat: {
                        syncCustomSeat()
                    },
                    onDismiss: {
                        withCardAnimation {
                            activeDrawer = nil
                        }
                    }
                )
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
}
