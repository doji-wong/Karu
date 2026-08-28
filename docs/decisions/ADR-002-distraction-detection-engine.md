# ADR-002: Event-Driven Distraction Detection via NSWorkspace

## Status
Accepted

## Date
2026-08-29

## Context
The core game mechanic of Karu is the contrast between **Cruising Velocity** (working in designated productive tools) and **Traffic Gridlock** (wandering into blacklisted distraction apps).

To detect context switches on macOS without draining laptop battery or triggering invasive security permission prompts, we needed to select an appropriate monitoring architecture.

## Decision
Use macOS **`NSWorkspace.didActivateApplicationNotification`** notifications through an event-driven `DistractionMonitor` service.

When a frontmost application switch occurs:
1. `NSWorkspace` delivers the bundle identifier and localized name of the new active app.
2. The `DistractionMonitor` compares the bundle ID / app name against the user's blacklist / whitelist.
3. If an unapproved distraction app is frontmost, the transit state engine transitions to `.trafficStalled` and records a stall incident.
4. When focus returns to an approved app or neutral context, the engine returns to `.cruising`.

## Alternatives Considered

### Periodic Polling Timer (e.g. `Timer.scheduledTimer` every 500ms)
- **Pros:** Conceptually simple.
- **Cons:** Constantly wakes the CPU and timer coalescing threads, causing unnecessary battery drain on Apple Silicon laptops.
- **Rejected:** Inefficient compared to macOS system notifications.

### Accessibility API / Deep Window Title & Browser URL Inspection
- **Pros:** Can inspect the specific tab URL in Chrome/Safari/Arc.
- **Cons:** Requires the user to grant invasive macOS Accessibility / Automation permissions in System Settings, which causes high friction during initial onboarding and raises privacy concerns.
- **Decision:** Defer URL inspection to an optional opt-in setting in v1.1. For MVP, app-level switching provides a frictionless, zero-permission setup.

## Consequences
- **Positive:** Zero polling overhead—CPU wakes only on actual user window switches.
- **Positive:** Requires zero special system permissions for standard app-level detection.
- **Positive:** Instantaneous response time on app switch.
- **Negative:** Won't detect distractions within a browser if the browser itself is classed as a general tool (addressed by allowing users to blacklist specific standalone apps like Discord/Steam/Social apps, or toggle strict mode).
