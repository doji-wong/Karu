import SwiftUI
import KaruCore

/// Edge-Docked Aviation Cockpit HUD with Hover & Tap Dropdown Deck.
public struct SidebarHUDView: View {
    @Bindable public var engine: TransitEngine
    @Bindable public var scratchpadStore: ScratchpadStore
    public var audioEngine: AudioEngine
    public var storage: LocalStorageManager
    public var onOpenGarage: (() -> Void)?
    public var onOpenSettings: (() -> Void)?
    public var onEdgePositionChanged: ((Bool) -> Void)?
    
    @State private var isHovering: Bool = false
    @State private var isExpanded: Bool = false
    @State private var isPinned: Bool = false
    @State private var isRightEdge: Bool = true
    @State private var selectedPreset: TripPreset = .cityDash25
    @State private var selectedCityRoute: CityRoutePreset = .manilaBGC
    
    public init(
        engine: TransitEngine,
        scratchpadStore: ScratchpadStore,
        audioEngine: AudioEngine,
        storage: LocalStorageManager,
        onOpenGarage: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil,
        onEdgePositionChanged: ((Bool) -> Void)? = nil
    ) {
        self.engine = engine
        self.scratchpadStore = scratchpadStore
        self.audioEngine = audioEngine
        self.storage = storage
        self.onOpenGarage = onOpenGarage
        self.onOpenSettings = onOpenSettings
        self.onEdgePositionChanged = onEdgePositionChanged
    }
    
    public var body: some View {
        ZStack(alignment: isRightEdge ? .trailing : .leading) {
            if isExpanded || isPinned {
                expandedCockpitDeck
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95, anchor: isRightEdge ? .trailing : .leading).combined(with: .opacity),
                        removal: .scale(scale: 0.95, anchor: isRightEdge ? .trailing : .leading).combined(with: .opacity)
                    ))
            } else {
                collapsedAviationPill
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded || isPinned)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                isHovering = hovering
                if !isPinned {
                    if hovering {
                        isExpanded = true
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            if !isHovering && !isPinned {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isExpanded = false
                                }
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: isRightEdge) { _, newEdge in
            onEdgePositionChanged?(newEdge)
        }
    }
    
    // MARK: - 1. Collapsed Resting Pill (Aviation Telemetry Capsule)
    private var collapsedAviationPill: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 7) {
                // Gold Airline / Emblem Dot
                ZStack {
                    Circle()
                        .fill(Color(hex: 0xEAB308))
                        .frame(width: 14, height: 14)
                    Image(systemName: "airplane")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Color.black)
                }
                
                // Flight Status Text
                Text(flightBadgeString)
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundStyle(statusColor)
                
                // Retro Green LCD Speed Mini-Badge
                HStack(spacing: 2) {
                    Text("\(Int(lcdSpeedValue))")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(hex: 0x1C2F15))
                    Text("MPH")
                        .font(.system(size: 6, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: 0x1C2F15).opacity(0.8))
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(colors: [Color(hex: 0xBDDDA8), Color(hex: 0xA3CD8C)], startPoint: .top, endPoint: .bottom))
                )
                
                // ETA
                if let session = engine.activeSession, let target = session.targetDuration {
                    let remaining = max(0, target - session.cruisingDuration)
                    let mins = Int(remaining) / 60
                    Text("📍 \(mins)m")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                
                // Chevron
                Image(systemName: isRightEdge ? "chevron.left" : "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(hex: 0x0C0D10).opacity(0.95))
                    .shadow(color: Color.black.opacity(0.6), radius: 10, x: 0, y: 3)
            )
            .overlay(
                Capsule()
                    .stroke(isHovering ? Color(hex: 0x22C55E).opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 2. Expanded Aviation Cockpit Deck
    private var expandedCockpitDeck: some View {
        VStack(spacing: 8) {
            // Top Bar: Title + Route Selector + Collapse Handle
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: 0xEAB308))
                    Text("KARU FLIGHT COCKPIT")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color.white)
                        .tracking(0.8)
                }
                
                Spacer()
                
                // Route Selector Menu
                Menu {
                    ForEach(CityRoutePreset.allCases) { route in
                        Button(route.rawValue) {
                            selectedCityRoute = route
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 8))
                        Text(selectedCityRoute.rawValue.components(separatedBy: " ").prefix(2).joined(separator: " "))
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.1))
                    .foregroundStyle(Color(hex: 0x22C55E))
                    .clipShape(Capsule())
                }
                .menuStyle(.borderlessButton)
                
                // Collapse Button
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isPinned = false
                        isExpanded = false
                    }
                } label: {
                    Image(systemName: "chevron.right.2")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .padding(4)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)
            
            // ── Card 1: Long Flight Telemetry Card ──
            AviationFlightCard(
                state: engine.state,
                velocity: engine.currentVelocity,
                activeSession: engine.activeSession,
                vehicle: engine.activeVehicle,
                selectedCityRoute: selectedCityRoute
            )
            
            // ── Card 2: Cockpit Altimeter / Speedometer Dial Card ──
            CockpitDialCard(
                state: engine.state,
                velocity: engine.currentVelocity,
                session: engine.activeSession,
                vehicle: engine.activeVehicle
            )
            
            // ── Card 3: Turn-by-Turn Navigation Controls & Telemetry ──
            TurnByTurnNavigationWidget(
                state: engine.state,
                session: engine.activeSession,
                onHold: { engine.togglePitStop() },
                onDock: { engine.completeTrip() },
                onAbort: { engine.cancelTrip() },
                onLaunch: {
                    engine.startTrip(preset: selectedPreset)
                    audioEngine.start()
                }
            )
            
            // Idle Preset Selector
            if engine.state == .idle {
                presetSelectorGrid
            }
            
            // ── Card 4: In-Flight Scratchpad & Audio Utility Bar ──
            InFlightScratchpadWidget(
                notes: $scratchpadStore.notes,
                audioEngine: audioEngine,
                isPinned: $isPinned,
                isRightEdge: $isRightEdge
            )
        }
        .padding(10)
        .frame(width: 330)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: 0x07080A).opacity(0.97))
                .shadow(color: Color.black.opacity(0.8), radius: 18, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    // MARK: - Preset Selector Grid
    private var presetSelectorGrid: some View {
        HStack(spacing: 5) {
            ForEach(TripPreset.allCases) { preset in
                let isSelected = selectedPreset == preset
                Button {
                    selectedPreset = preset
                } label: {
                    VStack(spacing: 2) {
                        Text(presetShortName(preset))
                            .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                            .foregroundStyle(isSelected ? Color.black : Color.white)
                        
                        Text(presetDurationText(preset))
                            .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(isSelected ? Color.black.opacity(0.8) : Color(hex: 0x22C55E))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(isSelected ? Color(hex: 0x22C55E) : Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var flightBadgeString: String {
        switch engine.state {
        case .cruising: return "ON TIME"
        case .trafficStalled: return "GRIDLOCK"
        case .pitStop: return "PIT STOP"
        case .idle: return "STANDBY"
        case .completed: return "ARRIVED"
        }
    }
    
    private var statusColor: Color {
        switch engine.state {
        case .cruising: return Color(hex: 0x22C55E)
        case .trafficStalled: return Color(hex: 0xEF4444)
        case .pitStop: return Color(hex: 0xF59E0B)
        case .idle: return Color.white.opacity(0.6)
        case .completed: return Color(hex: 0x22C55E)
        }
    }
    
    private var lcdSpeedValue: Double {
        if engine.state == .cruising {
            return 859.0
        } else if engine.state == .trafficStalled {
            return 0.0
        } else {
            return 859.0
        }
    }
    
    private func presetShortName(_ preset: TripPreset) -> String {
        switch preset {
        case .cityDash25: return "CITY"
        case .expressway50: return "EXPR"
        case .interstate90: return "INTR"
        case .openHighway: return "OPEN"
        }
    }
    
    private func presetDurationText(_ preset: TripPreset) -> String {
        switch preset {
        case .cityDash25: return "25m"
        case .expressway50: return "50m"
        case .interstate90: return "90m"
        case .openHighway: return "∞"
        }
    }
}
