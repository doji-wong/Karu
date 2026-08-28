import SwiftUI
import KaruCore

/// Waze-inspired Isometric 2.5D Highway Navigation Map for Karu.
public struct HighwayNavigationView: View {
    @Bindable public var engine: TransitEngine

    // Animation state for continuous highway road markings
    @State private var roadOffset: CGFloat = 0.0

    public init(engine: TransitEngine) {
        self.engine = engine
    }

    public var body: some View {
        VStack(spacing: 8) {
            // Lane Telemetry Banner (Waze Navigation Header)
            laneHeaderBanner

            // 2.5D Perspective Highway Roadbed
            ZStack {
                // Background Night Sky / Distant Horizon Glow
                horizonGlow

                // Perspective Roadbed Canvas
                PerspectiveRoadShape()
                    .fill(
                        LinearGradient(
                            colors: [KaruTheme.surfaceElevated, KaruTheme.surface.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        PerspectiveRoadShape()
                            .stroke(KaruTheme.cardBorder, lineWidth: 1.5)
                    )

                // Neon Side Curbs / Guard Rails
                RoadGuardRails(glowColor: KaruTheme.statusGlow(for: engine.state))

                // Animated Center-line Road Markings
                TimelineView(.animation(paused: engine.state != .cruising)) { timeline in
                    RoadMarkingsView(offset: roadOffset)
                        .onChange(of: timeline.date) { _, _ in
                            if engine.state == .cruising {
                                roadOffset = (roadOffset + 4.0).truncatingRemainder(dividingBy: 40.0)
                            }
                        }
                }

                // Waze-Style Traffic Hazard Pins
                if let session = engine.activeSession {
                    hazardPinsOverlay(session: session)
                }

                // Active Vehicle Avatar on the Road
                vehicleAvatarView

                // Waypoint Markers (Start, 50% Milestone, Destination)
                waypointsOverlay
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(KaruTheme.cardBorder, lineWidth: 1)
            )

            // Bottom Route Distance & Progress Summary
            routeProgressFooter
        }
    }

    // MARK: - Lane Header Banner (Waze Style)
    private var laneHeaderBanner: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(KaruTheme.statusGlow(for: engine.state))
                    .frame(width: 8, height: 8)

                if engine.state == .cruising {
                    Text("LANE 1 CLEAR · 100 KM/H")
                        .font(KaruTheme.captionMono)
                        .fontWeight(.bold)
                        .foregroundStyle(KaruTheme.cruiseNeon)
                } else if engine.state == .trafficStalled {
                    let hazardApp = engine.activeSession?.incidents.last?.appName ?? "Distraction"
                    Text("GRIDLOCK AHEAD · HAZARD: \(hazardApp.uppercased())")
                        .font(KaruTheme.captionMono)
                        .fontWeight(.bold)
                        .foregroundStyle(KaruTheme.hazardAmber)
                } else if engine.state == .pitStop {
                    Text("REST AREA · PIT STOP")
                        .font(KaruTheme.captionMono)
                        .fontWeight(.bold)
                        .foregroundStyle(KaruTheme.navCyan)
                } else {
                    Text("HIGHWAY READY · ON-RAMP")
                        .font(KaruTheme.captionMono)
                        .fontWeight(.bold)
                        .foregroundStyle(KaruTheme.textSecondary)
                }
            }

            Spacer()

            if let session = engine.activeSession, let target = session.targetDuration {
                let remaining = max(0, target - session.cruisingDuration)
                let mins = Int(remaining) / 60
                Text("ETA \(mins) MIN")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.textPrimary)
            } else {
                Text("OPEN RUN")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.textMuted)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(KaruTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Horizon Glow
    private var horizonGlow: some View {
        VStack {
            LinearGradient(
                colors: [KaruTheme.statusGlow(for: engine.state).opacity(0.25), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 50)
            Spacer()
        }
    }

    // MARK: - Vehicle Avatar
    private var vehicleAvatarView: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    // Vehicle Glyph
                    ZStack {
                        Circle()
                            .fill(KaruTheme.background)
                            .frame(width: 38, height: 38)
                            .shadow(color: KaruTheme.statusGlow(for: engine.state).opacity(0.6), radius: 8, x: 0, y: 2)

                        Image(systemName: vehicleIconName(for: engine.activeVehicle))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(KaruTheme.statusGlow(for: engine.state))
                    }

                    // Speed Badge under Vehicle
                    Text("\(Int(engine.currentVelocity)) km/h")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(KaruTheme.statusGlow(for: engine.state))
                        .clipShape(Capsule())
                }
                Spacer()
            }
            .padding(.bottom, 12)
        }
    }

    // MARK: - Hazard Pins Overlay
    private func hazardPinsOverlay(session: TripSession) -> some View {
        ZStack {
            if engine.state == .trafficStalled {
                // Active Road Hazard Cone / Pin right ahead of vehicle
                VStack {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(KaruTheme.hazardAmber)
                        Text(session.incidents.last?.appName ?? "Hazard")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.85))
                    .overlay(Capsule().stroke(KaruTheme.hazardAmber, lineWidth: 1.5))
                    .clipShape(Capsule())
                    .shadow(color: KaruTheme.hazardAmber.opacity(0.5), radius: 6)

                    Spacer().frame(height: 55)
                }
            }
        }
    }

    // MARK: - Waypoints Overlay
    private var waypointsOverlay: some View {
        VStack {
            HStack {
                // Origin On-ramp
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .foregroundStyle(KaruTheme.navCyan)
                    Text("START")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(KaruTheme.textMuted)
                }
                .padding(6)

                Spacer()

                // Destination Flag
                HStack(spacing: 3) {
                    Text("DESTINATION")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(KaruTheme.cruiseNeon)
                    Image(systemName: "flag.checkered.circle.fill")
                        .foregroundStyle(KaruTheme.cruiseEmerald)
                }
                .padding(6)
            }
            Spacer()
        }
    }

    // MARK: - Route Progress Footer
    private var routeProgressFooter: some View {
        HStack {
            if let session = engine.activeSession {
                HStack(spacing: 4) {
                    Image(systemName: "road.lanes")
                        .font(.caption)
                    Text(String(format: "%.1f km covered", session.distanceTraveledKm))
                        .font(KaruTheme.captionMono)
                }
                .foregroundStyle(KaruTheme.textSecondary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "gauge.with.dots.needle.50percent")
                        .font(.caption)
                    Text("\(Int(session.cruiseEfficiency))% Efficiency")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.cruiseNeon)
                }
            } else {
                Text("Select route and press Start Trip")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.textMuted)
                Spacer()
            }
        }
        .padding(.horizontal, 4)
    }

    private func vehicleIconName(for vehicle: VehicleType) -> String {
        switch vehicle {
        case .midnightEV: return "bolt.car.fill"
        case .classicSarao: return "bus.fill"
        case .nightRainHatchback: return "car.side.fill"
        case .shinkansenExpress: return "tram.fill"
        case .coastalBus: return "bus.doubledecker.fill"
        }
    }
}

// MARK: - 2.5D Perspective Shapes

struct PerspectiveRoadShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topWidth: CGFloat = rect.width * 0.45
        let bottomWidth: CGFloat = rect.width * 0.90
        
        let topLeft = CGPoint(x: (rect.width - topWidth) / 2, y: 0)
        let topRight = CGPoint(x: (rect.width + topWidth) / 2, y: 0)
        let bottomRight = CGPoint(x: (rect.width + bottomWidth) / 2, y: rect.height)
        let bottomLeft = CGPoint(x: (rect.width - bottomWidth) / 2, y: rect.height)

        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.closeSubpath()
        return path
    }
}

struct RoadGuardRails: View {
    var glowColor: Color

    var body: some View {
        GeometryReader { geo in
            Path { path in
                let topWidth = geo.size.width * 0.45
                let bottomWidth = geo.size.width * 0.90

                // Left Guardrail
                path.move(to: CGPoint(x: (geo.size.width - topWidth) / 2, y: 0))
                path.addLine(to: CGPoint(x: (geo.size.width - bottomWidth) / 2, y: geo.size.height))

                // Right Guardrail
                path.move(to: CGPoint(x: (geo.size.width + topWidth) / 2, y: 0))
                path.addLine(to: CGPoint(x: (geo.size.width + bottomWidth) / 2, y: geo.size.height))
            }
            .stroke(glowColor.opacity(0.6), lineWidth: 2)
        }
    }
}

struct RoadMarkingsView: View {
    var offset: CGFloat

    var body: some View {
        GeometryReader { geo in
            Path { path in
                let centerX = geo.size.width / 2
                let dashLength: CGFloat = 18
                let spacing: CGFloat = 22

                var y: CGFloat = -40 + offset
                while y < geo.size.height + 40 {
                    path.move(to: CGPoint(x: centerX, y: y))
                    path.addLine(to: CGPoint(x: centerX, y: y + dashLength))
                    y += dashLength + spacing
                }
            }
            .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }
}
