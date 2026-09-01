import SwiftUI
import KaruCore

/// A high-contrast carbon-matte mini avionics cockpit view rendered dynamically into the macOS Dock icon.
public struct DynamicDockTileView: View {
    public let state: TransitState
    public let velocityKts: Int
    public let progressFraction: Double
    public let remainingMinutes: Int
    public let originCode: String
    public let destinationCode: String
    public let aircraftCode: String

    public init(
        state: TransitState,
        velocityKts: Int,
        progressFraction: Double,
        remainingMinutes: Int,
        originCode: String,
        destinationCode: String,
        aircraftCode: String
    ) {
        self.state = state
        self.velocityKts = velocityKts
        self.progressFraction = min(1.0, max(0.0, progressFraction))
        self.remainingMinutes = remainingMinutes
        self.originCode = originCode
        self.destinationCode = destinationCode
        self.aircraftCode = aircraftCode
    }

    public var body: some View {
        ZStack {
            // 1. Carbon Matte Squircle Base
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0x121218),
                            Color(hex: 0x070709)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
                )

            // 2. Outer Avionics Circular Progress Track
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 6)
                .padding(12)

            // 3. Dynamic Telemetry Progress Ring
            switch state {
            case .cruising:
                Circle()
                    .trim(from: 0, to: CGFloat(max(0.04, progressFraction)))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Color(hex: 0x00E5FF), Color(hex: 0x10B981), Color(hex: 0x00E5FF)]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(12)
                    .shadow(color: Color(hex: 0x00E5FF).opacity(0.5), radius: 4)

            case .trafficStalled:
                Circle()
                    .stroke(Color(hex: 0xEF4444), style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [6, 4]))
                    .padding(12)
                    .shadow(color: Color(hex: 0xEF4444).opacity(0.7), radius: 5)

            case .pitStop:
                Circle()
                    .stroke(Color(hex: 0xFFD600), style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [8, 4]))
                    .padding(12)

            case .completed:
                Circle()
                    .stroke(Color(hex: 0x10B981), lineWidth: 6)
                    .padding(12)
                    .shadow(color: Color(hex: 0x10B981).opacity(0.6), radius: 4)

            case .idle:
                // Subtle radar tick marks
                Circle()
                    .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 2, dash: [2, 10]))
                    .padding(14)
            }

            // 4. Central Avionics Instrument Readouts
            VStack(spacing: 1) {
                // Route pill
                Text("\(originCode) ✈ \(destinationCode)")
                    .font(.system(size: 8.5, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())

                // Main Central Velocity / State Readout
                switch state {
                case .cruising:
                    Text("\(velocityKts)")
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(hex: 0x00E5FF))
                        .shadow(color: Color(hex: 0x00E5FF).opacity(0.5), radius: 3)
                    
                    Text("KTS • \(remainingMinutes)M")
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: 0x10B981))

                case .trafficStalled:
                    Text("STALL")
                        .font(.system(size: 18, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(hex: 0xEF4444))
                        .shadow(color: Color(hex: 0xEF4444).opacity(0.8), radius: 4)

                    Text("0 KTS")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: 0xEF4444))

                case .pitStop:
                    Text("HOLD")
                        .font(.system(size: 20, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(hex: 0xFFD600))

                    Text("GATE PAUSE")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: 0xFFD600).opacity(0.8))

                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(hex: 0x10B981))

                    Text("LANDED")
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(hex: 0x10B981))

                case .idle:
                    Image(systemName: "airplane")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.85))

                    Text("STANDBY")
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.5))
                }

                // Aircraft Model Code
                Text(aircraftCode)
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: 0xFF5C00))
            }
            .padding(.top, 2)
        }
        .frame(width: 128, height: 128)
    }
}
