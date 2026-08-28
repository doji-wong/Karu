# ADR-004: Local-First Data, Habit, and Travel Log Persistence

## Status
Accepted

## Date
2026-08-29

## Context
Karu stores:
1. **Habit Profiles:** Name, target duration, frequency, color theme, and streak counts.
2. **Trip Logs (Travel History):** Timestamps, total duration, cruise efficiency percentage, traffic stall incidents list, and associated scratchpad notes.
3. **App Configuration & Rules:** Whitelist/blacklist bundle IDs, sound preferences, and HUD position presets.

All data must be stored 100% locally on the user's Mac, work with zero internet connectivity, and support instant read/writes with zero disk IO stalls.

## Decision
Use **SwiftData / JSON File Storage with Atomic Writes** in the user's `Application Support/Karu/` directory.

- **Models:**
  - `Habit`: Represents a recurring track/habit with streaks and lifetime stats.
  - `TripSession`: Represents a completed or active journey, containing `stalledEvents: [TrafficIncident]`, `scratchpadNotes: String`, `duration: TimeInterval`, and `cruiseEfficiency: Double`.
  - `AppSettings`: Stores user preferences and custom distraction blacklist entries.

## Alternatives Considered

### CoreData
- **Pros:** Mature, robust.
- **Cons:** Heavy boilerplate, complex schema migration setup for a lightweight utility app.
- **Decision:** SwiftData or structured JSON Codable models offer identical speed with far cleaner code and easier debugging.

### CloudKit / Firebase
- **Pros:** Multi-device synchronization.
- **Cons:** Requires user accounts/Apple ID setup, introduces network failure states, and conflicts with the v1 local-first principle.
- **Rejected:** Deferred to future cloud sync roadmap if demanded.

## Consequences
- **Positive:** Privacy-first: user data never leaves their Mac.
- **Positive:** Instantaneous read/write speeds with zero network latency.
- **Positive:** Easy for users to backup, inspect, or export their notes and trip logs as Markdown or JSON.
