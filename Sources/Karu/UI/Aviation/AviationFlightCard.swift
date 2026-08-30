import SwiftUI
import KaruCore

/// Authentic Aviation & Transit Route Card with vehicle-specific progress tracking.
public struct AviationFlightCard: View {
    public let state: TransitState
    public let velocity: Double
    public let activeSession: TripSession?
    public var vehicle: VehicleType = .midnightEV
    public var selectedCityRoute: CityRoutePreset = .manilaBGC
    
    public init(
        state: TransitState,
        velocity: Double,
        activeSession: TripSession?,
        vehicle: VehicleType = .midnightEV,
        selectedCityRoute: CityRoutePreset = .manilaBGC
    ) {
        self.state = state
        self.velocity = velocity
        self.activeSession = activeSession
        self.vehicle = vehicle
        self.selectedCityRoute = selectedCityRoute
    }
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Background Card
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: 0x0C0D10))
            
            // Atmospheric Crimson Horizon Glow
            RadialGradient(
                colors: [Color(hex: 0x7F1D1D).opacity(0.65), Color(hex: 0x3F0C0C).opacity(0.2), Color.clear],
                center: UnitPoint(x: 0.5, y: 1.15),
                startRadius: 10,
                endRadius: 110
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            // Dotted Spherical Wireframe Globe
            DottedGlobeMeshView()
                .frame(height: 55)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            
            // Content
            VStack(spacing: 0) {
                // Top Departure & Arrival Row
                HStack {
                    Text("DEPARTURE: \(departureTimeString)")
                        .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.45))
                    
                    Spacer()
                    
                    Text("ARRIVAL: \(arrivalTimeString)")
                        .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)
                
                Spacer().frame(height: 6)
                
                // Trajectory Banner: Origin -> Vehicle Progress -> Destination
                HStack(alignment: .center) {
                    // Origin Station
                    VStack(alignment: .leading, spacing: 1) {
                        Text(originCode)
                            .font(.system(size: 19, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white)
                        Text(originCity)
                            .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    // Dynamic Vehicle Route Progress Bar
                    VStack(spacing: 3) {
                        GeometryReader { geo in
                            let totalWidth = geo.size.width
                            let progress = CGFloat(activeSession?.progressFraction ?? (state == .cruising ? 0.45 : 0.0))
                            let iconPosition = max(10, min(totalWidth - 10, totalWidth * progress))
                            
                            ZStack(alignment: .leading) {
                                // Remaining Trajectory (Dashed)
                                DashedLineView()
                                    .frame(width: totalWidth, height: 2)
                                
                                // Completed Trajectory (Solid Glowing Line)
                                Rectangle()
                                    .fill(routeColor)
                                    .frame(width: iconPosition, height: 2)
                                    .shadow(color: routeColor.opacity(0.8), radius: 3)
                                
                                // Active Selected Vehicle Avatar (Moves along route!)
                                HStack(spacing: 0) {
                                    Image(systemName: vehicleIconName)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.white)
                                        .padding(3)
                                        .background(routeColor)
                                        .clipShape(Circle())
                                        .shadow(color: routeColor.opacity(0.9), radius: 4)
                                }
                                .offset(x: iconPosition - 8, y: -7)
                            }
                        }
                        .frame(width: 120, height: 16)
                        
                        // Status Badge (ON TIME / MISSION HOLD / GRIDLOCK)
                        Text(statusBadgeText)
                            .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                            .foregroundStyle(routeColor)
                            .shadow(color: routeColor.opacity(0.6), radius: 3)
                    }
                    .frame(width: 130)
                    
                    Spacer()
                    
                    // Destination Station
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(destinationCode)
                            .font(.system(size: 19, weight: .black, design: .rounded))
                            .foregroundStyle(Color.white)
                        Text(destinationCity)
                            .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Bottom Badges: Vehicle Tag & Gold Insignia
                HStack {
                    // Vehicle Tag (e.g. EV-01 / SARAO / A350F)
                    Text(vehicleTag)
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.8))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    Spacer()
                    
                    // Golden Vehicle Insignia Emblem
                    ZStack {
                        Circle()
                            .fill(Color(hex: 0xEAB308))
                            .frame(width: 20, height: 20)
                            .shadow(color: Color(hex: 0xEAB308).opacity(0.4), radius: 4)
                        
                        Image(systemName: vehicleIconName)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.black)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
        }
        .frame(height: 138)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private var vehicleTag: String {
        switch vehicle {
        case .midnightEV: return "EV-01"
        case .classicSarao: return "SARAO"
        case .nightRainHatchback: return "HATCH"
        case .shinkansenExpress: return "SHINKANSEN"
        case .coastalBus: return "COASTAL"
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
    
    private var departureTimeString: String {
        guard let session = activeSession else { return "12:01 AM" }
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: session.startDate)
    }
    
    private var arrivalTimeString: String {
        guard let session = activeSession, let target = session.targetDuration else { return "12:51 AM" }
        let estArrival = session.startDate.addingTimeInterval(target)
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: estArrival)
    }
    
    private var originCode: String {
        let parts = selectedCityRoute.rawValue.components(separatedBy: " ")
        if let first = parts.first {
            return first.count >= 3 ? String(first.prefix(3)).uppercased() : "MAN"
        }
        return "MAN"
    }
    
    private var originCity: String {
        let parts = selectedCityRoute.rawValue.components(separatedBy: " ")
        return parts.first ?? "Manila"
    }
    
    private var destinationCode: String {
        let parts = selectedCityRoute.rawValue.components(separatedBy: " ")
        if parts.count >= 2, let last = parts.last {
            return last.count >= 3 ? String(last.prefix(3)).uppercased() : "TRA"
        }
        return "TRA"
    }
    
    private var destinationCity: String {
        let parts = selectedCityRoute.rawValue.components(separatedBy: " ")
        if parts.count >= 2 {
            return parts.last ?? "Trajectory"
        }
        return "Trajectory"
    }
    
    private var routeColor: Color {
        switch state {
        case .cruising:
            return Color(hex: 0x22C55E) // Neon Emerald
        case .trafficStalled:
            return Color(hex: 0xEF4444) // Hazard Red
        case .pitStop:
            return Color(hex: 0xF59E0B) // Amber
        case .idle:
            return Color(hex: 0x22C55E)
        case .completed:
            return Color(hex: 0x22C55E)
        }
    }
    
    private var statusBadgeText: String {
        switch state {
        case .cruising: return "ON TIME"
        case .trafficStalled: return "GRIDLOCK"
        case .pitStop: return "MISSION HOLD"
        case .idle: return "STANDBY"
        case .completed: return "ARRIVED"
        }
    }
}

// MARK: - Dashed Line & Dotted Globe

struct DashedLineView: View {
    var body: some View {
        LineShape()
            .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
    }
}

struct LineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}

/// Dynamic spherical dotted wireframe globe placed gently at the bottom of the card.
struct DottedGlobeMeshView: View {
    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height + 70
            let radius: CGFloat = 130
            
            let rows = 8
            let cols = 24
            
            for row in 0..<rows {
                let phi = Double(row) / Double(rows) * (Double.pi / 3.0) + 0.15
                let y = centerY - radius * CGFloat(cos(phi))
                
                let rowWidth = radius * CGFloat(sin(phi)) * 2
                let startX = centerX - (rowWidth / 2)
                
                for col in 0..<cols {
                    let u = Double(col) / Double(cols)
                    let x = startX + rowWidth * CGFloat(u)
                    
                    let distFromCenter = abs(x - centerX) / (rowWidth / 2 + 1)
                    if distFromCenter <= 1.0 {
                        let alpha = (1.0 - distFromCenter * 0.7) * (Double(rows - row) / Double(rows))
                        let dotSize: CGFloat = (distFromCenter < 0.5 ? 1.8 : 1.2)
                        
                        let rect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
                        context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(alpha * 0.6)))
                    }
                }
            }
        }
    }
}
