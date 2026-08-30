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
                Button("Toggle Floating HUD") {
                    appDelegate.toggleFloatingHUD()
                }
                .keyboardShortcut("f", modifiers: [.command, .shift])

                Divider()

                Button("Open Garage") {
                    appDelegate.openGarageWindow()
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])

                Button("Preferences & Rules...") {
                    appDelegate.openSettingsWindow()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}
