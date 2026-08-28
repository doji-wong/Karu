# ADR-006: Adaptive In-Flight Ambient Audio Engine via AVAudioEngine

## Status
Accepted

## Date
2026-08-29

## Context
Karu provides vehicle-specific ambient soundscapes (electric hum, rain on car roof, rhythmic train glide, warm engine purr) during active focus runs, and adapts the soundscape during distraction events (smooth crossfade into idle/traffic audio cues).

Key technical requirements:
- Seamless looping with zero stutter or popping at loop boundaries.
- Smooth crossfading (300ms–500ms linear or equal-power gain ramp) between Cruising and Stalled audio states.
- Ultra-low memory and CPU impact (<1% CPU when audio is playing).
- Independent volume control that does not block or hijack system audio playback (e.g. user listening to Spotify/Apple Music concurrently).

## Decision
Use Apple's native **`AVAudioEngine`** with custom `AVAudioPlayerNode` and `AVAudioMixerNode` pipelines.

1. **Audio Looping & Crossfading:**
   - Pre-buffer compressed AAC/CAF ambient loops into `AVAudioPCMBuffer` memory.
   - Use two simultaneous player nodes: `cruisePlayerNode` and `stallPlayerNode`.
   - On state transitions (`.cruising` <-> `.trafficStalled`), smoothly ramp player volumes via `mixerNode` parameter automation over 400ms.
2. **Audio Mixing & Concurrency:**
   - Configure audio session / output to mix seamlessly with background music players without ducking unless configured by user.

## Alternatives Considered

### Web Audio API / Electron Webview audio
- **Pros:** Easy JavaScript audio APIs.
- **Cons:** High CPU load for simple audio looping; prone to audio glitches during Mac system load.
- **Rejected:** Incompatible with native macOS goals.

### `AVPlayer` / `NSSound`
- **Pros:** Very simple one-line API.
- **Cons:** `NSSound` lacks smooth crossfading, gapless looping, and dynamic equalizer curves.
- **Rejected:** `AVAudioEngine` is significantly superior for low-latency adaptive soundscapes.

## Consequences
- **Positive:** Gapless, studio-quality ambient audio with zero CPU bloat.
- **Positive:** Smooth, cinematic audio crossfading between high-speed cruising and traffic gridlock.
- **Negative:** Requires lightweight bundled audio assets (CAF/AAC) carefully mastered for seamless looping.
