import SwiftUI
import KaruCore

// MARK: - Reusable Pre-Flight Dispatch Card Modifier

struct DispatchCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(8)
            .background(KaruTheme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
            )
    }
}

// MARK: - Pre-Flight Dispatch Deck View

/// Complete Route Clearance, Cabin Seat & Duration Deck for FocusFlightCard.
struct PreFlightDispatchDeckView: View {
    @Bindable var engine: TransitEngine
    var audioEngine: AudioEngine?
    let originAirport: DestinationAirport
    let destinationAirport: DestinationAirport
    let departureTimeString: String
    let arrivalTimeString: String
    let destinationAirportLocalTimeString: String
    let routeDistanceNM: Int
    let timezoneDeltaString: String
    let currentSeatCode: String
    let currentTaskTitle: String
    let currentSeatIcon: String

    @Binding var isCustomSeatSelected: Bool
    @Binding var customSeatCode: String
    @Binding var customTaskName: String
    @Binding var customSeatIcon: String
    @Binding var selectedDurationMinutes: Int
    @Binding var dispatchAirportTarget: AirportPickerTarget?

    let onSelectStandardSeat: (FocusSeatClass) -> Void
    let onSyncCustomSeat: () -> Void
    let onSaveDuration: (Int) -> Void
    let onClearForTakeoff: () -> Void
    let onAirportSelected: (DestinationAirport, Bool) -> Void

    var body: some View {
        if let target = dispatchAirportTarget {
            airportSelectionView(target: target)
        } else {
            clearanceDeckView
        }
    }

    // MARK: - Airport Selection Subview

    @ViewBuilder
    private func airportSelectionView(target: AirportPickerTarget) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button {
                    withAnimation(Animation.spring(response: 0.32, dampingFraction: 0.82)) {
                        dispatchAirportTarget = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 8, weight: .bold))
                        Text("BACK TO CLEARANCE")
                            .font(.system(size: 8.5, weight: .black, design: .monospaced))
                    }
                    .foregroundStyle(Color(hex: 0xFF5C00))
                }
                .buttonStyle(.plain)

                Spacer()

                Text(target == .origin ? "DEPARTURE (ORIGIN)" : "ARRIVAL (DESTINATION)")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.8))
            }
            .padding(.bottom, 2)

            FlightCardAirportPickerDrawer(
                isOrigin: target == .origin,
                selectedAirportCode: target == .origin ? originAirport.code : destinationAirport.code,
                maxHeight: 175
            ) { airport in
                onAirportSelected(airport, target == .origin)
            }
        }
    }

    // MARK: - Clearance Main Deck

    @ViewBuilder
    private var clearanceDeckView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 1. Dual Route Corridor Card (Departure & Destination with Swap)
            HStack(spacing: 6) {
                corridorAirportBox(isOrigin: true)

                // Corridor Swap Button
                Button {
                    withAnimation(Animation.spring(response: 0.32, dampingFraction: 0.82)) {
                        let oldOrigin = originAirport.code
                        let oldDest = destinationAirport.code
                        engine.updateRoute(origin: oldDest, destination: oldOrigin)
                        onAirportSelected(originAirport, false)
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(KaruTheme.surfaceElevated)
                            .frame(width: 24, height: 24)
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                }
                .buttonStyle(.plain)
                .help("Swap Departure and Destination")

                corridorAirportBox(isOrigin: false)
            }

            // 2. Seat & Cabin Class Selection Strip
            seatSectionView

            // 3. Dedicated Destination Time Control Box
            timeControlSectionView

            // 4. Clear For Takeoff Action
            Button(action: onClearForTakeoff) {
                HStack(spacing: 5.5) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 9.5, weight: .heavy))
                    Text("CLEAR FOR TAKEOFF")
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7.5)
                .background(Capsule().fill(Color.white))
                .shadow(color: Color.white.opacity(0.3), radius: 3)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Seat Section

    @ViewBuilder
    private var seatSectionView: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("03 / SEAT & CABIN CLASS")
                    .font(.system(size: 7.5, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.9))

                Spacer()

                Text("SEAT \(currentSeatCode) · \(currentTaskTitle)")
                    .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: 0xFF5C00))
                    .lineLimit(1)
            }

            // Horizontal Seat Selector Strip
            HStack(spacing: 3) {
                ForEach(FocusSeatClass.allCases) { seat in
                    let isSelected = !isCustomSeatSelected && (currentSeatCode == seat.rawValue)
                    SelectablePill(
                        title: seat.rawValue,
                        icon: seat.iconSymbol,
                        isSelected: isSelected,
                        helpText: "\(seat.title) (\(seat.seatCode)) — \(seat.cabinClass)"
                    ) {
                        onSelectStandardSeat(seat)
                    }
                }

                // Custom Seat Pill
                let isSelectedCustom = isCustomSeatSelected || (FocusSeatClass.find(code: currentSeatCode) == nil)
                SelectablePill(
                    title: customSeatCode.isEmpty ? "7X" : customSeatCode.uppercased(),
                    icon: customSeatIcon,
                    isSelected: isSelectedCustom,
                    helpText: "Custom Seat & Mission Objective"
                ) {
                    onSyncCustomSeat()
                }
            }

            // Expandable Custom Mission Deck
            if isCustomSeatSelected {
                CustomMissionInputRow(
                    seatCode: $customSeatCode,
                    taskTitle: $customTaskName,
                    showSetButton: false,
                    onCommit: onSyncCustomSeat
                )
                .padding(.top, 1)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .modifier(DispatchCardModifier())
    }

    // MARK: - Time Control Section

    @ViewBuilder
    private var timeControlSectionView: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("04 / TIME CONTROL (\(destinationAirport.code) · \(destinationAirport.cityName.uppercased()))")
                    .font(.system(size: 7.5, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.9))

                Spacer()

                Text("ETA \(arrivalTimeString)")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: 0xFF5C00))
            }

            // Duration Preset Pills
            HStack(spacing: 4) {
                ForEach([15, 25, 45, 60, 90], id: \.self) { mins in
                    let isSelected = (selectedDurationMinutes == mins)
                    SelectablePill(
                        title: "\(mins)M",
                        isSelected: isSelected,
                        helpText: "\(mins) Minutes Focus Flight"
                    ) {
                        onSaveDuration(mins)
                    }
                }
            }

            // Precision Stepper & Slider
            HStack(spacing: 6) {
                stepperButton(systemName: "minus", delta: -5)

                Slider(
                    value: Binding(
                        get: { Double(selectedDurationMinutes) },
                        set: { onSaveDuration(Int($0)) }
                    ),
                    in: 5...120,
                    step: 5
                )
                .tint(Color.white)

                stepperButton(systemName: "plus", delta: 5)

                Text("\(selectedDurationMinutes)M")
                    .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Color.white)
                    .frame(width: 32, alignment: .trailing)
            }

            // Telemetry Status Strip
            HStack {
                Text("\(routeDistanceNM) NM CORRIDOR")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(KaruTheme.textMuted)

                Spacer()

                Text("\(timezoneDeltaString) · \(destinationAirport.timeZoneCode)")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(KaruTheme.textSecondary)
            }
        }
        .modifier(DispatchCardModifier())
    }

    // MARK: - Corridor Airport Box

    @ViewBuilder
    private func corridorAirportBox(isOrigin: Bool) -> some View {
        let airport = isOrigin ? originAirport : destinationAirport
        let timeStr = isOrigin ? departureTimeString : destinationAirportLocalTimeString
        let header = isOrigin ? "01 / DEPARTURE" : "02 / DESTINATION"
        let accentColor = isOrigin ? Color.white : Color(hex: 0xFF5C00)
        let borderColor = isOrigin ? Color.white.opacity(0.06) : Color(hex: 0xFF5C00).opacity(0.2)
        let headerColor = isOrigin ? KaruTheme.textMuted : Color(hex: 0xFF5C00).opacity(0.85)

        Button {
            withAnimation(Animation.spring(response: 0.32, dampingFraction: 0.82)) {
                dispatchAirportTarget = isOrigin ? .origin : .destination
            }
        } label: {
            VStack(alignment: .leading, spacing: 1.5) {
                Text(header)
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundStyle(headerColor)

                HStack(spacing: 4) {
                    Text(airport.countryFlag)
                        .font(.system(size: 11))
                    Text(airport.code)
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundStyle(accentColor)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(isOrigin ? KaruTheme.textMuted : Color(hex: 0xFF5C00).opacity(0.6))
                }

                Text("\(airport.cityName) · \(timeStr)")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(KaruTheme.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(KaruTheme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .help(isOrigin ? "Change Departure Airport" : "Change Arrival Destination")
    }

    @ViewBuilder
    private func stepperButton(systemName: String, delta: Int) -> some View {
        Button {
            let target = min(180, max(5, selectedDurationMinutes + delta))
            onSaveDuration(target)
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 8, weight: .black))
                .foregroundStyle(Color.white)
                .frame(width: 20, height: 20)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
