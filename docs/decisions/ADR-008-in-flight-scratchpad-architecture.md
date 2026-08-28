# ADR-008: In-Flight Scratchpad & Note-Taking Architecture

## Status
Accepted

## Date
2026-08-29

## Context
During deep work and study sessions, users frequently have sudden ideas, quick tasks, or questions they want to jot down without context-switching out of their active workspace or opening a heavy note-taking application.

Key requirements:
- **Instant access:** Accessible directly from the Menu Bar popover, Floating HUD, and dynamic notch dropdown.
- **Zero latency:** Key strokes must never block the UI thread.
- **Local-first auto-save:** Notes must persist across app restarts and attach to the completed `TripSession` travel log entry.
- **Format:** Plain text / Markdown-friendly.

## Decision
Implement an event-driven, debounced `ScratchpadStore` backed by atomic Markdown file storage (`~/Library/Application Support/Karu/scratchpad.md` / `notes.json`).

1. **Auto-Saving & Debouncing:**
   - Use a 500ms trailing debounce on keystrokes before writing to disk, avoiding high disk I/O on every character typed.
   - Flush unwritten scratchpad buffers immediately on application backgrounding, trip completion, or system termination.
2. **Session Logbook Attachment:**
   - When a user finishes a focus trip, the scratchpad contents captured during that session are snapshot and copied into the `TripSession.scratchpadNotes` field in the travel log.
   - The user can choose to clear the scratchpad for the next trip or keep continuous notes.

## Alternatives Considered

### Direct SQLite/CoreData row update on every keystroke
- **Pros:** Structured database.
- **Cons:** Unnecessary database lock overhead on rapid typing.
- **Rejected:** Debounced atomic file writes provide better performance and zero schema lock complexity.

### Cloud Notes Sync (Apple Notes integration / Notion API)
- **Pros:** Cloud backup.
- **Cons:** Violates 100% local-first zero-telemetry guarantee and introduces network failure edge-cases.
- **Rejected:** Local atomic Markdown files allow users to index their notes via Obsidian, VS Code, or Spotlight directly.

## Consequences
- **Positive:** Zero keystroke lag, safe persistence against sudden power loss.
- **Positive:** Notes are user-accessible as standard Markdown in their Application Support directory.
- **Negative:** Requires handling uncommitted buffer flushes on app crash/termination.
