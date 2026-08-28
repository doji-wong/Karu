import SwiftUI
import KaruCore

/// Minimalist Tesla-inspired PRND Gear Telemetry Selector for the Karu Cockpit.
///
/// States:
/// - **P (Parked):** App is idle or trip completed.
/// - **R (Reverse):** Traffic stalled / distraction hazard active.
/// - **N (Neutral):** Pit stop / manual pause.
/// - **D (Drive):** Cruising focus at 100 km/h with Autopilot engaged.
public struct TeslaGearSelectorView: View {
    let state: TransitState
    let showEnergyBar: Bool
    let focusFraction: Double

    public init(state: TransitState, showEnergyBar: Bool = true, focusFraction: Double = 1.0) {
        self.state = state
        self.showEnergyBar = showEnergyBar
        self.focusFraction = focusFraction
    }

    private let gears = ["P", "R", "N", "D"]

    public var body: some View {
        HStack(spacing: 12) {
            // PRND Cluster
            HStack(spacing: 8) {
                ForEach(gears, id: \.self) { gear in
                    let isCurrent = isGearActive(gear)
                    VStack(spacing: 2) {
                        Text(gear)
                            .font(KaruTheme.gearSelector)
                            .foregroundStyle(isCurrent ? gearActiveColor(gear) : KaruTheme.textDimmed)
                            .shadow(color: isCurrent ? gearActiveColor(gear).opacity(0.6) : .clear, radius: 4)

                        // Glowing underline bar for active gear
                        RoundedRectangle(cornerRadius: 1)
                            .fill(isCurrent ? gearActiveColor(gear) : Color.clear)
                            .frame(width: 12, height: 2)
                            .shadow(color: isCurrent ? gearActiveColor(gear).opacity(0.8) : .clear, radius: 3)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(KaruTheme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(KaruTheme.cardBorder, lineWidth: 1)
            )

            // Optional Tesla Battery / Focus Energy Bar
            if showEnergyBar {
                HStack(spacing: 6) {
                    // Battery Shell
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2.5)
                            .stroke(KaruTheme.textSecondary.opacity(0.5), lineWidth: 1.2)
                            .frame(width: 28, height: 13)

                        // Battery Terminal Tip
                        RoundedRectangle(cornerRadius: 1)
                            .fill(KaruTheme.textSecondary.opacity(0.5))
                            .frame(width: 2, height: 6)
                            .offset(x: 29)

                        // Battery Level Fill
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(
                                LinearGradient(
                                    colors: [KaruTheme.cyberCyan, KaruTheme.cruiseEmerald],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(2, 24 * CGFloat(min(1.0, max(0.0, focusFraction)))), height: 9)
                            .padding(.leading, 2)
                            .shadow(color: KaruTheme.cyberCyan.opacity(0.4), radius: 3)
                    }
                    .frame(width: 32, height: 13)

                    // Percentage Text
                    Text("\(Int(focusFraction * 100))%")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.textPrimary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(KaruTheme.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(KaruTheme.cardBorder, lineWidth: 1)
                )
            }
        }
    }

    private func isGearActive(_ gear: String) -> Bool {
        switch gear {
        case "P":
            return state == .idle || state == .completed
        case "R":
            return state == .trafficStalled
        case "N":
            return state == .pitStop
        case "D":
            return state == .cruising
        default:
            return false
        }
    }

    private func gearActiveColor(_ gear: String) -> Color {
        switch gear {
        case "P":
            return .white
        case "R":
            return KaruTheme.cyberOrange
        case "N":
            return KaruTheme.hazardAmber
        case "D":
            return KaruTheme.cyberCyan
        default:
            return .white
        }
    }
}
