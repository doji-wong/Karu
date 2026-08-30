import SwiftUI
import KaruCore

/// Ultra-Sleek Avionics Telemetry Flight Card — Direction A Monochrome Edition.
/// High-contrast luxury black & white flight deck interface with dynamic hover expansion:
/// - Idle Height: 122px (Compact 16px equal margins on all sides)
/// - Hover/Active Height: 156px (Spring expands bottom border to reveal actions without crowding)
/// - Pure Jet Black base (#08080A), Obsidian containers (#151518), and Crisp White highlights (#FFFFFF)
public struct FocusFlightCard: View {
    public var state: TransitState
    public var velocity: Double
    public var activeSession: TripSession?
    public var vehicle: VehicleType
    public var audioEngine: AudioEngine?
    public var scratchpadStore: ScratchpadStore?
    public var onStart: ((TripPreset, TimeInterval?) -> Void)?
    public var onHold: (() -> Void)?
    public var onDock: (() -> Void)?
    public var onAbort: (() -> Void)?
    public var onToggleFloatingHUD: (() -> Void)?
    public var onOpenGarage: (() -> Void)?
    public var onOpenSettings: (() -> Void)?
    
    // Flight Route & Destination (Default YYZ ➔ HND)
    @State private var originAirport: DestinationAirport = DestinationAirport.find(code: "YYZ")
    @State private var destinationAirport: DestinationAirport = DestinationAirport.find(code: "HND")
    @State private var selectedSeat: FocusSeatClass = .code
    
    // User-Selected Flight Duration in Minutes
    @State private var selectedDurationMinutes: Int = 25
    @State private var isHovering: Bool = false
    @State private var showDestinationTime: Bool = true
    
    // Interactive Sheets / Modals
    @State private var isShowingDestinationPicker: Bool = false
    @State private var isShowingSeatPicker: Bool = false
    
    public init(
        state: TransitState,
        velocity: Double,
        activeSession: TripSession? = nil,
        vehicle: VehicleType = .classicSarao,
        audioEngine: AudioEngine? = nil,
        scratchpadStore: ScratchpadStore? = nil,
        onStart: ((TripPreset, TimeInterval?) -> Void)? = nil,
        onHold: (() -> Void)? = nil,
        onDock: (() -> Void)? = nil,
        onAbort: (() -> Void)? = nil,
        onToggleFloatingHUD: (() -> Void)? = nil,
        onOpenGarage: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil
    ) {
        self.state = state
        self.velocity = velocity
        self.activeSession = activeSession
        self.vehicle = vehicle
        self.audioEngine = audioEngine
        self.scratchpadStore = scratchpadStore
        self.onStart = onStart
        self.onHold = onHold
        self.onDock = onDock
        self.onAbort = onAbort
        self.onToggleFloatingHUD = onToggleFloatingHUD
        self.onOpenGarage = onOpenGarage
        self.onOpenSettings = onOpenSettings
    }
    
    // MARK: - Telemetry Calculations
    
    private var progress: Double {
        if let session = activeSession {
            return min(1.0, max(0.0, session.progressFraction))
        }
        return state == .cruising ? 0.42 : (state == .completed ? 1.0 : 0.0)
    }
    
    private var isExpanded: Bool {
        isHovering || state != .idle
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
            return "DINNER IN 2:34H"
        case .trafficStalled:
            return "TURBULENCE"
        case .pitStop:
            return "GATE HOLD"
        case .completed:
            return "TOUCHDOWN"
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
            }
            .padding(16)
        }
        .frame(width: 372, height: isExpanded ? 156 : 122)
        .clipShape(
            RoundedRectangle(cornerRadius: KaruTheme.radiusCard, style: .continuous),
            style: FillStyle(antialiased: true)
        )
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isExpanded)
        .onHover { hovering in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                isHovering = hovering
            }
        }
        .popover(isPresented: $isShowingDestinationPicker) {
            destinationPickerView
        }
        .popover(isPresented: $isShowingSeatPicker) {
            seatPickerView
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var topRouteRow: some View {
        HStack(alignment: .center, spacing: 8) {
            // ── Left: Symmetrical Aligned Monochrome Route Display ──
            Button {
                isShowingDestinationPicker = true
            } label: {
                HStack(alignment: .center, spacing: 7) {
                    // Origin Column: Code -> City -> Time
                    VStack(alignment: .leading, spacing: 1.5) {
                        DotMatrixTextView(
                            text: originAirport.code,
                            dotSize: 2.1,
                            dotSpacing: 1.0,
                            activeColor: .white
                        )
                        
                        Text(originAirport.cityName)
                            .font(KaruTheme.cityTitle)
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                        
                        Text(departureTimeString)
                            .font(KaruTheme.flightTimestamp)
                            .foregroundStyle(KaruTheme.textMuted)
                            .lineLimit(1)
                    }
                    
                    // Route Arrow perfectly vertically centered in Crisp White
                    DotMatrixArrowView(
                        color: .white,
                        dotSize: 2.1,
                        dotSpacing: 1.0
                    )
                    .padding(.horizontal, 1)
                    
                    // Destination Column: Code -> City -> Time
                    VStack(alignment: .leading, spacing: 1.5) {
                        DotMatrixTextView(
                            text: destinationAirport.code,
                            dotSize: 2.1,
                            dotSpacing: 1.0,
                            activeColor: .white
                        )
                        
                        Text(destinationAirport.cityName)
                            .font(KaruTheme.cityTitle)
                            .foregroundStyle(Color.white)
                            .lineLimit(1)
                        
                        Text(arrivalTimeString)
                            .font(KaruTheme.flightTimestamp)
                            .foregroundStyle(KaruTheme.textMuted)
                            .lineLimit(1)
                    }
                }
            }
            .buttonStyle(.plain)
            .help("Click to change flight route & destinations")
            
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
            Button {
                isShowingSeatPicker = true
            } label: {
                HStack(spacing: 3.5) {
                    Image(systemName: selectedSeat.iconSymbol)
                        .font(.system(size: 8, weight: .bold))
                    Text("SEAT \(selectedSeat.seatCode)")
                        .font(.system(size: 8.5, weight: .black, design: .monospaced))
                }
                .foregroundStyle(KaruTheme.textSecondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .background(
                    Capsule()
                        .fill(KaruTheme.recessedTray)
                        .overlay(
                            Capsule().strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5, antialiased: true)
                        )
                )
                .clipShape(Capsule(), style: FillStyle(antialiased: true))
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            if state == .idle {
                Button {
                    onStart?(.cityDash25, TimeInterval(selectedDurationMinutes * 60))
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
                    .help(state == .pitStop ? "Resume Cruise" : "Hold Flight")
                    
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
                    onToggleFloatingHUD?()
                } label: {
                    Image(systemName: "pip")
                        .font(.system(size: 8.5))
                        .foregroundStyle(KaruTheme.textMuted)
                        .padding(3)
                }
                .buttonStyle(.plain)
                .help("Toggle Floating HUD")
                
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
    
    // MARK: - Destination Selection Popover
    
    private var destinationPickerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Select Route & Destination")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white)
                Spacer()
                Button {
                    isShowingDestinationPicker = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(KaruTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            ScrollView {
                VStack(spacing: 5) {
                    ForEach(DestinationAirport.worldwideDestinations) { airport in
                        Button {
                            destinationAirport = airport
                            isShowingDestinationPicker = false
                        } label: {
                            HStack(spacing: 8) {
                                Text(airport.countryFlag)
                                    .font(.system(size: 16))
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    HStack {
                                        Text(airport.cityName)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(Color.white)
                                        Text("(\(airport.code))")
                                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                            .foregroundStyle(Color.white)
                                    }
                                    Text("\(airport.countryName) · \(airport.timeZoneCode)")
                                        .font(.system(size: 8.5))
                                        .foregroundStyle(KaruTheme.textSecondary)
                                }
                                
                                Spacer()
                                
                                if destinationAirport.code == airport.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.white)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(destinationAirport.code == airport.code ? KaruTheme.surfaceElevated : KaruTheme.recessedTray)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous), style: FillStyle(antialiased: true))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 220)
        }
        .padding(12)
        .frame(width: 280)
        .background(KaruTheme.surface)
    }
    
    // MARK: - Seat Selection Popover
    
    private var seatPickerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Select Focus Seat & Cabin")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.white)
                Spacer()
                Button {
                    isShowingSeatPicker = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(KaruTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
            
            Divider().background(Color.white.opacity(0.1))
            
            VStack(spacing: 6) {
                ForEach(FocusSeatClass.allCases) { seat in
                    Button {
                        selectedSeat = seat
                        isShowingSeatPicker = false
                    } label: {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 24, height: 24)
                                Image(systemName: seat.iconSymbol)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 1) {
                                HStack {
                                    Text(seat.title)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.white)
                                    Text("[\(seat.seatCode)]")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color.white)
                                }
                                Text(seat.subtitle)
                                    .font(.system(size: 8.5))
                                    .foregroundStyle(KaruTheme.textSecondary)
                            }
                            
                            Spacer()
                            
                            if selectedSeat == seat {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.white)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(selectedSeat == seat ? KaruTheme.surfaceElevated : KaruTheme.recessedTray)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous), style: FillStyle(antialiased: true))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .frame(width: 280)
        .background(KaruTheme.surface)
    }
}
