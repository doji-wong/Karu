import SwiftUI
import KaruCore

// MARK: - Reusable Custom Mission Input Row

/// Compact, high-contrast input strip for custom seat code (e.g., "7X") and custom mission objective.
struct CustomMissionInputRow: View {
    @Binding var seatCode: String
    @Binding var taskTitle: String
    var showSetButton: Bool = false
    var onCommit: (() -> Void)? = nil
    var onSet: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 6) {
            // Seat Code Input
            HStack(spacing: 3) {
                Text("SEAT")
                    .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(KaruTheme.textMuted)
                TextField("7X", text: $seatCode)
                    .textFieldStyle(.plain)
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white)
                    .frame(width: 28)
                    .onChange(of: seatCode) { _, _ in
                        onCommit?()
                    }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            // Mission / Task Title Input
            HStack(spacing: 3) {
                Text("MISSION")
                    .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(KaruTheme.textMuted)
                TextField("Task title / objective...", text: $taskTitle)
                    .textFieldStyle(.plain)
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundStyle(Color.white)
                    .onChange(of: taskTitle) { _, _ in
                        onCommit?()
                    }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            // Optional Set Button for standalone drawer
            if showSetButton {
                Button {
                    onSet?()
                } label: {
                    Text("SET")
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Reusable Selectable Pill

/// Clean high-contrast pill button used for duration presets and cabin seat codes.
struct SelectablePill: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    var helpText: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 7.5, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 8, weight: isSelected ? .black : .bold, design: .monospaced))
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.08))
            )
            .foregroundStyle(isSelected ? Color.black : Color.white)
        }
        .buttonStyle(.plain)
        .help(helpText ?? title)
    }
}

// MARK: - Airport Picker Drawer

/// Scrollable airport search & selection list for departure (origin) and arrival (destination).
struct FlightCardAirportPickerDrawer: View {
    let isOrigin: Bool
    let selectedAirportCode: String
    var maxHeight: CGFloat = 120
    let onSelectAirport: (DestinationAirport) -> Void

    @State private var searchQuery: String = ""

    private var filteredAirports: [DestinationAirport] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            return DestinationAirport.worldwideDestinations
        }
        return DestinationAirport.worldwideDestinations.filter {
            $0.code.lowercased().contains(query) ||
            $0.cityName.lowercased().contains(query) ||
            $0.countryName.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 9))
                    .foregroundStyle(KaruTheme.textMuted)

                TextField("Search airport code or city...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white)
            }
            .padding(6)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            // Results List
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(filteredAirports) { airport in
                        let isSelected = (selectedAirportCode == airport.code)

                        Button {
                            onSelectAirport(airport)
                        } label: {
                            HStack(spacing: 8) {
                                Text(airport.countryFlag)
                                    .font(.system(size: 14))

                                VStack(alignment: .leading, spacing: 1) {
                                    HStack(spacing: 4) {
                                        Text(airport.cityName)
                                            .font(.system(size: 10.5, weight: .bold))
                                            .foregroundStyle(Color.white)
                                        Text("(\(airport.code))")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundStyle(Color.white.opacity(0.7))
                                    }
                                    Text("\(airport.countryName) · \(airport.timeZoneCode)")
                                        .font(.system(size: 8))
                                        .foregroundStyle(KaruTheme.textSecondary)
                                }

                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color(hex: 0xFF5C00))
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(isSelected ? KaruTheme.surfaceElevated : Color.white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: maxHeight)
        }
    }
}

// MARK: - Seat Class Picker Drawer

/// Drawer presenting all standard cabin seat classes and custom mission configuration.
struct FlightCardSeatPickerDrawer: View {
    let currentSeatCode: String
    let isCustomSeatSelected: Bool
    @Binding var customSeatCode: String
    @Binding var customTaskName: String
    let customSeatIcon: String
    let onSelectStandardSeat: (FocusSeatClass) -> Void
    let onSyncCustomSeat: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                ForEach(FocusSeatClass.allCases) { seat in
                    let isSelected = !isCustomSeatSelected && (currentSeatCode == seat.rawValue)
                    seatClassRow(
                        icon: seat.iconSymbol,
                        title: seat.title,
                        badge: "[\(seat.seatCode)]",
                        subtitle: seat.subtitle,
                        isSelected: isSelected
                    ) {
                        onSelectStandardSeat(seat)
                    }
                }

                // Custom Mission & Seat Option
                VStack(spacing: 5) {
                    let isSelectedCustom = isCustomSeatSelected || (FocusSeatClass.find(code: currentSeatCode) == nil)

                    seatClassRow(
                        icon: customSeatIcon,
                        title: customTaskName.isEmpty ? "CUSTOM MISSION" : customTaskName.uppercased(),
                        badge: "[Seat \(customSeatCode.isEmpty ? "7X" : customSeatCode.uppercased())]",
                        subtitle: "Custom Objective · User-Defined Seat Code",
                        isSelected: isSelectedCustom
                    ) {
                        onSyncCustomSeat()
                        onDismiss()
                    }

                    CustomMissionInputRow(
                        seatCode: $customSeatCode,
                        taskTitle: $customTaskName,
                        showSetButton: true,
                        onCommit: nil,
                        onSet: {
                            onSyncCustomSeat()
                            onDismiss()
                        }
                    )
                    .padding(.horizontal, 4)
                }
            }
        }
        .frame(maxHeight: 145)
    }

    private func seatClassRow(
        icon: String,
        title: String,
        badge: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 22, height: 22)
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(title)
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundStyle(Color.white)
                        Text(badge)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    Text(subtitle)
                        .font(.system(size: 8))
                        .foregroundStyle(KaruTheme.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: 0xFF5C00))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isSelected ? KaruTheme.surfaceElevated : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
