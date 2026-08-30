# ADR-011: Live 1-Click Running Application Radar Architecture

## Status
Accepted

## Date
2026-08-30

## Context
Configuring application whitelist and blacklist rules traditionally requires users to manually look up Apple bundle identifiers (e.g. `com.apple.dt.Xcode`, `com.hnc.Discord`, `com.tinyspeck.slackmacgap`). This creates high friction and onboarding drop-off.

Key requirements:
- Users should be able to classify currently running applications in **1 click**.
- Display native macOS application icons, localized app names, and bundle IDs.
- Persist overrides instantly to local storage without requiring app restarts.

## Decision
Implement a **Live Running App Radar** inside `AppFilterSettingsView`:
1. Use `NSWorkspace.shared.runningApplications` filtered by `activationPolicy == .regular` to discover all running user applications.
2. Extract localized application names and icons via `NSRunningApplication.icon`.
3. Provide a 3-way 1-click classification toggle (`Focus`, `Hazard`, `Neutral`) that instantly updates `AppClassifier` and writes to atomic JSON storage (`~/Library/Application Support/Karu/rules.json`).
4. Include real-time query search filtering and a manual rescan trigger.

## Alternatives Considered

### Manual Bundle ID Input Only
- **Pros:** Minimal UI.
- **Cons:** Extremely high user friction; users don't know bundle IDs.
- **Rejected:** Unusable for non-technical users.

### System Accessibility Permission Requirement
- **Pros:** Can inspect all background daemon processes.
- **Cons:** Triggers scary macOS Security & Privacy permission prompts on first launch.
- **Rejected:** `NSWorkspace.shared.runningApplications` provides regular GUI apps with zero elevated permissions required.

## Consequences
- **Positive:** Zero friction onboarding; users classify their entire desktop workflow in under 10 seconds.
- **Positive:** No special macOS system permissions or Accessibility entitlements required.
- **Positive:** Visual confirmation with native app icons.
