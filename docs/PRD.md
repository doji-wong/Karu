# Karu — Product Requirements Document (PRD)

**Document Status:** Approved for MVP  
**Version:** 1.0.0 (MVP)  
**Date:** 2026-08-29  
**Platform:** macOS 14.0+ (Apple Silicon & Intel)  
**Tech Foundation:** Native Swift / SwiftUI / AppKit (100% Local-First)

---

## 1. Executive Summary & Vision

Traditional focus timers (e.g., standard Pomodoro apps) rely on anxiety-inducing countdown clocks and passive timers that are either ignored or induce task friction. 

**Karu** is a high-performance, native macOS Menu Bar & Floating HUD application that replaces countdown clocks with a **traffic and route navigation metaphor**. A focus session is framed as a high-speed transit run down an open highway. Remaining active in your designated workspace keeps your vehicle cruising at peak velocity; switching into high-friction distraction apps hits sudden road gridlock, halting transit until you return to focus.

With integrated **in-flight scratchpad note-taking** and **habit-linked routes**, Karu turns deep study and development sessions into a tangible journey of momentum.

---

## 2. Target Audience & Personas

1. **The Software Engineer / Terminal Worker:** Needs uninterrupted deep coding flow; spends hours switching between IDE, terminal, and documentation, but prone to muscle-memory context-switching (e.g., Reddit, Discord, YouTube, Twitter/X).
2. **The Student / Researcher:** Balances reading papers, drafting notes, and problem-solving; needs a quick scratchpad during study sessions without leaving their active desktop space.
3. **The Remote Knowledge Worker:** Struggles with unstructured work blocks and needs a visible, low-friction momentum tracker in the macOS Menu Bar.

---

## 3. Product Metaphor & Core Mechanics

```
┌─────────────────────────────────────────────────────────────┐
│                      THE TRANSIT ENGINE                     │
│                                                             │
│   [Focus Workspace]  ─────────► [Cruising Velocity: 100km/h]│
│   (Xcode, VS Code, Docs)        (Green Wave / Smooth Route) │
│                                                             │
│   [Distraction App]  ─────────► [Traffic Stalled: 0km/h]   │
│   (Social, Video, Chat)         (Hazard Gridlock / Warning) │
└─────────────────────────────────────────────────────────────┘
```

### 3.1 The Open Highway (Cruising Velocity)
* When a trip is active and the user's frontmost application is on the **Approved Workspace list** (or neutral), the transit engine runs at **Cruise State (e.g., 100 km/h / 60 mph)**.
* Visual indicators glow with a steady, serene pulse; route distance accumulates steadily toward destination arrival.

### 3.2 Traffic & Detours (The Distraction Filter)
* Karu monitors frontmost active application changes via macOS `NSWorkspace`.
* When the user activates a blacklisted distraction app (e.g., Discord, Telegram, Steam, Twitter client, or configurable apps), the transit engine detects a **Road Hazard / Traffic Gridlock**.
* Velocity drops to **0 km/h**. The Menu Bar and HUD shift to an amber/red traffic alert state, and route progress freezes until the user steers back to their focus window.

### 3.3 Trip Presets & Flow Modes
* **City Dash (25m):** High-intensity sprint (Pomodoro equivalent).
* **Expressway Transit (50m):** Deep-work standard block.
* **Interstate Run (90m):** Extended ultradian cycle.
* **Open Highway (Stopwatch):** Uncapped flow run with continuous velocity logging.

---

## 4. Feature Specifications

### 4.1 Menu Bar HUD (Collapsed State)
* **Visuals:** Minimalist status item featuring a dynamic vector route glyph + live velocity or remaining ETA distance.
* **States:**
  * *Idle:* Dim monochrome route glyph.
  * *Cruising:* Crisp high-contrast indicator with gentle pulse.
  * *Traffic Stalled:* High-visibility amber/hazard flash indicating gridlock.
  * *Complete:* Destination reached icon + subtle macOS native notification chime.

### 4.2 Diagnostic Dropdown (Expanded Menu Bar Popover)
* Triggered by clicking the Menu Bar icon or pressing a global shortcut (`Option + Space` configurable).
* **Components:**
  1. **Telemetry Dashboard:** Live speed gauge, trip progress bar (% and distance remaining), cruising time vs. traffic stall time.
  2. **Active Habit / Route Selector:** Switch between tagged habit tracks (e.g., *"Study Algorithms"*, *"API Refactoring"*, *"Writing PRD"*).
  3. **Trip Controls:** Quick Start, Pause / Pit Stop, Complete Run, Cancel Trip.
  4. **Traffic Incident Log:** Chronological list of stall events (e.g., `04:12 PM - Stalled 2m 14s [Discord]`).
  5. **In-Flight Scratchpad:** Markdown-enabled quick-capture text area for thoughts, study notes, or questions.

### 4.3 Floating HUD Overlay (Detachable / Always-on-Top)
* A translucent, ultra-compact glassmorphism HUD window that can be pinned to any screen corner.
* Stays visible above full-screen IDEs, study documents, or split-screen layouts.
* Displays: Active Habit Name, Speedometer Pill, Mini Route Progress Bar, Quick Scratchpad toggle.
* Can be toggled on/off with a dedicated button or hotkey (`Cmd + Shift + K`).

### 4.4 Dynamic Notch HUD / Side-Notch Wings (MacBook Display Integration)
* **Screen Attachment:** Integrates directly with the physical camera notch on modern MacBooks (MacBook Pro / Air) using native `NSScreen.auxiliaryTopLeftArea` / `auxiliaryTopRightArea`.
* **Notch Wings Layout:**
  * **Left Wing:** Live Velocity Speedometer (e.g., `⚡ 100 km/h` emerald cruise glow; shifts to `⚠️ 0 km/h GRIDLOCK` amber/red warning when distracted).
  * **Right Wing:** Route progress & habit tag (e.g., `📍 24m remaining · Deep Work`).
* **Hover Interaction:** Hovering over the notch area gently expands an aerodynamic dropdown cockpit dashboard right beneath the notch.
* **Intelligent Display Fallback:** On external monitors or Macs without a camera notch, Karu automatically falls back to the Menu Bar HUD or floating HUD pill.

### 4.5 In-Flight Scratchpad & Study Logbook
* Frictionless note capture during and between focus runs.
* Instant auto-save to local storage on keystroke.
* Notes taken during a run are automatically attached to that session's **Travel Log** entry.
* Standalone notes can be taken without an active timer running.

### 4.6 Habit Tracking & Route History
* **Habits:** Define recurring focus rituals (e.g., "Daily Code - 50m", "Deep Reading - 30m").
* **Streaks & Travel History:** Daily streak tracking based on completed runs.
* **Trip History Log:** Searchable timeline of past journeys with date, duration, cruise efficiency %, and attached session notes.

### 4.7 The Garage & Vehicle Selection
Users can select their ride from a curated hangar of vehicles, customizing their journey's visual avatar, telemetry gauge style, and cruising sound profile:
1. **The Midnight EV (Cyber Cruiser):** Sleek aerodynamic electric vehicle with neon teal HUD line and a smooth, futuristic electric hum.
2. **The Classic Sarao (Heritage Jeepney):** Cultural icon with vibrant chrome styling, warm rhythmic engine acoustics, and scenic provincial journey vibes.
3. **The Night Rain Hatchback (Lo-Fi Commuter):** Cozy interior vibe with rain-on-roof audio, gentle rhythmic wipers, and ambient dashboard warmth—ideal for reading and study.
4. **The Shinkansen / Metro Express (High-Speed Rail):** High-momentum transit train with seamless rail-glide acoustics and wind tunnel white noise—perfect for high-intensity sprints.
5. **The Coastal Cruiser (Scenic Bus Liner):** Long-distance cruiser with rhythmic highway tire-clicks and ocean breeze acoustics—built for 50m/90m deep work blocks.

### 4.8 Adaptive Ambient Soundscapes (In-Flight Audio)
* **Cruising Audio:** Gentle, non-distracting background soundscapes (white/pink noise frequency curves) tailored to the active vehicle (engine hum, rain, road rhythm) designed to induce deep cognitive flow.
* **Dynamic Traffic Audio Cues:** When the user switches to a blacklisted distraction app, the audio smoothly transitions from clear highway cruise to a gentle brake/idle soundscape (muffled city rain, idle engine rumble), providing a non-jarring auditory feedback loop.
* **Audio Controls:** Master volume slider, one-click mute toggle in HUD, and option to route audio independently of system sound.

### 4.9 Customizable Focus & Distraction App Filters
* **Default Smart Presets:**
  * *Developer Preset:* Xcode, VS Code, iTerm/Terminal, Warp, Sublime, TablePlus, Figma, GitHub Desktop.
  * *Student / Researcher Preset:* Obsidian, Notion, Safari/Chrome (Docs & JSTOR), Preview (PDFs), Books, Anki, Overleaf.
  * *Writer / Creator Preset:* Ulysses, Scrivener, Word, Google Docs, Final Cut, Lightroom.
* **Custom App Whitelist & Blacklist Manager:** Simple drag-and-drop or bundle-picker interface allowing users to explicitly categorize any Mac application as *Cruising Workspace*, *Distraction Hazard (Stalls Engine)*, or *Neutral (e.g., Finder, Calculator, Notes)*.
* **Custom Distraction Strictness:** Option to set tolerance levels (e.g., Instant 0s stall vs. 5s grace period for quick 2FA/notifications).

---

## 5. UI / UX Design Specifications

### 5.1 Design Aesthetic: Aerospace & Modern Navigation
* **Theme:** Deep space / OLED dark mode (`#0B0D13` base background) with crisp neon accents.
* **Color Tokens:**
  * *Cruise Velocity (Green):* `#10B981` / `#34D399` (Emerald Neon)
  * *Traffic Hazard (Amber/Red):* `#F59E0B` / `#EF4444` (Brake Light Red)
  * *Route Track (Neutral Accent):* `#3B82F6` / `#6366F1` (Navigation Cyan/Indigo)
  * *Surface & Glass:* `rgba(22, 27, 38, 0.75)` with native macOS background blur (`NSVisualEffectView`).
* **Typography:** System SF Pro / SF Mono for telemetry digits and data readouts.

---

## 6. Non-Functional Requirements & Performance

* **CPU Overhead:** `< 0.5%` continuous background CPU usage.
* **Memory Footprint:** `< 45 MB` idle and active RAM footprint.
* **Startup Time:** `< 300 ms` cold start.
* **Zero Cloud Dependency:** 100% local-first data storage (SwiftData / SQLite). No telemetry, no user tracking, no accounts.
* **Battery Friendly:** App-switching detection uses event-driven `NSWorkspace.didActivateApplicationNotification` rather than polling loops.

---

## 7. Out of Scope for MVP (v1)

* Cloud sync across multiple Mac devices (v1.2).
* Deep browser URL inspection via Accessibility API/AppleScript (v1.1).
* Social leaderboards and multiplayer road trips.
* Kernel-level network packet blocking.

---

## 8. Success Metrics (MVP)

1. **Sub-second Start:** User can initiate a focus run from menu bar in $\le 2$ clicks.
2. **Zero False Positives:** App switching accurately detects whitelist vs blacklist with zero UI hang.
3. **Frictionless Scratchpad:** Instant notes capture without context switching.
4. **Delight Factor:** Clear visual feedback on cruising velocity vs. gridlock stalls.
