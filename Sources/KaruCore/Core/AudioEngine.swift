import Foundation
import AVFoundation

/// Low-latency adaptive in-flight ambient audio engine backed by AVAudioEngine.
///
/// Produces realistic FocusFlight aviation soundscapes:
/// - **Cruising (On Time):** Layered high-altitude jet cabin hum + soothing conditioned airflow pink noise + turbine harmonics.
///   Each aircraft has distinct acoustics (A350 Trent hum, Dreamliner rain atmosphere, Concorde Mach rush, G650 whisper, Cessna prop).
/// - **In Turbulence (Distraction Hazard):** Atmospheric wind buffet + air pocket shudder + cabin seatbelt sign alert.
/// - **Seatbelt Chime:** Authentic dual-tone "Ding-Dong" chime on takeoff, turbulence, and touchdown.
/// - **Crossfade:** 400ms smooth transition between cruise and turbulence states.
@MainActor
public final class AudioEngine {
    
    // MARK: - Audio Nodes
    private let engine = AVAudioEngine()
    private let cruisePlayerNode = AVAudioPlayerNode()
    private let stallPlayerNode = AVAudioPlayerNode()
    private let chimePlayerNode = AVAudioPlayerNode()
    private let mixerNode = AVAudioMixerNode()
    
    // State properties
    public private(set) var isRunning: Bool = false
    public private(set) var isMuted: Bool = false
    public var masterVolume: Float = 0.6 {
        didSet {
            updateMixerVolume()
        }
    }
    
    public private(set) var currentVehicle: VehicleType = .midnightEV
    public private(set) var currentTransitState: TransitState = .idle
    
    // Audio buffers
    private var cruiseBuffer: AVAudioPCMBuffer?
    private var stallBuffer: AVAudioPCMBuffer?
    private var seatbeltChimeBuffer: AVAudioPCMBuffer?
    
    // Crossfade timer / task
    private var crossfadeTask: Task<Void, Never>?

    public init() {
        setupAudioPipeline()
    }

    // MARK: - Pipeline Setup

    private func setupAudioPipeline() {
        engine.attach(cruisePlayerNode)
        engine.attach(stallPlayerNode)
        engine.attach(chimePlayerNode)
        engine.attach(mixerNode)

        let standardFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!

        engine.connect(cruisePlayerNode, to: mixerNode, format: standardFormat)
        engine.connect(stallPlayerNode, to: mixerNode, format: standardFormat)
        engine.connect(chimePlayerNode, to: mixerNode, format: standardFormat)
        engine.connect(mixerNode, to: engine.mainMixerNode, format: standardFormat)

        // Set initial volumes
        cruisePlayerNode.volume = 0.0
        stallPlayerNode.volume = 0.0
        chimePlayerNode.volume = 0.8
        mixerNode.outputVolume = masterVolume

        // Generate aircraft-specific ambient buffers & chimes
        loadAircraftBuffers(for: currentVehicle)
        generateSeatbeltChimeBuffer()
    }

    // MARK: - Lifecycle Controls

    /// Start ambient in-flight audio engine playback.
    public func start() {
        guard !isRunning else { return }

        do {
            if !engine.isRunning {
                try engine.start()
            }
            isRunning = true
            scheduleLoops()
            playSeatbeltChime()
            updateState(currentTransitState, animated: false)
        } catch {
            print("[FocusFlightAudio] Failed to start AVAudioEngine: \(error)")
        }
    }

    /// Stop ambient audio engine playback.
    public func stop() {
        guard isRunning else { return }
        isRunning = false
        crossfadeTask?.cancel()
        cruisePlayerNode.stop()
        stallPlayerNode.stop()
        chimePlayerNode.stop()
        engine.stop()
    }

    /// Mute / unmute audio output.
    public func toggleMute() {
        isMuted.toggle()
        updateMixerVolume()
    }

    public func setMuted(_ muted: Bool) {
        isMuted = muted
        updateMixerVolume()
    }

    /// Play the classic dual-tone airplane seatbelt sign chime ("Ding-Dong").
    public func playSeatbeltChime() {
        guard isRunning, !isMuted, let chimeBuf = seatbeltChimeBuffer else { return }
        chimePlayerNode.stop()
        chimePlayerNode.scheduleBuffer(chimeBuf, at: nil, options: [], completionHandler: nil)
        chimePlayerNode.play()
    }

    // MARK: - State Transitions & 400ms Crossfade

    /// Adapt audio soundscape to the new transit state (On Time vs In Turbulence).
    public func updateState(_ state: TransitState, animated: Bool = true) {
        let previousState = self.currentTransitState
        self.currentTransitState = state
        guard isRunning else { return }

        // Play chime on entering turbulence or touchdown
        if (previousState == .cruising && state == .trafficStalled) || state == .completed {
            playSeatbeltChime()
        }

        let targetCruiseVol: Float
        let targetStallVol: Float

        switch state {
        case .cruising:
            targetCruiseVol = 1.0
            targetStallVol = 0.0
        case .trafficStalled:
            targetCruiseVol = 0.0
            targetStallVol = 1.0
        case .idle, .pitStop, .completed:
            targetCruiseVol = 0.0
            targetStallVol = 0.0
        }

        if animated {
            performCrossfade(targetCruise: targetCruiseVol, targetStall: targetStallVol, durationMs: 400)
        } else {
            cruisePlayerNode.volume = targetCruiseVol
            stallPlayerNode.volume = targetStallVol
        }
    }

    /// Change active aircraft soundscape.
    public func setVehicle(_ vehicle: VehicleType) {
        self.currentVehicle = vehicle
        loadAircraftBuffers(for: vehicle)
        if isRunning {
            scheduleLoops()
        }
    }

    // MARK: - Volume & Crossfade Implementation

    private func updateMixerVolume() {
        mixerNode.outputVolume = isMuted ? 0.0 : masterVolume
    }

    private func performCrossfade(targetCruise: Float, targetStall: Float, durationMs: Int) {
        crossfadeTask?.cancel()

        let startCruise = cruisePlayerNode.volume
        let startStall = stallPlayerNode.volume
        let steps = 20
        let stepIntervalNs = UInt64((durationMs * 1_000_000) / steps)

        crossfadeTask = Task { @MainActor in
            for i in 1...steps {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(nanoseconds: stepIntervalNs)
                guard !Task.isCancelled else { return }

                let progress = Float(i) / Float(steps)
                self.cruisePlayerNode.volume = startCruise + (targetCruise - startCruise) * progress
                self.stallPlayerNode.volume = startStall + (targetStall - startStall) * progress
            }
        }
    }

    private func scheduleLoops() {
        guard let cBuf = cruiseBuffer, let sBuf = stallBuffer else { return }

        cruisePlayerNode.stop()
        stallPlayerNode.stop()

        cruisePlayerNode.scheduleBuffer(cBuf, at: nil, options: .loops, completionHandler: nil)
        stallPlayerNode.scheduleBuffer(sBuf, at: nil, options: .loops, completionHandler: nil)

        cruisePlayerNode.play()
        stallPlayerNode.play()
    }

    // MARK: - Aviation In-Flight Audio Synthesis

    private func loadAircraftBuffers(for aircraft: VehicleType) {
        let sampleRate: Double = 44100.0
        let durationSeconds: Double = 5.0
        let frameCount = AVAudioFrameCount(sampleRate * durationSeconds)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        // ── 1. Cruise Buffer: High-Altitude Cabin Air & Turbofan Drone ──
        if let cBuf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) {
            cBuf.frameLength = frameCount
            let channels = Int(format.channelCount)
            let params = aircraftParams(for: aircraft)

            for ch in 0..<channels {
                guard let data = cBuf.floatChannelData?[ch] else { continue }
                for frame in 0..<Int(frameCount) {
                    let t = Double(frame) / sampleRate
                    var sample: Double = 0.0

                    // Layer A: Low-frequency turbofan drone (55 - 90 Hz)
                    let fanPhase = 2.0 * .pi * params.engineFreq * t
                    let fanDrone = sin(fanPhase) * params.engineLevel
                    let fanHarmonic = sin(fanPhase * 2.0) * params.engineLevel * 0.35
                    // Subtle cabin acoustic modulation (breathing air pressure)
                    let pressureMod = sin(2.0 * .pi * 0.15 * t) * 0.03
                    sample += (fanDrone + fanHarmonic) * (1.0 + pressureMod)

                    // Layer B: Soothing conditioned cabin airflow (pink noise)
                    let airFlow = pinkNoise(frame: frame, ch: ch, seed: 101) * params.cabinAirLevel
                    sample += airFlow

                    // Layer C: High-altitude broadband white noise (sound-dampened hull)
                    let hullDampening = brownNoise(frame: frame, ch: ch, seed: 202) * params.hullRumbleLevel
                    sample += hullDampening

                    // Layer D: Aircraft-specific acoustic character layer
                    sample += params.characterLayer(t, frame, ch)

                    // Master soft limiting
                    data[frame] = Float(max(-0.95, min(0.95, sample)))
                }
            }
            self.cruiseBuffer = cBuf
        }

        // ── 2. Stall Buffer: Atmospheric Turbulence & Air Buffet ──
        if let sBuf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) {
            sBuf.frameLength = frameCount
            let channels = Int(format.channelCount)

            for ch in 0..<channels {
                guard let data = sBuf.floatChannelData?[ch] else { continue }
                for frame in 0..<Int(frameCount) {
                    let t = Double(frame) / sampleRate
                    var sample: Double = 0.0

                    // Layer A: Low-frequency airframe shudder (18-32 Hz air pocket rumble)
                    let pocketFreq = 22.0 + sin(2.0 * .pi * 0.6 * t) * 8.0
                    let airPocketRumble = sin(2.0 * .pi * pocketFreq * t) * 0.16
                    sample += airPocketRumble

                    // Layer B: Atmospheric crosswind shear (periodic wind buffet sweeps)
                    let windSweep = sin(2.0 * .pi * 0.35 * t)
                    let buffetIntensity = max(0.0, windSweep)
                    let windBuffet = pinkNoise(frame: frame, ch: ch, seed: 303) * 0.22 * buffetIntensity
                    sample += windBuffet

                    // Layer C: Hull shudder impulse (sporadic bumps)
                    let bumpImpulse = sin(2.0 * .pi * 1.8 * t) > 0.88 ? brownNoise(frame: frame, ch: ch, seed: 404) * 0.12 : 0.0
                    sample += bumpImpulse

                    // Layer D: Continuous cockpit air rush
                    let cockpitRush = brownNoise(frame: frame, ch: ch, seed: 505) * 0.08
                    sample += cockpitRush

                    data[frame] = Float(max(-0.95, min(0.95, sample)))
                }
            }
            self.stallBuffer = sBuf
        }
    }

    // MARK: - Dual-Tone Airplane Seatbelt Chime Generator

    private func generateSeatbeltChimeBuffer() {
        let sampleRate: Double = 44100.0
        let durationSeconds: Double = 1.6
        let frameCount = AVAudioFrameCount(sampleRate * durationSeconds)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        guard let chimeBuf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        chimeBuf.frameLength = frameCount
        let channels = Int(format.channelCount)

        // Classic Boeing / Airbus Chime: High Tone (D5 587.33 Hz) -> Low Tone (A4 440.00 Hz)
        for ch in 0..<channels {
            guard let data = chimeBuf.floatChannelData?[ch] else { continue }
            for frame in 0..<Int(frameCount) {
                let t = Double(frame) / sampleRate
                var sample: Double = 0.0

                // Tone 1: High Bell D5 (0.0s to 0.7s)
                if t < 0.7 {
                    let decay1 = exp(-t * 5.5) // Smooth exponential bell ring
                    let tone1 = sin(2.0 * .pi * 587.33 * t) * 0.25 * decay1
                    let overtone1 = sin(2.0 * .pi * 1174.66 * t) * 0.08 * decay1
                    sample += tone1 + overtone1
                }

                // Tone 2: Low Bell A4 (0.28s to 1.6s)
                if t >= 0.28 {
                    let t2 = t - 0.28
                    let decay2 = exp(-t2 * 4.5)
                    let tone2 = sin(2.0 * .pi * 440.00 * t2) * 0.28 * decay2
                    let overtone2 = sin(2.0 * .pi * 880.00 * t2) * 0.09 * decay2
                    sample += tone2 + overtone2
                }

                data[frame] = Float(max(-0.95, min(0.95, sample)))
            }
        }
        self.seatbeltChimeBuffer = chimeBuf
    }

    // MARK: - Aircraft Acoustic Sound Profiles

    private struct AircraftAudioParams {
        let engineFreq: Double
        let engineLevel: Double
        let cabinAirLevel: Double
        let hullRumbleLevel: Double
        let characterLayer: (Double, Int, Int) -> Double
    }

    private func aircraftParams(for aircraft: VehicleType) -> AircraftAudioParams {
        switch aircraft {
        case .midnightEV:
            // Airbus A350F: Quiet carbon-composite cabin + Rolls-Royce Trent XWB turbofan hum
            return AircraftAudioParams(
                engineFreq: 58.0,
                engineLevel: 0.10,
                cabinAirLevel: 0.12,
                hullRumbleLevel: 0.06,
                characterLayer: { t, _, _ in
                    // High-bypass turbine blade harmonic (soothing 420 Hz hum)
                    let turbine = sin(2.0 * .pi * 420.0 * t) * 0.02
                    return turbine
                }
            )

        case .classicSarao:
            // Boeing 787-9 Dreamliner: Serene acoustic cabin dampening + gentle high-altitude mist
            return AircraftAudioParams(
                engineFreq: 64.0,
                engineLevel: 0.12,
                cabinAirLevel: 0.14,
                hullRumbleLevel: 0.05,
                characterLayer: { t, frame, ch in
                    // Gentle high-altitude rain / mist whisper
                    let mist = self.pinkNoise(frame: frame, ch: ch, seed: 12) * 0.025
                    return mist
                }
            )

        case .nightRainHatchback:
            // Concorde SST: Supersonic delta-wing airflow rush + Olympus turbojet thrust
            return AircraftAudioParams(
                engineFreq: 88.0,
                engineLevel: 0.16,
                cabinAirLevel: 0.18,
                hullRumbleLevel: 0.08,
                characterLayer: { t, frame, ch in
                    // Supersonic Mach 2.0 aerodynamic wave
                    let machRush = self.pinkNoise(frame: frame, ch: ch, seed: 34) * 0.06
                    return machRush
                }
            )

        case .shinkansenExpress:
            // Gulfstream G650: Whisper-quiet executive jet FL450 cruising air
            return AircraftAudioParams(
                engineFreq: 72.0,
                engineLevel: 0.07,
                cabinAirLevel: 0.09,
                hullRumbleLevel: 0.04,
                characterLayer: { t, _, _ in
                    let whisper = sin(2.0 * .pi * 510.0 * t) * 0.015
                    return whisper
                }
            )

        case .coastalBus:
            // Cessna 172 Skyhawk: Lycoming 4-cylinder rhythmic propeller drone
            return AircraftAudioParams(
                engineFreq: 42.0,
                engineLevel: 0.20,
                cabinAirLevel: 0.08,
                hullRumbleLevel: 0.05,
                characterLayer: { t, frame, ch in
                    // Propeller blade thrum (2-blade prop at 2400 RPM = 80 Hz beat)
                    let propBeat = sin(2.0 * .pi * 80.0 * t) * 0.06
                    return propBeat
                }
            )
        }
    }

    // MARK: - Noise Synthesizers

    private func brownNoise(frame: Int, ch: Int, seed: Int) -> Double {
        let idx = frame &+ (ch &* 44100) &+ (seed &* 17389)
        let raw = Double((idx &* 1103515245 &+ 12345) & 0x7fffffff) / Double(0x7fffffff)
        let white = (raw * 2.0 - 1.0)
        return white * 0.5
    }

    private func pinkNoise(frame: Int, ch: Int, seed: Int) -> Double {
        let idx = frame &+ (ch &* 44100) &+ (seed &* 31337)
        let raw = Double((idx &* 214013 &+ 2531011) & 0x7fffffff) / Double(0x7fffffff)
        return (raw * 2.0 - 1.0) * 0.7
    }
}
