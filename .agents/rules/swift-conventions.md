# Swift Conventions & Concurrency

## 1. Swift 6 & Concurrency
- Strict concurrency checking enabled.
- `@MainActor` required on all UI ViewModels, Window Controllers, and `@Observable` stores.
- Data structures passed across background queues or actors must be `Sendable` (value types, immutable structs, or explicit actors).

## 2. SwiftUI & State Management
- Use `@Observable` (Observation framework) for state stores where supported (macOS 14+).
- Decouple business logic from SwiftUI View rendering; keep `TransitEngine` and `DistractionMonitor` testable as pure Swift classes/actors.
- View styling should adhere to dark aerospace theme: OLED black `#0B0D13`, Emerald green `#10B981`, Hazard amber `#F59E0B`, Navigation blue `#3B82F6`.

## 3. AppKit Interoperability
- Subclass `NSPanel` for floating overlays; configure with `.nonactivatingPanel` to prevent stealing focus from user's active code editor.
- Use `NSVisualEffectView` with `.behindWindow` blending and `.hudWindow` / `.popover` material for macOS dark vibrancy.
