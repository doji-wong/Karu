import SwiftUI
import KaruCore

/// Ultra-compact translucent glassmorphism floating HUD view with mini highway toggle.
public struct FloatingHUDView: View {
    @Bindable public var engine: TransitEngine
    @Bindable public var scratchpadStore: ScratchpadStore
    public var onClose: (() -> Void)?

    @State private var isHovering: Bool = false
    @State private var isScratchpadExpanded: Bool = false
    @State private var isHighwayExpanded: Bool = false

    public init(
        engine: TransitEngine,
        scratchpadStore: ScratchpadStore,
        onClose: (() -> Void)? = nil
    ) {
        self.engine = engine
        self.scratchpadStore = scratchpadStore
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 6) {
            // Main HUD Bar
            HStack(spacing: 8) {
                // Drag Handle
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 9))
                    .foregroundStyle(KaruTheme.textMuted)

                // Velocity Pill
                HStack(spacing: 4) {
                    Circle()
                        .fill(KaruTheme.statusGlow(for: engine.state))
                        .frame(width: 6, height: 6)

                    Text("\(Int(engine.currentVelocity))")
                        .font(KaruTheme.captionMono)
                        .fontWeight(.black)
                        .foregroundStyle(KaruTheme.statusGlow(for: engine.state))

                    Text("km/h")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(KaruTheme.textMuted)
                }

                // Route Progress
                if let session = engine.activeSession {
                    if let target = session.targetDuration {
                        let remaining = max(0, target - session.cruisingDuration)
                        let mins = Int(remaining) / 60
                        Text("· \(mins)m left")
                            .font(KaruTheme.captionMono)
                            .foregroundStyle(KaruTheme.textSecondary)
                    }
                }

                Spacer()

                // Highway Mini-Map Expand Toggle
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        isHighwayExpanded.toggle()
                        if isHighwayExpanded { isScratchpadExpanded = false }
                    }
                } label: {
                    Image(systemName: "road.lanes.curved.right")
                        .font(.system(size: 11))
                        .foregroundStyle(isHighwayExpanded ? KaruTheme.cruiseNeon : KaruTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Toggle Mini Highway Navigation")

                // Scratchpad Expand Toggle
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        isScratchpadExpanded.toggle()
                        if isScratchpadExpanded { isHighwayExpanded = false }
                    }
                } label: {
                    Image(systemName: isScratchpadExpanded ? "note.text.badge.plus" : "note.text")
                        .font(.system(size: 11))
                        .foregroundStyle(isScratchpadExpanded ? KaruTheme.navCyan : KaruTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .help("Toggle In-Flight Scratchpad")

                // Close Overlay Button
                if isHovering {
                    Button {
                        onClose?()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(KaruTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            // Expandable Waze Highway Map
            if isHighwayExpanded {
                VStack(spacing: 4) {
                    Divider().background(KaruTheme.cardBorder)
                    HighwayNavigationView(engine: engine)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 6)
                }
            }

            // Expandable Scratchpad
            if isScratchpadExpanded {
                VStack(spacing: 4) {
                    Divider().background(KaruTheme.cardBorder)
                    TextEditor(text: $scratchpadStore.notes)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(height: 70)
                        .scrollContentBackground(.hidden)
                        .background(KaruTheme.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .padding(.horizontal, 8)
                        .padding(.bottom, 6)
                }
            }
        }
        .frame(width: isHighwayExpanded ? 320 : 270)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(KaruTheme.background.opacity(0.92))
                .shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(KaruTheme.cardBorder, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}
