# ADR-007: Customizable App Classification & Filter Rules Architecture

## Status
Accepted

## Date
2026-08-29

## Context
Users have distinct workflows: a developer might consider Terminal and Xcode focus tools, while a graphic designer considers Photoshop and Blender focus tools. Furthermore, apps like Finder, System Settings, or 1Password should be treated as neutral utilities rather than immediate distraction hazards.

Karu needs a flexible, fast rule classification engine to categorize running macOS applications.

## Decision
Implement a triple-state rule engine with the following classification categories:

```swift
enum AppFocusCategory: String, Codable {
    case focusWorkspace   // Cruising velocity (100 km/h)
    case distractionHazard // Stalls velocity to 0 km/h (Gridlock)
    case neutralUtility   // Maintains current state without penalties (e.g. 1Password, Finder)
}
```

1. **Rule Evaluation Hierarchy:**
   - **User Custom Override:** Explicit user assignment by `bundleIdentifier` (e.g. `com.tinyspeck.slackmacgap` -> `distractionHazard` or `focusWorkspace`).
   - **Active Preset Match:** Match against curated presets (Developer, Student, Writer, Designer).
   - **Default Heuristic:** Unlisted applications default to `neutralUtility` with an optional "Strict Mode" toggle (where unlisted apps trigger distraction warning).
2. **Persistence:**
   - Stored in `Application Support/Karu/app_filters.json` as a fast-lookup set keyed by bundle ID.
3. **UI Management:**
   - In-app preference panel allowing users to drag-and-drop apps from `/Applications` or select from a list of currently running processes.

## Alternatives Considered

### Static Hardcoded Blacklist
- **Pros:** Zero configuration.
- **Cons:** Inflexible for non-standard workflows (e.g., a community manager who legitimately uses Discord for work).
- **Rejected:** Fails user workflow customization.

## Consequences
- **Positive:** Complete personalization for any discipline (coding, studying, research, creative arts).
- **Positive:** Sub-millisecond lookup latency ($O(1)$ dictionary lookup on bundle ID).
- **Negative:** Requires an intuitive, visual preference editor for managing app lists.
