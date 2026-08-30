import SwiftUI
import KaruCore

/// Pilot's Flight Logbook window displaying historical focus sessions, streaks, and flight telemetry.
public struct LogbookView: View {
    public var storage: LocalStorageManager
    @State private var tripHistory: [TripSession] = []
    @State private var habits: [Habit] = []

    public init(storage: LocalStorageManager) {
        self.storage = storage
    }

    private var totalFocusHours: Double {
        let totalSeconds = tripHistory.reduce(0.0) { $0 + $1.cruisingDuration }
        return totalSeconds / 3600.0
    }

    private var totalDistanceNM: Double {
        tripHistory.reduce(0.0) { $0 + $1.distanceTraveledNM }
    }

    private var totalTouchdowns: Int {
        tripHistory.filter { $0.isCompleted }.count
    }

    private var fleetEfficiency: Double {
        guard !tripHistory.isEmpty else { return 100.0 }
        let totalActive = tripHistory.reduce(0.0) { $0 + $1.activeFlightDuration }
        let totalCruise = tripHistory.reduce(0.0) { $0 + $1.cruisingDuration }
        guard totalActive > 0 else { return 100.0 }
        return (totalCruise / totalActive) * 100.0
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PILOT LOGBOOK & FLIGHT HISTORY")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(Color(hex: 0xFF5C00))
                    Text("Flight Hours & On-Time Performance")
                        .font(KaruTheme.headerTitle)
                        .foregroundStyle(KaruTheme.textPrimary)
                }
                Spacer()
                Image(systemName: "airplane.departure")
                    .font(.title2)
                    .foregroundStyle(Color(hex: 0xFF5C00))
            }

            Divider().background(KaruTheme.cardBorder)

            // Top Telemetry Metrics Cards
            HStack(spacing: 12) {
                metricCard(
                    title: "TOTAL FLIGHT TIME",
                    value: String(format: "%.1f HRS", totalFocusHours),
                    icon: "clock.fill",
                    tint: Color(hex: 0x10B981)
                )

                metricCard(
                    title: "DISTANCE FLOWN",
                    value: String(format: "%.0f NM", totalDistanceNM),
                    icon: "map.fill",
                    tint: Color(hex: 0x0EA5E9)
                )

                metricCard(
                    title: "TOUCHDOWNS",
                    value: "\(totalTouchdowns)",
                    icon: "checkmark.seal.fill",
                    tint: Color(hex: 0xFF5C00)
                )

                metricCard(
                    title: "FLEET EFFICIENCY",
                    value: String(format: "%.1f%%", fleetEfficiency),
                    icon: "gauge.with.needle.fill",
                    tint: fleetEfficiency >= 85 ? Color(hex: 0x10B981) : Color(hex: 0xEF4444)
                )
            }

            Divider().background(KaruTheme.cardBorder)

            // Historical Flight Table
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("RECORDED FOCUS FLIGHTS (\(tripHistory.count))")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.textSecondary)

                    Spacer()

                    if !tripHistory.isEmpty {
                        Button {
                            clearHistory()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("Clear Logbook")
                            }
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(KaruTheme.hazardRed)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if tripHistory.isEmpty {
                    VStack(spacing: 8) {
                        Spacer()
                        Image(systemName: "airplane")
                            .font(.system(size: 32))
                            .foregroundStyle(KaruTheme.textMuted)
                        Text("No completed focus flights yet")
                            .font(KaruTheme.subheadline)
                            .foregroundStyle(KaruTheme.textMuted)
                        Text("Take off from the menu bar to log your first flight.")
                            .font(KaruTheme.captionMono)
                            .foregroundStyle(KaruTheme.textMuted.opacity(0.6))
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(tripHistory.reversed()) { session in
                                flightLogRow(session)
                            }
                        }
                    }
                    .frame(maxHeight: 280)
                }
            }
        }
        .padding(20)
        .frame(width: 580, height: 500)
        .background(KaruTheme.background)
        .onAppear {
            loadData()
        }
    }

    // MARK: - Subviews & Helpers

    @ViewBuilder
    private func metricCard(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(KaruTheme.textMuted)
            }
            Text(value)
                .font(.system(size: 15, weight: .black, design: .monospaced))
                .foregroundStyle(Color.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(KaruTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private func flightLogRow(_ session: TripSession) -> some View {
        HStack(spacing: 12) {
            // Status Icon
            Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(session.isCompleted ? Color(hex: 0x10B981) : KaruTheme.hazardRed)

            // Date & Preset
            VStack(alignment: .leading, spacing: 1) {
                Text(formattedDate(session.startDate))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white)
                Text(session.preset.displayName)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(KaruTheme.textMuted)
            }

            Spacer()

            // Cruising Minutes
            VStack(alignment: .trailing, spacing: 1) {
                Text(String(format: "%.0fm Cruise", session.cruisingDuration / 60.0))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white)

                if session.stalledDuration > 0 {
                    Text(String(format: "%.0fm Turbulence (%d)", session.stalledDuration / 60.0, session.turbulenceLogs.count))
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Color(hex: 0xEF4444))
                } else {
                    Text("100% On-Time")
                        .font(.system(size: 8.5, design: .monospaced))
                        .foregroundStyle(Color(hex: 0x10B981))
                }
            }

            // Distance
            Text(String(format: "%.0f NM", session.distanceTraveledNM))
                .font(.system(size: 10.5, weight: .heavy, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.8))
                .frame(width: 60, alignment: .trailing)
        }
        .padding(8)
        .background(KaruTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private func loadData() {
        self.tripHistory = storage.loadTripHistory()
        self.habits = storage.loadHabits()
    }

    private func clearHistory() {
        try? storage.saveTripHistory([])
        self.tripHistory = []
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}
