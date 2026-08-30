import SwiftUI
import KaruCore

/// Ultra-Minimalist DeskMinder-Inspired Frosted Glass Transit Flight Card.
public struct DeskMinderTransitCard: View {
    public let state: TransitState
    public let velocity: Double
    public let activeSession: TripSession?
    public var vehicle: VehicleType = .midnightEV
    public var selectedCityRoute: CityRoutePreset = .manilaBGC
    
    // Interactive Callbacks
    public var onStart: ((TripPreset) -> Void)?
    public var onHold: (() -> Void)?
    public var onDock: (() -> Void)?
    public var onAbort: (() -> Void)?
    
    @State private var selectedPreset: TripPreset = .cityDash25
    
    public init(
        state: TransitState,
        velocity: Double,
        activeSession: TripSession?,
        vehicle: VehicleType = .midnightEV,
        selectedCityRoute: CityRoutePreset = .manilaBGC,
        onStart: ((TripPreset) -> Void)? = nil,
        onHold: (() -> Void)? = nil,
        onDock: (() -> Void)? = nil,
        onAbort: (() -> Void)? = nil
    ) {
        self.state = state
        self.velocity = velocity
        self.activeSession = activeSession
        self.vehicle = vehicle
        self.selectedCityRoute = selectedCityRoute
        self.onStart = onStart
        self.onHold = onHold
        self.onDock = onDock
        self.onAbort = onAbort
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // ── 1. Top Timestamps Row ──
            HStack {
                Text(departureTimeString)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.55))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text(arrivalTimeString)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.55))
                    
                    if state == .cruising || state == .pitStop {
                        Text("(\(remainingTimeString))")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(statusColor)
                    }
                }
            }
            
            // ── 2. Minimalist Trajectory Track ──
            VStack(spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    // Origin Code
                    Text(originCode)
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color.white)
                    
                    // Liquid Progress Line with Moving Vector Vehicle Pod
                    GeometryReader { geo in
                        let totalW = geo.size.width
                        let progress = CGFloat(activeSession?.progressFraction ?? (state == .cruising ? 0.45 : 0.0))
                        let clampedProgress = max(0.0, min(1.0, progress))
                        let podX = totalW * clampedProgress
                        
                        ZStack(alignment: .leading) {
                            // Remaining Path (Subtle translucent track)
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 3)
                            
                            // Completed Trajectory (Liquid Sunset to Emerald Gradient)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: 0xFF5C00), Color(hex: 0x22C55E)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(4, podX), height: 3)
                                .shadow(color: Color(hex: 0x22C55E).opacity(0.6), radius: 3)
                            
                            // Modern Vector Vehicle Pod (Zero Emojis)
                            HStack(spacing: 0) {
                                Image(systemName: vehicleIconName)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(Color.white)
                                    .frame(width: 22, height: 22)
                                    .background(
                                        Circle()
                                            .fill(Color(hex: 0x14161E))
                                            .shadow(color: Color.black.opacity(0.6), radius: 4)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(statusColor, lineWidth: 1.5)
                                    )
                            }
                            .offset(x: max(0, min(totalW - 22, podX - 11)))
                        }
                    }
                    .frame(height: 22)
                    
                    // Destination Code
                    Text(destinationCode)
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color.white)
                }
                
                // Live Status Pill
                HStack(spacing: 5) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 5, height: 5)
                        .shadow(color: statusColor.opacity(0.8), radius: 3)
                    
                    Text(statusText)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(statusColor)
                }
            }
            
            // ── 3. Minimalist Integrated Controls ──
            if state == .idle {
                idleControlsRow
            } else {
                activeControlsRow
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: 0x0F1015).opacity(0.92))
                .shadow(color: Color.black.opacity(0.7), radius: 16, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    // MARK: - Idle Controls: Preset Chips + Start
    private var idleControlsRow: some View {
        HStack(spacing: 6) {
            ForEach(TripPreset.allCases) { preset in
                let isSelected = selectedPreset == preset
                Button {
                    selectedPreset = preset
                } label: {
                    Text(presetShortName(preset))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(isSelected ? Color.black : Color.white.opacity(0.7))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(isSelected ? Color.white : Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            Button {
                onStart?(selectedPreset)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 8, weight: .bold))
                    Text("Start")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                }
                .foregroundStyle(Color.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color(hex: 0x22C55E))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Active Controls: Hold / Dock / Abort
    private var activeControlsRow: some View {
        HStack(spacing: 12) {
            // Hold / Resume
            Button {
                onHold?()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: state == .pitStop ? "play.fill" : "pause.fill")
                        .font(.system(size: 9))
                    Text(state == .pitStop ? "Resume" : "Hold")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Color.white.opacity(0.85))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Dock / Complete
            Button {
                onDock?()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 9))
                    Text("Dock")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(Color(hex: 0x22C55E))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color(hex: 0x22C55E).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            
            // Abort
            Button {
                onAbort?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(6)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Helpers & Data Resolvers
    
    private var vehicleIconName: String {
        switch vehicle {
        case .midnightEV: return "bolt.car.fill"
        case .classicSarao: return "bus.fill"
        case .nightRainHatchback: return "car.side.fill"
        case .shinkansenExpress: return "tram.fill"
        case .coastalBus: return "bus.doubledecker.fill"
        }
    }
    
    private var departureTimeString: String {
        guard let session = activeSession else { return "09:35 AM" }
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: session.startDate)
    }
    
    private var arrivalTimeString: String {
        guard let session = activeSession, let target = session.targetDuration else { return "10:25 AM" }
        let estArrival = session.startDate.addingTimeInterval(target)
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: estArrival)
    }
    
    private var remainingTimeString: String {
        guard let session = activeSession, let target = session.targetDuration else { return "24m left" }
        let remaining = max(0, target - session.cruisingDuration)
        let mins = Int(remaining) / 60
        return "\(mins)m left"
    }
    
    private var originCode: String {
        let parts = selectedCityRoute.rawValue.components(separatedBy: " ")
        if let first = parts.first {
            return first.count >= 3 ? String(first.prefix(3)).uppercased() : "MAN"
        }
        return "MAN"
    }
    
    private var destinationCode: String {
        let parts = selectedCityRoute.rawValue.components(separatedBy: " ")
        if parts.count >= 2, let last = parts.last {
            return last.count >= 3 ? String(last.prefix(3)).uppercased() : "BGC"
        }
        return "BGC"
    }
    
    private var statusColor: Color {
        switch state {
        case .cruising: return Color(hex: 0x22C55E)
        case .trafficStalled: return Color(hex: 0xEF4444)
        case .pitStop: return Color(hex: 0xF59E0B)
        case .idle: return Color.white.opacity(0.5)
        case .completed: return Color(hex: 0x22C55E)
        }
    }
    
    private var statusText: String {
        switch state {
        case .cruising: return "ON TIME"
        case .trafficStalled: return "GRIDLOCK"
        case .pitStop: return "PAUSED"
        case .idle: return "STANDBY"
        case .completed: return "ARRIVED"
        }
    }
    
    private func presetShortName(_ preset: TripPreset) -> String {
        switch preset {
        case .cityDash25: return "25m"
        case .expressway50: return "50m"
        case .interstate90: return "90m"
        case .openHighway: return "Open"
        }
    }
}
