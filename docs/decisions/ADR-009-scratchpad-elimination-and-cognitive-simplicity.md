# ADR-009: Elimination of In-Flight Scratchpad & Note-Taking for Cognitive Simplicity

## Status
Accepted (Supersedes [ADR-008](file:///Users/vinbaldove/Documents/Karu%20-%20Focus%20Timer/docs/decisions/ADR-008-in-flight-scratchpad-architecture.md))

## Date
2026-08-30

## Context
In ADR-008, an embedded scratchpad note editor was introduced across the Menu Bar popover and floating HUD to capture quick notes during focus sessions. However, real-world user testing and ideation refinement revealed critical product friction:
1. **Cognitive Overhead:** Having a text editor embedded in a floating flight telemetry card divided the user's attention between telemetry tracking and document editing.
2. **Feature Creep & Tool Competition:** Knowledge workers and developers already use dedicated note-taking environments (Obsidian, Bear, VS Code, Notion) that are already configured as approved `focusWorkspace` apps. An embedded scratchpad created redundant, subpar note-taking features.
3. **UI Complexity:** Managing debounced file I/O, cursor states, markdown shortcuts, and text area sizing crowded the compact 372px HUD card.

## Decision
Completely eliminate the in-flight scratchpad feature, `ScratchpadStore`, `ScratchpadView`, and `TripSession.scratchpadNotes` field across the entire codebase.

Focus Karu 100% on **frictionless flight telemetry, real-time turbulence detection, ambient cabin audio, and pilot streak tracking**.

## Alternatives Considered

### Retain as a hidden / collapsed drawer
- **Pros:** Preserved existing code.
- **Cons:** Still incurred maintenance cost, model bloat, and storage overhead.
- **Rejected:** Complete deletion provides clean architecture, zero dead code, and maximal focus.

### Read-only note viewer
- **Pros:** No text editing complexity.
- **Cons:** Did not solve the core issue of competing with dedicated knowledge management apps.
- **Rejected:** Unnecessary clutter.

## Consequences
- **Positive:** Reduced memory footprint and eliminated disk I/O debouncing logic.
- **Positive:** Simplified `FocusFlightCard`, `FloatingHUDView`, `DiagnosticPopoverView`, and `TripSession` models.
- **Positive:** Clarified product value: Karu is a focused flight telemetry and habit tracker, not a note-taking app.
- **Negative:** Users who want to take notes must use their primary focus applications (which are recognized as active focus workspaces).
