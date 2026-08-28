import Foundation
import AVFoundation

/// Low-latency adaptive ambient audio engine backed by AVAudioEngine.
///
/// Produces realistic vehicle driving soundscapes:
/// - **Cruising:** Layered engine drone + tire road noise + subtle wind texture. Each vehicle has
///   distinct engine characteristics (EV whine, diesel rumble, rain patter, rail hum, bus rumble).
/// - **Traffic Gridlock:** Chaotic horn honking chorus + idling engine + brake squeals + crowd murmur.
/// - **Crossfade:** 400ms smooth transition between cruise and gridlock states.
@MainActor
public final class AudioEngine {
    
    // MARK: - Audio Nodes
    private let engine = AVAudioEngine()
    private let cruisePlayerNode = AVAudioPlayerNode()
    private let stallPlayerNode = AVAudioPlayerNode()
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
    
    // Crossfade timer / task
    private var crossfadeTask: Task<Void, Never>?

    public init() {
        setupAudioPipeline()
    }

    // MARK: - Pipeline Setup

    private func setupAudioPipeline() {
        engine.attach(cruisePlayerNode)
        engine.attach(stallPlayerNode)
        engine.attach(mixerNode)

        let standardFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)!

        engine.connect(cruisePlayerNode, to: mixerNode, format: standardFormat)
        engine.connect(stallPlayerNode, to: mixerNode, format: standardFormat)
        engine.connect(mixerNode, to: engine.mainMixerNode, format: standardFormat)

        // Set initial volumes
        cruisePlayerNode.volume = 0.0
        stallPlayerNode.volume = 0.0
        mixerNode.outputVolume = masterVolume

        // Generate vehicle-specific ambient buffers
        loadVehicleBuffers(for: currentVehicle)
    }

    // MARK: - Lifecycle Controls

    /// Start ambient audio engine playback.
    public func start() {
        guard !isRunning else { return }

        do {
            if !engine.isRunning {
                try engine.start()
            }
            isRunning = true
            scheduleLoops()
            updateState(currentTransitState, animated: false)
        } catch {
            print("[KaruAudio] Failed to start AVAudioEngine: \(error)")
        }
    }

    /// Stop ambient audio engine playback.
    public func stop() {
        guard isRunning else { return }
        isRunning = false
        crossfadeTask?.cancel()
        cruisePlayerNode.stop()
        stallPlayerNode.stop()
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

    // MARK: - State Transitions & 400ms Crossfade

    /// Adapt audio soundscape to the new transit state (Cruising vs Traffic Gridlock).
    public func updateState(_ state: TransitState, animated: Bool = true) {
        self.currentTransitState = state
        guard isRunning else { return }

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

    /// Change active vehicle soundscape.
    public func setVehicle(_ vehicle: VehicleType) {
        self.currentVehicle = vehicle
        loadVehicleBuffers(for: vehicle)
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

    // MARK: - Realistic Vehicle Audio Synthesis

    private func loadVehicleBuffers(for vehicle: VehicleType) {
        let sampleRate: Double = 44100.0
        let durationSeconds: Double = 4.0  // Longer loop for more natural feel
        let frameCount = AVAudioFrameCount(sampleRate * durationSeconds)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        // ── Cruise Buffer: Realistic Moving Vehicle Sound ──
        if let cBuf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) {
            cBuf.frameLength = frameCount
            let channels = Int(format.channelCount)
            let params = vehicleParams(for: vehicle)

            for ch in 0..<channels {
                guard let data = cBuf.floatChannelData?[ch] else { continue }
                for frame in 0..<Int(frameCount) {
                    let t = Double(frame) / sampleRate
                    var sample: Double = 0.0

                    // Layer 1: Engine fundamental drone (vehicle-specific frequency)
                    let enginePhase = 2.0 * .pi * params.engineFreq * t
                    let engineDrone = sin(enginePhase) * params.engineLevel
                    // Engine harmonic overtones for richness
                    let harmonic2 = sin(enginePhase * 2.0) * params.engineLevel * 0.35
                    let harmonic3 = sin(enginePhase * 3.0) * params.engineLevel * 0.15
                    // Subtle RPM fluctuation to prevent monotony
                    let rpmWobble = sin(2.0 * .pi * 0.7 * t) * 0.02
                    sample += (engineDrone + harmonic2 + harmonic3) * (1.0 + rpmWobble)

                    // Layer 2: Tire/Road noise (filtered broadband noise)
                    let roadNoise = brownNoise(frame: frame, ch: ch, seed: 1) * params.roadNoiseLevel
                    sample += roadNoise

                    // Layer 3: Wind / Aero noise (high-pass filtered noise at speed)
                    let windNoise = pinkNoise(frame: frame, ch: ch, seed: 2) * params.windLevel
                    sample += windNoise

                    // Layer 4: Vehicle-specific character layer
                    sample += params.characterLayer(t, frame, ch)

                    // Soft limiting
                    data[frame] = Float(max(-0.95, min(0.95, sample)))
                }
            }
            self.cruiseBuffer = cBuf
        }

        // ── Stall Buffer: Traffic Gridlock Chaos ──
        if let sBuf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) {
            sBuf.frameLength = frameCount
            let channels = Int(format.channelCount)

            for ch in 0..<channels {
                guard let data = sBuf.floatChannelData?[ch] else { continue }
                for frame in 0..<Int(frameCount) {
                    let t = Double(frame) / sampleRate
                    var sample: Double = 0.0

                    // Layer 1: Idling engine rumble (low, rough)
                    let idleFreq = 28.0 + sin(2.0 * .pi * 0.3 * t) * 4.0 // Irregular idle
                    let idleRumble = sin(2.0 * .pi * idleFreq * t) * 0.10
                    let idleHarmonics = sin(2.0 * .pi * idleFreq * 2.0 * t) * 0.04
                    sample += idleRumble + idleHarmonics

                    // Layer 2: Horn honking chorus (multiple horns at staggered intervals)
                    let horn1Active = hornPulse(t: t, period: 2.8, onDuration: 0.6, offset: 0.0)
                    let horn1 = sin(2.0 * .pi * 440.0 * t) * 0.18 * horn1Active  // Classic car horn A4

                    let horn2Active = hornPulse(t: t, period: 3.5, onDuration: 0.35, offset: 1.2)
                    let horn2 = sin(2.0 * .pi * 349.0 * t) * 0.14 * horn2Active  // Lower F4 truck horn

                    let horn3Active = hornPulse(t: t, period: 1.8, onDuration: 0.2, offset: 0.5)
                    let horn3 = sin(2.0 * .pi * 587.0 * t) * 0.10 * horn3Active  // Higher D5 scooter beep

                    // Dual-tone horn (like a bus/truck)
                    let horn4Active = hornPulse(t: t, period: 4.0, onDuration: 1.2, offset: 2.0)
                    let horn4a = sin(2.0 * .pi * 370.0 * t) * 0.12 * horn4Active
                    let horn4b = sin(2.0 * .pi * 494.0 * t) * 0.10 * horn4Active

                    sample += horn1 + horn2 + horn3 + horn4a + horn4b

                    // Layer 3: Brake squeal (intermittent high-pitched)
                    let brakeActive = hornPulse(t: t, period: 5.0, onDuration: 0.15, offset: 3.0)
                    let brakeSweep = 2800.0 + sin(2.0 * .pi * 3.0 * t) * 400.0
                    let brake = sin(2.0 * .pi * brakeSweep * t) * 0.04 * brakeActive
                    sample += brake

                    // Layer 4: Crowd / ambient murmur (filtered noise)
                    let crowdMurmur = brownNoise(frame: frame, ch: ch, seed: 3) * 0.04
                    sample += crowdMurmur

                    // Layer 5: Distant engine revving (other cars in gridlock)
                    let revFreq = 60.0 + sin(2.0 * .pi * 0.8 * t) * 20.0
                    let distantRev = sin(2.0 * .pi * revFreq * t) * 0.06
                    sample += distantRev

                    // Soft limiting
                    data[frame] = Float(max(-0.95, min(0.95, sample)))
                }
            }
            self.stallBuffer = sBuf
        }
    }

    // MARK: - Vehicle Sound Profiles

    private struct VehicleAudioParams {
        let engineFreq: Double
        let engineLevel: Double
        let roadNoiseLevel: Double
        let windLevel: Double
        let characterLayer: (Double, Int, Int) -> Double  // (time, frame, channel) -> sample
    }

    private func vehicleParams(for vehicle: VehicleType) -> VehicleAudioParams {
        switch vehicle {
        case .midnightEV:
            // Electric vehicle: High-pitched inverter whine + minimal engine, strong tire noise
            return VehicleAudioParams(
                engineFreq: 220.0,
                engineLevel: 0.06,
                roadNoiseLevel: 0.08,
                windLevel: 0.05,
                characterLayer: { t, _, _ in
                    // EV inverter whine (sweeping high frequency)
                    let whineFreq = 1200.0 + sin(2.0 * .pi * 0.4 * t) * 200.0
                    return sin(2.0 * .pi * whineFreq * t) * 0.03
                }
            )

        case .classicSarao:
            // Diesel jeepney: Rough, low rumble with mechanical clatter
            return VehicleAudioParams(
                engineFreq: 55.0,
                engineLevel: 0.20,
                roadNoiseLevel: 0.06,
                windLevel: 0.03,
                characterLayer: { t, frame, ch in
                    // Diesel knock / mechanical clatter
                    let knockFreq = 110.0
                    let knockEnv = max(0.0, sin(2.0 * .pi * 12.0 * t)) // Percussive envelope
                    let knock = sin(2.0 * .pi * knockFreq * t) * 0.08 * knockEnv
                    // Exhaust pop texture
                    let exhaust = self.pinkNoise(frame: frame, ch: ch, seed: 5) * 0.04
                    return knock + exhaust
                }
            )

        case .nightRainHatchback:
            // Lo-fi rain hatchback: Moderate engine + rain patter on roof/windshield
            return VehicleAudioParams(
                engineFreq: 82.0,
                engineLevel: 0.12,
                roadNoiseLevel: 0.07,
                windLevel: 0.04,
                characterLayer: { t, frame, ch in
                    // Rain patter (sparse high-frequency impulses)
                    let rainDensity = 0.015
                    let rainDrop = Double.random(in: 0.0...1.0) < rainDensity
                        ? Double.random(in: 0.3...1.0) * sin(2.0 * .pi * Double.random(in: 3000...6000) * t) * 0.06
                        : 0.0
                    // Windshield wiper sweep (periodic whoosh)
                    let wiperActive = sin(2.0 * .pi * 0.25 * t) > 0.85
                    let wiperWhoosh = wiperActive ? self.pinkNoise(frame: frame, ch: ch, seed: 6) * 0.05 : 0.0
                    return rainDrop + wiperWhoosh
                }
            )

        case .shinkansenExpress:
            // Bullet train: High-speed wind + rail clatter + electric motor whine
            return VehicleAudioParams(
                engineFreq: 160.0,
                engineLevel: 0.08,
                roadNoiseLevel: 0.02,
                windLevel: 0.10,
                characterLayer: { t, frame, ch in
                    // Rail joint clatter (periodic rhythmic thumps)
                    let railPeriod = 0.8  // Rail joints every 0.8s at high speed
                    let railPhase = t.truncatingRemainder(dividingBy: railPeriod) / railPeriod
                    let railClatter = railPhase < 0.05
                        ? sin(2.0 * .pi * 95.0 * t) * 0.12
                        : 0.0
                    // Traction motor whine
                    let motorFreq = 800.0 + sin(2.0 * .pi * 0.15 * t) * 50.0
                    let motorWhine = sin(2.0 * .pi * motorFreq * t) * 0.04
                    return railClatter + motorWhine
                }
            )

        case .coastalBus:
            // Heavy diesel bus: Deep rumble + air brake hiss + bus-specific vibration
            return VehicleAudioParams(
                engineFreq: 45.0,
                engineLevel: 0.18,
                roadNoiseLevel: 0.06,
                windLevel: 0.04,
                characterLayer: { t, frame, ch in
                    // Bus body vibration/resonance
                    let bodyRes = sin(2.0 * .pi * 22.0 * t) * 0.05
                    // Intermittent air brake release hiss
                    let hissActive = sin(2.0 * .pi * 0.12 * t) > 0.92
                    let airHiss = hissActive ? self.pinkNoise(frame: frame, ch: ch, seed: 7) * 0.08 : 0.0
                    return bodyRes + airHiss
                }
            )
        }
    }

    // MARK: - Noise Generators

    /// Brown noise (random walk filtered) for road rumble and crowd murmur.
    private func brownNoise(frame: Int, ch: Int, seed: Int) -> Double {
        // Deterministic-ish brown noise using a simple LCG
        let idx = frame &+ (ch &* 44100) &+ (seed &* 17389)
        let raw = Double((idx &* 1103515245 &+ 12345) & 0x7fffffff) / Double(0x7fffffff)
        let white = (raw * 2.0 - 1.0)
        // Simple first-order lowpass for brownish character
        return white * 0.5
    }

    /// Pink noise approximation for wind and texture.
    private func pinkNoise(frame: Int, ch: Int, seed: Int) -> Double {
        let idx = frame &+ (ch &* 44100) &+ (seed &* 31337)
        let raw = Double((idx &* 214013 &+ 2531011) & 0x7fffffff) / Double(0x7fffffff)
        return (raw * 2.0 - 1.0) * 0.7
    }

    /// Horn pulse envelope: returns 1.0 when horn is active, 0.0 when silent.
    private func hornPulse(t: Double, period: Double, onDuration: Double, offset: Double) -> Double {
        let phase = (t + offset).truncatingRemainder(dividingBy: period)
        if phase < onDuration {
            // Smooth attack/release envelope
            let attack = min(1.0, phase / 0.02)
            let release = min(1.0, (onDuration - phase) / 0.02)
            return min(attack, release)
        }
        return 0.0
    }
}
