import SwiftUI
import AppKit

@main
struct KaruApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandMenu("Karu") {
                Button("Toggle Floating Flight Card") {
                    appDelegate.toggleFloatingHUD()
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])

                Divider()

                Button("Pilot's Logbook") {
                    appDelegate.openLogbookWindow()
                }
                .keyboardShortcut("l", modifiers: .command)

                Button("Aircraft Hangar") {
                    appDelegate.openGarageWindow()
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Button("Desktop Widgets Simulator") {
                    appDelegate.openWidgetSimulatorWindow()
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])

                Button("Pre-Flight Cockpit Briefing...") {
                    appDelegate.replayOnboarding()
                }

                Button("Preferences & Rules...") {
                    appDelegate.openSettingsWindow()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
