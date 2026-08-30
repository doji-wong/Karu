# ADR-012: Pilot Logbook & Flight Hours Telemetry Architecture

## Status
Accepted

## Date
2026-08-30

## Context
Users need clear proof of their focus work and deep-work consistency over time. Traditional Pomodoro apps show basic count totals or simple bar charts, which lack immersion.

With the **Focus Flight** paradigm, knowledge workers earn certified **Pilot Flight Hours**, accumulate **Nautical Miles (NM)** of focused air travel, and track **Touchdown Streaks** and **On-Time Fleet Efficiency**.

## Decision
Implement a dedicated **Pilot's Flight Logbook** window (`LogbookView.swift`) accessible via global menu bar shortcut (`Cmd + L`) and direct button on the Flight Card:
1. **Telemetry Top Cards:**
   - Total Flight Hours (`HRS`)
   - Total Distance Flown in Nautical Miles (`NM`)
   - Completed Touchdowns
   - Fleet On-Time Cruising Efficiency percentage
2. **Chronological Flight Records:**
   - Date and time of departure
   - Flight preset used (`Sprint 25m`, `Cruise 50m`, `Long Haul 90m`, `Open Flight`)
   - Cruising minutes vs Turbulence minutes
   - Number of turbulence encounters logged during the flight
   - Distance traveled in NM
   - Completion status (`Touchdown` vs `Aborted`)
3. **Data Management:**
   - 100% local persistence in `~/Library/Application Support/Karu/trips.json`.
   - Option to clear logbook history.

## Alternatives Considered

### Embedding full log history inside Menu Bar popover
- **Pros:** No extra window.
- **Cons:** Clutters the lightweight menu bar popover and increases popover memory overhead.
- **Rejected:** Dedicated utility window (`Cmd + L`) provides spacious, comfortable logbook inspection.

### Third-party cloud analytics database
- **Pros:** Cross-device sync.
- **Cons:** Violates Zero-Cloud and local-first privacy commitments.
- **Rejected:** Local atomic JSON storage guarantees absolute privacy.

## Consequences
- **Positive:** Deeply satisfying aviation-themed milestone progression for users.
- **Positive:** Clear visual distinction between smooth cruise time and turbulence distraction time.
- **Positive:** Fast access via `Cmd + L`.
