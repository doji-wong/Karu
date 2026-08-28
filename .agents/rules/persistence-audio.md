# Local Persistence & Audio Engine Guidelines

## 1. Local-First Storage Architecture
- Directory: `~/Library/Application Support/Karu/`
- Zero cloud servers, zero network dependencies.
- Use atomic disk writes:
  ```swift
  try data.write(to: fileURL, options: [.atomic])
  ```
- File Models:
  - `habits.json` / SwiftData: User habits, daily targets, and streaks.
  - `trips.json` / SwiftData: Historical trip session logs, duration, efficiency %, and stall incidents.
  - `scratchpad.md` / `notes.json`: Auto-saved user scratchpad notes tied to session or standalone.
  - `app_filters.json`: User whitelist/blacklist bundle ID rules and active preset.

## 2. In-Flight Ambient Audio Engine (`AVAudioEngine`)
- Pre-load compressed CAF/AAC loop buffers into `AVAudioPCMBuffer`.
- Keep audio latency low and memory below 5MB per loop.
- Use two concurrent nodes (`cruisePlayerNode` and `stallPlayerNode`) attached to an `AVAudioMixerNode`.
- State transitions (`.cruising` <-> `.trafficStalled`) crossfade player volumes smoothly over 400ms without pops or clicks.
- Audio playback must mix seamlessly with user music (Spotify/Apple Music) without muting external system audio.
