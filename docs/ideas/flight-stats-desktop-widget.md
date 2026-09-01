# Karu Desktop Flight Telemetry Widget (Option A)

## Problem Statement
How might we transform the user's macOS desktop and Notification Center into an ambient, high-contrast Pilot Flight Dispatch Board that visualizes certified focus hours, efficiency, and streaks without inducing cognitive noise or timer anxiety?

## Recommended Direction (Option A: Dual Widget Set)
We are implementing **Option A: Dual Widget Set** featuring:
1. **Small Airspeed Gauge & Quota Widget (`systemSmall`)**: A minimalist circular dot-matrix focus quota ring displaying daily flight hours completed vs. goal (`3.5h / 5.0h`), current cruising velocity (`540 kts`), active streak (`🔥 12d`), and aircraft fleet badge (`A350F`).
2. **Medium Flight Dispatch Board Widget (`systemMedium`)**: A dual-pane avionics terminal.
   - *Left Telemetry Pane*: Today's Certified Flight Hours, Nautical Miles Flown (`NM`), On-Time Cruise Efficiency (`%`), and Streak.
   - *Right Flight Ops Pane*: Active Flight Route (`SFO ✈ HND`) with origin/destination timezones, real-time status badge (`CRUISING 540 kts` / `HOLDING` / `STANDBY`), and an interactive 1-click **"Takeoff / Gate Hold"** button powered by `AppIntent`.

Both widgets strictly adhere to **Direction A Monochrome Avionics** (`#08080A` carbon matte background, `#151518` elevated surfaces, `#FFFFFF` high contrast text, dot matrix LED styling, amber `#F59E0B` turbulence warning indicators).

## Key Assumptions to Validate
- [ ] **Data Sharing Feasibility**: Widget extension can read `WidgetTelemetrySnapshot` atomically written by `LocalStorageManager` / App Group container with zero latency.
- [ ] **Timeline Update Budget**: Refreshing timelines on state transitions (`cruising`, `trafficStalled`, `pitStop`, `completed`) keeps macOS battery usage near 0% without stale widget telemetry.
- [ ] **Interactive Intent Execution**: 1-click Takeoff and Gate Hold `AppIntent` triggers engine state updates seamlessly without forcing the main app to foreground.

## MVP Scope (Option A)
- **Data Snapshot Contract (`WidgetTelemetrySnapshot`)**: Encapsulates active route, duration, elapsed time, daily completed hours, daily goal hours, streak, cruising speed, and active aircraft.
- **Small Widget View (`SmallAirspeedGaugeWidgetView`)**: Circular progress ring, airspeed readout, daily goal fraction, and streak pill.
- **Medium Widget View (`MediumFlightDispatchWidgetView`)**: Split avionics card with flight performance telemetry on left, route & interactive takeoff button on right.
- **Timeline Provider (`FlightTelemetryTimelineProvider`)**: Generates timeline entries and handles snapshot decoding with resilient fallback defaults.
- **Interactive App Intents (`TakeoffIntent`, `GateHoldIntent`)**: Quick desktop-based flight controls.

## Not Doing (and Why)
- **60fps Second-by-Second Timer Animation**: WidgetKit does not permit unthrottled sub-second rendering; we use `Text(timerInterval:pauseTime:)` for live elapsed timer displays.
- **Large Heatmap Widget (SystemLarge)**: Deferred to a future release to keep the MVP laser-focused and lightweight.
- **Audio Playback Inside Widget**: WidgetKit does not host `AVAudioEngine` pipelines; audio remains managed by the main app process.

## Open Questions
- None blocking. Implementation uses standard macOS 14+ WidgetKit and AppIntents.
