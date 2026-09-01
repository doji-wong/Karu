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
    
    // Cabin PA Announcement Synthesizer
    private let speechSynthesizer = AVSpeechSynthesizer()
    public var isAnnouncementsEnabled: Bool = true
    
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
        chimePlayerNode.volume = 1.0
        mixerNode.outputVolume = isMuted ? 0.0 : masterVolume

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
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        engine.stop()
    }

    /// Mute / unmute audio output.
    public func toggleMute() {
        isMuted.toggle()
        updateMixerVolume()
        if isMuted && speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    public func setMuted(_ muted: Bool) {
        isMuted = muted
        updateMixerVolume()
        if isMuted && speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }

    /// Play the classic dual-tone airplane seatbelt sign chime ("Ding-Dong").
    public func playSeatbeltChime() {
        if !isRunning {
            start()
        }
        guard isRunning, !isMuted, let chimeBuf = seatbeltChimeBuffer else { return }
        chimePlayerNode.stop()
        chimePlayerNode.scheduleBuffer(chimeBuf, at: nil, options: [], completionHandler: nil)
        chimePlayerNode.play()
    }

    // MARK: - Cabin PA Voice Announcements

    /// Speak a cabin PA announcement with calm pilot voice parameters.
    public func speakAnnouncement(_ text: String, playChime: Bool = true) {
        guard !isMuted && isAnnouncementsEnabled else { return }
        
        if playChime {
            playSeatbeltChime()
        }
        
        Task { @MainActor in
            if playChime {
                try? await Task.sleep(nanoseconds: 650_000_000) // 650ms after chime starts
            }
            guard !self.isMuted && self.isAnnouncementsEnabled else { return }
            
            if self.speechSynthesizer.isSpeaking {
                self.speechSynthesizer.stopSpeaking(at: .immediate)
            }
            
            let utterance = AVSpeechUtterance(string: text)
            if let voice = AVSpeechSynthesisVoice(language: "en-US") {
                utterance.voice = voice
            }
            utterance.rate = 0.48
            utterance.pitchMultiplier = 0.95
            utterance.volume = min(1.0, max(0.4, self.masterVolume))
            
            self.speechSynthesizer.speak(utterance)
        }
    }

    /// Announce flight takeoff and initial cruise with destination, seat, and focus task mode.
    public func announceTakeoff(destinationCity: String, seatCode: String = "5F", taskTitle: String = "Deep Work") {
        let cleanSeat = seatCode.replacingOccurrences(of: "Seat ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanTask = taskTitle.replacingOccurrences(of: "MODE", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let text = "Welcome aboard Flight FL 288 to \(destinationCity). Cruising altitude reached in Seat \(cleanSeat) for \(cleanTask). Focus flight engaged."
        speakAnnouncement(text, playChime: true)
    }

    /// Announce flight landing / touchdown.
    public func announceTouchdown(destinationCity: String) {
        let text = "Ladies and gentlemen, touchdown in \(destinationCity). Certified focus flight completed. Thank you for flying Karu."
        speakAnnouncement(text, playChime: true)
    }

    /// Announce gate hold or cruise resumption.
    public func announceGateHold(isHolding: Bool) {
        let text = isHolding ? "Flight paused for gate hold." : "Resuming flight cruise."
        speakAnnouncement(text, playChime: false)
    }

    /// Announce turbulence warning.
    public func announceTurbulence() {
        let text = "Caution, turbulence detected. Return to approved focus workspaces."
        speakAnnouncement(text, playChime: true)
    }

    // MARK: - State Transitions & 400ms Crossfade

    /// Adapt audio soundscape to the new transit state (On Time vs In Turbulence).
    public func updateState(_ state: TransitState, animated: Bool = true) {
        let previousState = self.currentTransitState
        self.currentTransitState = state

        if (state == .cruising || state == .trafficStalled) && !isRunning {
            start()
        }
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
        let durationSeconds: Double = 4.0
        let frameCount = AVAudioFrameCount(sampleRate * durationSeconds)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        // ── 1. Cruise Buffer: High-Altitude Cabin Air & Turbofan Drone ──
        if let cBuf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) {
            cBuf.frameLength = frameCount
            let channels = Int(format.channelCount)
            let params = aircraftParams(for: aircraft)

            for ch in 0..<channels {
                guard let data = cBuf.floatChannelData?[ch] else { continue }
                var pinkState1 = 0.0
                var pinkState2 = 0.0
                var brownState = 0.0
                var seed = UInt32(ch * 7919 + 104729)

                for frame in 0..<Int(frameCount) {
                    let t = Double(frame) / sampleRate

                    // White noise source
                    seed = seed &* 1664525 &+ 1013904223
                    let white = (Double(seed) / Double(UInt32.max)) * 2.0 - 1.0

                    // Pink noise filter (2-pole gentle lowpass) for conditioned air rush
                    pinkState1 = 0.82 * pinkState1 + 0.18 * white
                    pinkState2 = 0.82 * pinkState2 + 0.18 * pinkState1
                    let cabinAir = pinkState2 * params.cabinAirLevel

                    // Brown noise filter (deep hull rumble)
                    brownState = 0.985 * brownState + 0.015 * white
                    let hullRumble = brownState * params.hullRumbleLevel

                    // Turbofan drone harmonics
                    let f0 = params.engineFreq
                    let fan1 = sin(2.0 * .pi * f0 * t) * params.engineLevel
                    let fan2 = sin(2.0 * .pi * (f0 * 2.0) * t) * (params.engineLevel * 0.45)
                    let fan3 = sin(2.0 * .pi * (f0 * 3.0) * t) * (params.engineLevel * 0.25)
                    let turbofan = fan1 + fan2 + fan3

                    // Character layer
                    let charLayer = params.characterLayer(t, frame, ch)

                    let sample = (cabinAir + hullRumble + turbofan + charLayer) * 1.6
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
                var pinkState = 0.0
                var brownState = 0.0
                var seed = UInt32(ch * 54321 + 98765)

                for frame in 0..<Int(frameCount) {
                    let t = Double(frame) / sampleRate

                    seed = seed &* 1664525 &+ 1013904223
                    let white = (Double(seed) / Double(UInt32.max)) * 2.0 - 1.0

                    pinkState = 0.85 * pinkState + 0.15 * white
                    brownState = 0.98 * brownState + 0.02 * white

                    // Air pocket low-frequency shudder
                    let pocketFreq = 24.0 + sin(2.0 * .pi * 0.8 * t) * 10.0
                    let pocketRumble = sin(2.0 * .pi * pocketFreq * t) * 0.25

                    // Crosswind shear buffet sweeps
                    let windMod = max(0.0, sin(2.0 * .pi * 0.4 * t))
                    let windBuffet = pinkState * 0.35 * windMod

                    // Hull bumps
                    let bump = sin(2.0 * .pi * 1.5 * t) > 0.85 ? brownState * 0.35 : 0.0

                    let sample = (pocketRumble + windBuffet + bump + (brownState * 0.2)) * 1.6
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
                    let decay1 = exp(-t * 5.0) // Smooth exponential bell ring
                    let tone1 = sin(2.0 * .pi * 587.33 * t) * 0.45 * decay1
                    let overtone1 = sin(2.0 * .pi * 1174.66 * t) * 0.18 * decay1
                    let overtone1b = sin(2.0 * .pi * 1761.99 * t) * 0.06 * decay1
                    sample += tone1 + overtone1 + overtone1b
                }

                // Tone 2: Low Bell A4 (0.28s to 1.6s)
                if t >= 0.28 {
                    let t2 = t - 0.28
                    let decay2 = exp(-t2 * 4.2)
                    let tone2 = sin(2.0 * .pi * 440.00 * t2) * 0.48 * decay2
                    let overtone2 = sin(2.0 * .pi * 880.00 * t2) * 0.20 * decay2
                    let overtone2b = sin(2.0 * .pi * 1320.00 * t2) * 0.08 * decay2
                    sample += tone2 + overtone2 + overtone2b
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

    private func aircraftParams(for aircraft: AircraftType) -> AircraftAudioParams {
        switch aircraft {
        case .a350F:
            // Airbus A350F: Quiet carbon-composite cabin + Rolls-Royce Trent XWB turbofan hum
            return AircraftAudioParams(
                engineFreq: 58.0,
                engineLevel: 0.18,
                cabinAirLevel: 0.22,
                hullRumbleLevel: 0.15,
                characterLayer: { t, _, _ in
                    // High-bypass turbine blade harmonic (soothing 420 Hz hum)
                    let turbine = sin(2.0 * .pi * 420.0 * t) * 0.035
                    return turbine
                }
            )

        case .b787Dreamliner:
            // Boeing 787-9 Dreamliner: Serene acoustic cabin dampening + gentle high-altitude mist
            return AircraftAudioParams(
                engineFreq: 64.0,
                engineLevel: 0.18,
                cabinAirLevel: 0.24,
                hullRumbleLevel: 0.14,
                characterLayer: { t, _, _ in
                    let mist = sin(2.0 * .pi * 320.0 * t) * 0.03
                    return mist
                }
            )

        case .concordeSST:
            // Concorde SST: Supersonic delta-wing airflow rush + Olympus turbojet thrust
            return AircraftAudioParams(
                engineFreq: 88.0,
                engineLevel: 0.24,
                cabinAirLevel: 0.28,
                hullRumbleLevel: 0.18,
                characterLayer: { t, _, _ in
                    let machRush = sin(2.0 * .pi * 650.0 * t) * 0.04
                    return machRush
                }
            )

        case .gulfstreamG650:
            // Gulfstream G650: Whisper-quiet executive jet FL450 cruising air
            return AircraftAudioParams(
                engineFreq: 72.0,
                engineLevel: 0.14,
                cabinAirLevel: 0.18,
                hullRumbleLevel: 0.10,
                characterLayer: { t, _, _ in
                    let whisper = sin(2.0 * .pi * 510.0 * t) * 0.025
                    return whisper
                }
            )

        case .cessna172:
            // Cessna 172 Skyhawk: Lycoming 4-cylinder rhythmic propeller drone
            return AircraftAudioParams(
                engineFreq: 42.0,
                engineLevel: 0.26,
                cabinAirLevel: 0.16,
                hullRumbleLevel: 0.14,
                characterLayer: { t, _, _ in
                    // Propeller blade thrum (2-blade prop at 2400 RPM = 80 Hz beat)
                    let propBeat = sin(2.0 * .pi * 80.0 * t) * 0.08
                    return propBeat
                }
            )
        }
    }
}
