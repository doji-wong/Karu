import SwiftUI
import KaruCore

/// The vehicle selection hangar and ambient acoustic testbed.
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
        VStack(spacing: 18) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("THE GARAGE")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.navCyan)
                    Text("Select Your Focus Vehicle")
                        .font(KaruTheme.headerTitle)
                        .foregroundStyle(KaruTheme.textPrimary)
                }
                Spacer()
                Image(systemName: "car.2.fill")
                    .font(.title2)
                    .foregroundStyle(KaruTheme.textMuted)
            }

            Divider().background(KaruTheme.cardBorder)

            // Vehicle Cards List
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(VehicleType.allCases) { vehicle in
                        Button {
                            selectVehicle(vehicle)
                        } label: {
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(Color(hex: UInt(vehicle.themeColorHex.dropFirst().description, radix: 16) ?? 0x06B6D4))
                                    .frame(width: 12, height: 12)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(vehicle.name)
                                            .font(KaruTheme.headerTitle)
                                            .foregroundStyle(selectedVehicle == vehicle ? Color.white : KaruTheme.textPrimary)
                                        Spacer()
                                        if selectedVehicle == vehicle {
                                            Text("ACTIVE")
                                                .font(KaruTheme.captionMono)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(KaruTheme.cruiseEmerald)
                                                .foregroundStyle(Color.black)
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
                                    .stroke(selectedVehicle == vehicle ? KaruTheme.navCyan : KaruTheme.cardBorder, lineWidth: 1)
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
                Text("IN-FLIGHT AMBIENT SOUNDSCAPE")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.textSecondary)

                HStack {
                    Toggle("Enable Soundscape Audio", isOn: $isSoundEnabled)
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
        .frame(width: 440)
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
