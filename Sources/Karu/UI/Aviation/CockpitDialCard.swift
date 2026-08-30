import SwiftUI
import KaruCore

/// Authentic Cockpit Altimeter / Speedometer Dial & Moving Digital LCD Odometer Card.
public struct CockpitDialCard: View {
    public let state: TransitState
    public let velocity: Double
    public let session: TripSession?
    public var vehicle: VehicleType = .midnightEV
    
    public init(
        state: TransitState,
        velocity: Double,
        session: TripSession?,
        vehicle: VehicleType = .midnightEV
    ) {
        self.state = state
        self.velocity = velocity
        self.session = session
        self.vehicle = vehicle
    }
    
    public var body: some View {
        TimelineView(.animation(paused: state != .cruising)) { timeline in
            let date = timeline.date
            let flutter = state == .cruising ? (sin(date.timeIntervalSince1970 * 4.0) * 0.02) : 0.0
            let normalizedDial = max(0.0, min(1.0, baseDialProgress + flutter))
            
            ZStack(alignment: .top) {
                // Background Card
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(hex: 0x0C0D10))
                
                // Subtle Warm Crimson Ambient Glow
                RadialGradient(
                    colors: [Color(hex: 0x7F1D1D).opacity(0.45), Color.clear],
                    center: UnitPoint(x: 0.5, y: 0.8),
                    startRadius: 10,
                    endRadius: 90
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                
                VStack(spacing: 0) {
                    // Top Row: Vehicle Tag (e.g. EV-01) & Moving Altitude/Distance Counter
                    HStack(alignment: .top) {
                        // Tag Badge
                        Text(vehicleTag)
                            .font(.system(size: 8, weight: .heavy, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.8))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        Spacer()
                        
                        // Altitude / Distance Live Counter
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("ALTITUDE")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.45))
                                .tracking(0.8)
                            
                            Text(altitudeDisplay(date: date))
                                .font(.system(size: 14, weight: .heavy, design: .monospaced))
                                .foregroundStyle(Color.white)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 14)
                    
                    Spacer()
                    
                    // ── Continuous Cockpit Speedometer & Moving Needle ──
                    ZStack(alignment: .bottom) {
                        CockpitContinuousDialView(
                            progress: normalizedDial,
                            needleColor: needleColor
                        )
                        .frame(height: 72)
                        
                        // Retro Green Backlit LCD Odometer Box
                        lcdSpeedometerBox(date: date)
                            .offset(y: 2)
                    }
                    .padding(.bottom, 8)
                }
            }
            .frame(height: 138)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
    
    // MARK: - LCD Speedometer Box (Moving Retro Green LCD Display)
    private func lcdSpeedometerBox(date: Date) -> some View {
        let speedDisplay = movingLcdSpeed(date: date)
        
        return HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text("\(Int(speedDisplay))")
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundStyle(Color(hex: 0x1C2F15))
            
            Text("MPH")
                .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(hex: 0x1C2F15).opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2.5)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xBDDDA8), Color(hex: 0xA3CD8C)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color(hex: 0x4A6B38), lineWidth: 0.8)
        )
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
    
    private func altitudeDisplay(date: Date) -> String {
        if let s = session {
            let baseFeet = 10000 + Int(s.distanceTraveledKm * 1500)
            let microJitter = state == .cruising ? Int(sin(date.timeIntervalSince1970 * 2.0) * 15) : 0
            let feet = max(0, baseFeet + microJitter)
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return "\(formatter.string(from: NSNumber(value: feet)) ?? "10,375") FT"
        }
        return "10,375 FT"
    }
    
    private func movingLcdSpeed(date: Date) -> Double {
        if state == .cruising {
            let jitter = sin(date.timeIntervalSince1970 * 3.5) * 4.0
            return 859.0 + jitter
        } else if state == .trafficStalled {
            return 0.0
        } else {
            return 859.0
        }
    }
    
    private var baseDialProgress: Double {
        switch state {
        case .cruising: return 0.58 // 600 MPH
        case .trafficStalled: return 0.0
        case .pitStop: return 0.20
        case .idle: return 0.58
        case .completed: return 1.0
        }
    }
    
    private var needleColor: Color {
        switch state {
        case .cruising: return Color(hex: 0xFACC15) // Bright Cockpit Yellow
        case .trafficStalled: return Color(hex: 0xEF4444) // Alert Red
        case .pitStop: return Color(hex: 0xF59E0B)
        case .idle: return Color(hex: 0xFACC15)
        case .completed: return Color(hex: 0x22C55E)
        }
    }
}

// MARK: - Continuous Cockpit Dial Arc Canvas View

struct CockpitContinuousDialView: View {
    var progress: Double // 0.0 to 1.0
    var needleColor: Color
    
    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height + 10
            let radius: CGFloat = 68
            
            let startDeg: Double = 200.0
            let endDeg: Double = 340.0
            let spanDeg = endDeg - startDeg // 140 degrees
            
            let startRad = startDeg * Double.pi / 180.0
            let endRad = endDeg * Double.pi / 180.0
            
            // 1. Continuous Red Limit Ring on Top
            var redPath = Path()
            redPath.addArc(
                center: CGPoint(x: centerX, y: centerY),
                radius: radius + 3,
                startAngle: Angle(radians: startRad),
                endAngle: Angle(radians: endRad),
                clockwise: false
            )
            context.stroke(redPath, with: .color(Color(hex: 0xEF4444).opacity(0.85)), lineWidth: 1.5)
            
            // 2. Main Dial Arc Semicircle Track
            var trackPath = Path()
            trackPath.addArc(
                center: CGPoint(x: centerX, y: centerY),
                radius: radius,
                startAngle: Angle(radians: startRad),
                endAngle: Angle(radians: endRad),
                clockwise: false
            )
            context.stroke(trackPath, with: .color(Color.white.opacity(0.2)), lineWidth: 1.5)
            
            // 3. Dial Ticks & Numeric Markings (400, 500, 600, 700, 800)
            let totalTicks = 20
            let labels = ["400", "500", "600", "700", "800"]
            
            for i in 0...totalTicks {
                let frac = Double(i) / Double(totalTicks)
                let angleDeg = startDeg + frac * spanDeg
                let rad = angleDeg * Double.pi / 180.0
                
                let isMajor = (i % 5 == 0)
                let innerR: CGFloat = radius - (isMajor ? 8.0 : 4.5)
                let outerR: CGFloat = radius
                
                let p1 = CGPoint(x: centerX + CGFloat(cos(rad)) * innerR, y: centerY + CGFloat(sin(rad)) * innerR)
                let p2 = CGPoint(x: centerX + CGFloat(cos(rad)) * outerR, y: centerY + CGFloat(sin(rad)) * outerR)
                
                var tickPath = Path()
                tickPath.move(to: p1)
                tickPath.addLine(to: p2)
                context.stroke(tickPath, with: .color(Color.white.opacity(isMajor ? 0.9 : 0.4)), lineWidth: isMajor ? 1.5 : 1.0)
                
                // Draw Label on Major Ticks
                if isMajor {
                    let labelIdx = i / 5
                    if labelIdx < labels.count {
                        let text = Text(labels[labelIdx])
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.7))
                        
                        let textR: CGFloat = radius - 15.0
                        let textPos = CGPoint(x: centerX + CGFloat(cos(rad)) * textR, y: centerY + CGFloat(sin(rad)) * textR)
                        context.draw(text, at: textPos)
                    }
                }
            }
            
            // 4. Moving Bright Cockpit Yellow Needle
            let clampedProgress = max(0.0, min(1.0, progress))
            let needleAngleDeg = startDeg + clampedProgress * spanDeg
            let needleRad = needleAngleDeg * Double.pi / 180.0
            
            let tipR: CGFloat = radius + 2.0
            let baseR: CGFloat = radius - 28.0
            
            let tipPos = CGPoint(x: centerX + CGFloat(cos(needleRad)) * tipR, y: centerY + CGFloat(sin(needleRad)) * tipR)
            let basePos = CGPoint(x: centerX + CGFloat(cos(needleRad)) * baseR, y: centerY + CGFloat(sin(needleRad)) * baseR)
            
            var needlePath = Path()
            needlePath.move(to: basePos)
            needlePath.addLine(to: tipPos)
            context.stroke(
                needlePath,
                with: .color(needleColor),
                style: StrokeStyle(lineWidth: 2.2, lineCap: .round)
            )
            
            // 5. Central Hub Pivot Dot
            let hubRect = CGRect(x: centerX - 4, y: centerY - 14, width: 8, height: 8)
            context.fill(Path(ellipseIn: hubRect), with: .color(Color(hex: 0x181A20)))
            context.stroke(Path(ellipseIn: hubRect), with: .color(Color.white.opacity(0.4)), lineWidth: 1)
        }
    }
}
