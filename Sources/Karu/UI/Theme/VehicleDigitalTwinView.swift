import SwiftUI
import KaruCore

/// Sleek top-down 3D vector vehicle digital twin for the Tesla/Cybertruck cockpit.
/// Renders a dynamic vector model with illuminated lightbars, neon ground glow, and headlights.
public struct VehicleDigitalTwinView: View {
    let vehicle: VehicleType
    let state: TransitState
    let size: CGSize

    @State private var pulseGlow: Bool = false

    public init(vehicle: VehicleType = .midnightEV, state: TransitState = .cruising, size: CGSize = CGSize(width: 48, height: 80)) {
        self.vehicle = vehicle
        self.state = state
        self.size = size
    }

    public var body: some View {
        ZStack {
            // Ground neon underglow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [glowColor.opacity(pulseGlow ? 0.6 : 0.35), .clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: size.width * 0.9
                    )
                )
                .frame(width: size.width * 1.5, height: size.height * 1.2)

            // Vehicle Vector Chassis
            switch vehicle {
            case .midnightEV:
                cyberEVChassis
            case .classicSarao:
                saraoJeepneyChassis
            case .nightRainHatchback:
                hatchbackChassis
            case .shinkansenExpress:
                shinkansenChassis
            case .coastalBus:
                coastalBusChassis
            }
        }
        .frame(width: size.width, height: size.height)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseGlow = true
            }
        }
    }

    private var glowColor: Color {
        switch state {
        case .cruising:
            return KaruTheme.cyberCyan
        case .trafficStalled:
            return KaruTheme.cyberOrange
        case .pitStop:
            return KaruTheme.hazardAmber
        case .idle, .completed:
            return Color(hex: UInt(vehicle.themeColorHex.dropFirst().prefix(6), radix: 16) ?? 0x00F0FF)
        }
    }

    // MARK: - 1. Cyber EV Vector Chassis (Model S / Cybertruck style)
    private var cyberEVChassis: some View {
        ZStack {
            // Main body shell
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x1E2536), Color(hex: 0x0F1420)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size.width, height: size.height)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: 0x334155), lineWidth: 1.2)
                )

            // Cabin / Windshield Glass
            Path { path in
                let w = size.width
                let h = size.height
                path.move(to: CGPoint(x: w * 0.22, y: h * 0.32))
                path.addLine(to: CGPoint(x: w * 0.78, y: h * 0.32))
                path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.68))
                path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.68))
                path.closeSubpath()
            }
            .fill(Color(hex: 0x080C14).opacity(0.9))
            .overlay(
                Path { path in
                    let w = size.width
                    let h = size.height
                    path.move(to: CGPoint(x: w * 0.22, y: h * 0.32))
                    path.addLine(to: CGPoint(x: w * 0.78, y: h * 0.32))
                    path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.68))
                    path.addLine(to: CGPoint(x: w * 0.15, y: h * 0.68))
                    path.closeSubpath()
                }
                .stroke(glowColor.opacity(0.4), lineWidth: 1)
            )

            // Front Full-Width Lightbar (Cyan)
            VStack {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(glowColor)
                    .frame(width: size.width * 0.78, height: 3)
                    .shadow(color: glowColor, radius: 5, x: 0, y: -2)
                Spacer()
            }
            .padding(.top, 3)

            // Rear Tail Lightbar (Cyan / Amber)
            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(state == .trafficStalled ? KaruTheme.cyberOrange : glowColor.opacity(0.8))
                    .frame(width: size.width * 0.7, height: 2.5)
                    .shadow(color: glowColor, radius: 4, x: 0, y: 2)
            }
            .padding(.bottom, 3)
        }
    }

    // MARK: - 2. Classic Sarao Jeepney Chassis
    private var saraoJeepneyChassis: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x2A1F10), Color(hex: 0x1A1208)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size.width * 0.95, height: size.height * 1.05)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(hex: 0xF59E0B).opacity(0.5), lineWidth: 1.2))

            // Chrome hood details
            VStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: 0xE2E8F0))
                    .frame(width: size.width * 0.65, height: 6)
                Spacer()
            }
            .padding(.top, 4)

            // Roof rail lines
            HStack(spacing: 6) {
                Rectangle().fill(Color(hex: 0xF59E0B)).frame(width: 2, height: size.height * 0.5)
                Spacer()
                Rectangle().fill(Color(hex: 0xF59E0B)).frame(width: 2, height: size.height * 0.5)
            }
            .padding(.horizontal, 10)

            // Dual Headlights
            VStack {
                HStack {
                    Circle().fill(Color.white).frame(width: 5, height: 5).shadow(color: .white, radius: 3)
                    Spacer()
                    Circle().fill(Color.white).frame(width: 5, height: 5).shadow(color: .white, radius: 3)
                }
                .padding(.horizontal, 4)
                Spacer()
            }
            .padding(.top, 2)
        }
    }

    // MARK: - 3. Night Rain Hatchback Chassis
    private var hatchbackChassis: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x1E1A2E), Color(hex: 0x100E1A)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size.width * 0.92, height: size.height * 0.88)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0x8B5CF6).opacity(0.4), lineWidth: 1.2))

            // Rear curved glass
            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: 0x0A0914))
                    .frame(width: size.width * 0.75, height: 18)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: 0x8B5CF6).opacity(0.3), lineWidth: 1))
            }
            .padding(.bottom, 8)

            // Violet Headlights
            VStack {
                HStack {
                    RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xA78BFA)).frame(width: 8, height: 3)
                    Spacer()
                    RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0xA78BFA)).frame(width: 8, height: 3)
                }
                .padding(.horizontal, 5)
                Spacer()
            }
            .padding(.top, 3)
        }
    }

    // MARK: - 4. Shinkansen Bullet Train Chassis
    private var shinkansenChassis: some View {
        ZStack {
            // Aerodynamic long bullet nose
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xF8FAFC), Color(hex: 0xCBD5E1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size.width * 0.75, height: size.height * 1.2)
                .overlay(Capsule().stroke(Color(hex: 0x10B981), lineWidth: 1.2))

            // Cockpit canopy
            VStack {
                Capsule()
                    .fill(Color(hex: 0x0F172A))
                    .frame(width: size.width * 0.45, height: 16)
                    .padding(.top, 14)
                Spacer()
            }

            // Emerald center racing stripe
            Rectangle()
                .fill(Color(hex: 0x10B981))
                .frame(width: 3, height: size.height * 0.8)
                .shadow(color: Color(hex: 0x10B981), radius: 4)
        }
    }

    // MARK: - 5. Coastal Bus Chassis
    private var coastalBusChassis: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x1E3A5F), Color(hex: 0x0F1D30)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size.width * 0.98, height: size.height * 1.15)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: 0x3B82F6).opacity(0.5), lineWidth: 1.2))

            // Roof panoramic vents
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0x3B82F6).opacity(0.4)).frame(width: size.width * 0.6, height: 6)
                RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0x3B82F6).opacity(0.4)).frame(width: size.width * 0.6, height: 6)
                RoundedRectangle(cornerRadius: 2).fill(Color(hex: 0x3B82F6).opacity(0.4)).frame(width: size.width * 0.6, height: 6)
            }

            // High-power front beam
            VStack {
                RoundedRectangle(cornerRadius: 1).fill(Color.white).frame(width: size.width * 0.8, height: 3).shadow(color: .white, radius: 4)
                Spacer()
            }
            .padding(.top, 2)
        }
    }
}
