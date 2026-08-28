import Testing
@testable import KaruCore
import Foundation

@Suite("Audio Engine Tests")
struct AudioEngineTests {

    @Test("AudioEngine initializes with valid default parameters")
    @MainActor
    func initialization() {
        let audioEngine = AudioEngine()
        #expect(audioEngine.isRunning == false)
        #expect(audioEngine.isMuted == false)
        #expect(audioEngine.masterVolume == 0.6)
        #expect(audioEngine.currentVehicle == .midnightEV)
        #expect(audioEngine.currentTransitState == .idle)
    }

    @Test("Volume and mute controls update properties properly")
    @MainActor
    func volumeAndMuteControls() {
        let audioEngine = AudioEngine()

        audioEngine.masterVolume = 0.8
        #expect(audioEngine.masterVolume == 0.8)

        audioEngine.toggleMute()
        #expect(audioEngine.isMuted == true)

        audioEngine.setMuted(false)
        #expect(audioEngine.isMuted == false)
    }

    @Test("Vehicle switching updates active vehicle profile")
    @MainActor
    func vehicleSwitching() {
        let audioEngine = AudioEngine()

        audioEngine.setVehicle(.classicSarao)
        #expect(audioEngine.currentVehicle == .classicSarao)

        audioEngine.setVehicle(.nightRainHatchback)
        #expect(audioEngine.currentVehicle == .nightRainHatchback)
    }

    @Test("Transit state updates transition without errors")
    @MainActor
    func stateTransitions() {
        let audioEngine = AudioEngine()

        audioEngine.updateState(.cruising, animated: false)
        #expect(audioEngine.currentTransitState == .cruising)

        audioEngine.updateState(.trafficStalled, animated: false)
        #expect(audioEngine.currentTransitState == .trafficStalled)

        audioEngine.updateState(.idle, animated: false)
        #expect(audioEngine.currentTransitState == .idle)
    }
}
