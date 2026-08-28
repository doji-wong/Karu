import Foundation
import AVFoundation

/// Low-latency adaptive ambient audio engine backed by AVAudioEngine.
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

        // Generate synthetic ambient buffers
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

    // MARK: - Synthesized Audio Generator (Self-Contained Low-Frequency Soundscapes)

    private func loadVehicleBuffers(for vehicle: VehicleType) {
        let sampleRate: Double = 44100.0
        let durationSeconds: Double = 3.0
        let frameCount = AVAudioFrameCount(sampleRate * durationSeconds)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        // Synthesize cruise buffer (warm resonant harmonic hum + pink white noise)
        if let cBuf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) {
            cBuf.frameLength = frameCount
            let channels = Int(format.channelCount)
            let baseFreq = baseFrequency(for: vehicle)

            for ch in 0..<channels {
                guard let data = cBuf.floatChannelData?[ch] else { continue }
                for frame in 0..<Int(frameCount) {
                    let t = Double(frame) / sampleRate
                    // Harmonic drone
                    let drone = sin(2.0 * .pi * baseFreq * t) * 0.15
                    let sub = sin(2.0 * .pi * (baseFreq * 0.5) * t) * 0.1
                    // Gentle white noise texture
                    let noise = (Double.random(in: -1.0...1.0)) * 0.03
                    data[frame] = Float(drone + sub + noise)
                }
            }
            self.cruiseBuffer = cBuf
        }

        // Synthesize stall/idle buffer (lower frequency idle rumble)
        if let sBuf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) {
            sBuf.frameLength = frameCount
            let channels = Int(format.channelCount)

            for ch in 0..<channels {
                guard let data = sBuf.floatChannelData?[ch] else { continue }
                for frame in 0..<Int(frameCount) {
                    let t = Double(frame) / sampleRate
                    let idleRumble = sin(2.0 * .pi * 32.0 * t) * 0.12
                    let noise = (Double.random(in: -1.0...1.0)) * 0.02
                    data[frame] = Float(idleRumble + noise)
                }
            }
            self.stallBuffer = sBuf
        }
    }

    private func baseFrequency(for vehicle: VehicleType) -> Double {
        switch vehicle {
        case .midnightEV: return 55.0 // Smooth Electric Hum
        case .classicSarao: return 82.0 // Rhythmic Engine Rumble
        case .nightRainHatchback: return 65.0 // Lo-Fi Rain Drone
        case .shinkansenExpress: return 110.0 // High-Speed Wind/Rail
        case .coastalBus: return 73.0 // Highway Cruiser
        }
    }
}
