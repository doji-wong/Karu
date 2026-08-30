import SwiftUI
import KaruCore

/// The aircraft selection hangar and in-flight acoustic testbed.
public struct GarageHangarView: View {
    @Bindable public var engine: TransitEngine
    public var audioEngine: AudioEngine
    public var storage: LocalStorageManager

    @State private var selectedVehicle: VehicleType
    @State private var isSoundEnabled: Bool = true
    @State private var ambientVolume: Double = 0.6

    public init(
        engine: TransitEngine,
        audioEngine: AudioEngine,
        storage: LocalStorageManager
    ) {
        self.engine = engine
        self.audioEngine = audioEngine
        self.storage = storage
        _selectedVehicle = State(initialValue: engine.activeVehicle)
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("THE AIRCRAFT HANGAR")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(Color(hex: 0xFF5C00))
                    Text("Select Your Focus Aircraft")
                        .font(KaruTheme.headerTitle)
                        .foregroundStyle(KaruTheme.textPrimary)
                }
                Spacer()
                Image(systemName: "airplane.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color(hex: 0xFF5C00))
            }

            Divider().background(KaruTheme.cardBorder)

            // Aircraft Fleet List
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(VehicleType.allCases) { vehicle in
                        Button {
                            selectVehicle(vehicle)
                        } label: {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(Color(hex: UInt(vehicle.themeColorHex.dropFirst().description, radix: 16) ?? 0xFF5C00))
                                    .frame(width: 12, height: 12)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(vehicle.name)
                                            .font(KaruTheme.headerTitle)
                                            .foregroundStyle(selectedVehicle == vehicle ? Color.white : KaruTheme.textPrimary)
                                        
                                        Text("(\(vehicle.aircraftCode))")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundStyle(Color.white.opacity(0.5))
                                        
                                        Spacer()
                                        if selectedVehicle == vehicle {
                                            Text("ACTIVE FLEET")
                                                .font(KaruTheme.captionMono)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color(hex: 0xFF5C00))
                                                .foregroundStyle(Color.white)
                                                .clipShape(Capsule())
                                        }
                                    }

                                    Text(vehicle.subtitle)
                                        .font(KaruTheme.captionMono)
                                        .foregroundStyle(KaruTheme.textSecondary)

                                    Text(vehicle.description)
                                        .font(.system(size: 11))
                                        .foregroundStyle(KaruTheme.textMuted)
                                        .lineLimit(2)
                                }
                            }
                            .padding(12)
                            .background(selectedVehicle == vehicle ? KaruTheme.surfaceElevated : KaruTheme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedVehicle == vehicle ? Color(hex: 0xFF5C00) : KaruTheme.cardBorder, lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 280)

            Divider().background(KaruTheme.cardBorder)

            // Audio Tuning Controls
            VStack(alignment: .leading, spacing: 10) {
                Text("IN-FLIGHT CABIN AMBIENT SOUNDSCAPE")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.textSecondary)

                HStack {
                    Toggle("Enable Cabin Jet Audio", isOn: $isSoundEnabled)
                        .onChange(of: isSoundEnabled) { _, newValue in
                            audioEngine.setMuted(!newValue)
                        }

                    Spacer()

                    Slider(value: $ambientVolume, in: 0.0...1.0) {
                        Text("Volume")
                    }
                    .frame(width: 100)
                    .onChange(of: ambientVolume) { _, newValue in
                        audioEngine.masterVolume = Float(newValue)
                    }
                }
                .font(KaruTheme.subheadline)
            }
        }
        .padding(20)
        .frame(width: 460)
        .background(KaruTheme.background)
        .onAppear {
            let saved = storage.loadVehicleProfile()
            self.selectedVehicle = saved.type
            self.isSoundEnabled = saved.isSoundEnabled
            self.ambientVolume = saved.ambientVolume
        }
    }

    private func selectVehicle(_ vehicle: VehicleType) {
        selectedVehicle = vehicle
        audioEngine.setVehicle(vehicle)
        
        let profile = VehicleProfile(type: vehicle, isSoundEnabled: isSoundEnabled, ambientVolume: ambientVolume)
        try? storage.saveVehicleProfile(profile)
    }
}

