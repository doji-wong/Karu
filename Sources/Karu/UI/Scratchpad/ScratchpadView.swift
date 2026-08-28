import SwiftUI
import KaruCore

/// Full standalone In-Flight Scratchpad editor view.
public struct ScratchpadView: View {
    @Bindable public var scratchpadStore: ScratchpadStore

    public init(scratchpadStore: ScratchpadStore) {
        self.scratchpadStore = scratchpadStore
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("IN-FLIGHT SCRATCHPAD")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.navCyan)
                    Text("Focus Notes & Quick Capture")
                        .font(KaruTheme.headerTitle)
                        .foregroundStyle(KaruTheme.textPrimary)
                }
                Spacer()

                Button("Clear") {
                    scratchpadStore.clear()
                }
                .buttonStyle(.bordered)
            }

            TextEditor(text: $scratchpadStore.notes)
                .font(.system(size: 13, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(KaruTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Text("Notes automatically attach to your active trip travel log.")
                    .font(KaruTheme.captionMono)
                    .foregroundStyle(KaruTheme.textMuted)
                Spacer()
                if let last = scratchpadStore.lastSavedDate {
                    Text("Last saved \(formattedTime(last))")
                        .font(KaruTheme.captionMono)
                        .foregroundStyle(KaruTheme.textSecondary)
                }
            }
        }
        .padding(18)
        .frame(minWidth: 400, minHeight: 300)
        .background(KaruTheme.background)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
