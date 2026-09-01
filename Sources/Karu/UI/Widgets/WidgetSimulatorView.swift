import SwiftUI
import KaruCore

/// Interactive In-App Widget Simulator & Preview Testbed (`Cmd + Shift + W`).
/// Renders the exact Direction A Monochrome Avionics Small and Medium widgets with live engine reactivity.
public struct WidgetSimulatorView: View {
    var engine: TransitEngine
    @State private var previewMode: SimulatorMode = .live
    @State private var lastExportedDate: Date? = Date()

    public enum SimulatorMode: String, CaseIterable, Identifiable {
        case live = "Live Engine"
        case cruising = "Cruising Mock"
        case idle = "Standby Mock"
        case turbulence = "Turbulence Mock"

        public var id: String { rawValue }
    }

    public init(engine: TransitEngine) {
        self.engine = engine
    }

    private var activeSnapshot: WidgetTelemetrySnapshot {
        switch previewMode {
        case .live:
            return engine.generateWidgetSnapshot()
        case .cruising:
            return .previewMock
        case .idle:
            return .idleMock
        case .turbulence:
            return .turbulenceMock
        }
    }

    public var body: some View {
        VStack(spacing: 20) {
            // MARK: - Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 6, height: 6)
                        Text("AVIONICS DESKTOP WIDGET TESTBED")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .tracking(1.0)
                    }

                    Text("Direction A Monochrome Avionics • macOS 14+ WidgetKit Preview")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(KaruTheme.textMuted)
                }

                Spacer()

                // Simulator Mode Picker
                Picker("", selection: $previewMode) {
                    ForEach(SimulatorMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 320)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Divider()
                .background(Color.white.opacity(0.08))

            // MARK: - Widget Canvases (Small + Medium)
            ScrollView {
                VStack(spacing: 28) {
                    // Small Widget Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("SMALL WIDGET (158 × 158 PT • SYSTEMSMALL)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(KaruTheme.textMuted)
                            Spacer()
                            Text("Instrument Airspeed Gauge")
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundColor(KaruTheme.textSecondary)
                        }

                        HStack {
                            Spacer()
                            SmallAirspeedGaugeWidgetView(snapshot: activeSnapshot)
                                .frame(width: 158, height: 158)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.6), radius: 12, x: 0, y: 6)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 24)

                    // Medium Widget Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("MEDIUM WIDGET (338 × 158 PT • SYSTEMMEDIUM)")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(KaruTheme.textMuted)
                            Spacer()
                            Text("Flight Dispatch Board")
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundColor(KaruTheme.textSecondary)
                        }

                        HStack {
                            Spacer()
                            MediumFlightDispatchWidgetView(
                                snapshot: activeSnapshot,
                                onTakeoffAction: {
                                    if engine.state == .idle {
                                        engine.startFlight()
                                    } else if engine.state == .pitStop {
                                        engine.resumeFromGateHold()
                                    }
                                },
                                onHoldAction: {
                                    engine.enterGateHold()
                                }
                            )
                            .frame(width: 338, height: 158)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.6), radius: 12, x: 0, y: 6)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 24)

                    // Footer Information
                    HStack(spacing: 12) {
                        Image(systemName: "externaldrive.badge.checkmark")
                            .font(.system(size: 11))
                            .foregroundColor(KaruTheme.textMuted)

                        Text("Atomic Snapshot: ~/Library/Application Support/Karu/widget_snapshot.json")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(KaruTheme.textMuted)

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                .padding(.vertical, 12)
            }
        }
        .frame(width: 580, height: 560)
        .background(KaruTheme.background)
    }
}
