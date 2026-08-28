import Foundation

/// Triple-state categorization for running macOS applications.
public enum AppFocusCategory: String, Codable, Sendable, CaseIterable {
    /// Approved productive workspace (IDE, terminal, text editor, study tools) -> 100 km/h cruising.
    case focusWorkspace
    /// Distraction hazard (social media, chat apps, games, streaming) -> 0 km/h traffic gridlock.
    case distractionHazard
    /// Neutral utility (Finder, System Settings, 1Password, Calculator) -> Maintains previous state.
    case neutralUtility

    public var title: String {
        switch self {
        case .focusWorkspace:
            return "Focus Workspace"
        case .distractionHazard:
            return "Distraction Hazard"
        case .neutralUtility:
            return "Neutral Utility"
        }
    }
}

/// A specific filter rule mapping a macOS bundle identifier to an AppFocusCategory.
public struct AppFilterRule: Identifiable, Codable, Sendable, Equatable, Hashable {
    public var id: String { bundleIdentifier }
    public let bundleIdentifier: String
    public let appName: String
    public var category: AppFocusCategory
    public var isCustomOverride: Bool

    public init(
        bundleIdentifier: String,
        appName: String,
        category: AppFocusCategory,
        isCustomOverride: Bool = false
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.category = category
        self.isCustomOverride = isCustomOverride
    }
}

/// Built-in curated app rule presets for different disciplines.
public enum FocusPreset: String, Codable, Sendable, CaseIterable {
    case developer
    case student
    case writer
    case creative

    public var displayName: String {
        switch self {
        case .developer: return "Software Engineer"
        case .student: return "Student & Researcher"
        case .writer: return "Author & Creator"
        case .creative: return "Designer & Artist"
        }
    }

    /// Curated default rules for this preset.
    public var defaultRules: [AppFilterRule] {
        var rules: [AppFilterRule] = []

        // Universal distractions across all presets
        let commonDistractions: [(String, String)] = [
            ("com.hnc.Discord", "Discord"),
            ("com.tinyspeck.slackmacgap", "Slack"),
            ("com.valvesoftware.steam", "Steam"),
            ("ru.keepcoder.Telegram", "Telegram"),
            ("com.facebook.archon", "Messenger"),
            ("com.atebits.Tweetie2", "Twitter"),
            ("com.spotify.client", "Spotify") // Audio runs in background; switching into app is distraction
        ]
        for (bundle, name) in commonDistractions {
            rules.append(AppFilterRule(bundleIdentifier: bundle, appName: name, category: .distractionHazard))
        }

        // Preset-specific focus tools
        switch self {
        case .developer:
            let devTools: [(String, String)] = [
                ("com.apple.dt.Xcode", "Xcode"),
                ("com.microsoft.VSCode", "VS Code"),
                ("com.googlecode.iterm2", "iTerm"),
                ("com.apple.Terminal", "Terminal"),
                ("dev.warp.Warp-Stable", "Warp"),
                ("com.sublimetext.4", "Sublime Text"),
                ("com.tinyapp.TablePlus", "TablePlus"),
                ("com.figma.Desktop", "Figma"),
                ("com.github.GitHubClient", "GitHub Desktop"),
                ("com.postmanlabs.mac", "Postman"),
                ("com.docker.docker", "Docker")
            ]
            for (bundle, name) in devTools {
                rules.append(AppFilterRule(bundleIdentifier: bundle, appName: name, category: .focusWorkspace))
            }

        case .student:
            let studentTools: [(String, String)] = [
                ("md.obsidian", "Obsidian"),
                ("notion.id", "Notion"),
                ("com.apple.Preview", "Preview"),
                ("com.apple.iBooksX", "Apple Books"),
                ("net.ankiweb.dtop", "Anki"),
                ("org.zotero.zotero", "Zotero"),
                ("com.apple.Safari", "Safari"),
                ("com.google.Chrome", "Google Chrome")
            ]
            for (bundle, name) in studentTools {
                rules.append(AppFilterRule(bundleIdentifier: bundle, appName: name, category: .focusWorkspace))
            }

        case .writer:
            let writerTools: [(String, String)] = [
                ("com.ulyssesapp.mac", "Ulysses"),
                ("com.literatureandlatte.scrivener3", "Scrivener"),
                ("com.microsoft.Word", "Microsoft Word"),
                ("com.apple.iWork.Pages", "Pages"),
                ("com.iawriter.iawriterx", "iA Writer"),
                ("md.obsidian", "Obsidian")
            ]
            for (bundle, name) in writerTools {
                rules.append(AppFilterRule(bundleIdentifier: bundle, appName: name, category: .focusWorkspace))
            }

        case .creative:
            let creativeTools: [(String, String)] = [
                ("com.adobe.Photoshop", "Adobe Photoshop"),
                ("com.adobe.Illustrator", "Adobe Illustrator"),
                ("org.blenderfoundation.blender", "Blender"),
                ("com.apple.FinalCut", "Final Cut Pro"),
                ("com.apple.Logic10", "Logic Pro"),
                ("com.figma.Desktop", "Figma")
            ]
            for (bundle, name) in creativeTools {
                rules.append(AppFilterRule(bundleIdentifier: bundle, appName: name, category: .focusWorkspace))
            }
        }

        // Universal neutral utilities
        let neutralUtilities: [(String, String)] = [
            ("com.apple.finder", "Finder"),
            ("com.apple.systempreferences", "System Settings"),
            ("com.apple.calculator", "Calculator"),
            ("com.1password.1password", "1Password"),
            ("com.bitwarden.desktop", "Bitwarden"),
            ("com.apple.keychainaccess", "Keychain Access"),
            ("com.apple.ActivityMonitor", "Activity Monitor")
        ]
        for (bundle, name) in neutralUtilities {
            rules.append(AppFilterRule(bundleIdentifier: bundle, appName: name, category: .neutralUtility))
        }

        return rules
    }
}
