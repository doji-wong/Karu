import Foundation

/// Defines how Karu is presented on macOS.
public enum AppPresentationMode: String, Codable, Sendable, CaseIterable {
    /// Standard application visible in macOS Dock with dynamic telemetry + Menu Bar HUD + Floating HUD.
    case standardDock = "standardDock"
    /// Stealth mode residing exclusively in the top Menu Bar and Floating HUD (hidden from Dock).
    case menuBarOnly = "menuBarOnly"

    public var displayName: String {
        switch self {
        case .standardDock:
            return "Standard Cockpit (Dock + Menu Bar)"
        case .menuBarOnly:
            return "Stealth Recon (Menu Bar Only)"
        }
    }
}

/// Defines the readout format displayed on the macOS Dock tile badge.
public enum DockBadgeStyle: String, Codable, Sendable, CaseIterable {
    /// Shows remaining flight minutes (e.g. "24m") when cruising.
    case timeRemaining = "timeRemaining"
    /// Shows current flight velocity in knots (e.g. "540") when cruising.
    case airspeedKts = "airspeedKts"
    /// No text badge on the Dock icon.
    case none = "none"

    public var displayName: String {
        switch self {
        case .timeRemaining:
            return "Remaining Time (e.g. 24m)"
        case .airspeedKts:
            return "Airspeed Velocity (e.g. 540 kts)"
        case .none:
            return "No Text Badge"
        }
    }
}

/// Pilot focus mission domain selected during onboarding or preferences.
public enum PilotRoleMission: String, Codable, Sendable, CaseIterable {
    case developer = "developer"
    case writer = "writer"
    case student = "student"
    case designer = "designer"

    public var title: String {
        switch self {
        case .developer: return "Software & Systems Engineering"
        case .writer: return "Writing & Knowledge Craft"
        case .student: return "Academic Research & Study"
        case .designer: return "Product & Visual Design"
        }
    }

    public var iconSymbol: String {
        switch self {
        case .developer: return "curlybraces"
        case .writer: return "pencil.and.outline"
        case .student: return "graduationcap.fill"
        case .designer: return "paintbrush.pointed.fill"
        }
    }

    public var suggestedFocusPreset: FocusPreset {
        switch self {
        case .developer: return .developer
        case .writer: return .writer
        case .student: return .student
        case .designer: return .developer
        }
    }
}

/// 100% Local-First User & Avionics Preferences.
public struct KaruPreferences: Codable, Sendable, Equatable {
    public var hasCompletedOnboarding: Bool
    public var presentationMode: AppPresentationMode
    public var dockBadgeStyle: DockBadgeStyle
    public var enableDockTileGraphics: Bool
    public var dailyFlightGoalMinutes: Int
    public var selectedMissionRole: PilotRoleMission
    public var launchAtLogin: Bool
    public var destinationDurations: [String: Int]

    public static let defaultDestinationDurations: [String: Int] = [
        "CTS": 25,
        "HND": 25,
        "CDG": 30,
        "LHR": 45,
        "JFK": 50,
        "SFO": 50,
        "YYZ": 45,
        "MNL": 30,
        "SIN": 60,
        "SYD": 60,
        "ICN": 35,
        "ZRH": 40,
        "KEF": 45,
        "VKO": 75,
        "MEX": 90,
        "AKL": 90
    ]

    public init(
        hasCompletedOnboarding: Bool = false,
        presentationMode: AppPresentationMode = .standardDock,
        dockBadgeStyle: DockBadgeStyle = .timeRemaining,
        enableDockTileGraphics: Bool = true,
        dailyFlightGoalMinutes: Int = 240, // 4 hours standard focus quota
        selectedMissionRole: PilotRoleMission = .developer,
        launchAtLogin: Bool = false,
        destinationDurations: [String: Int] = KaruPreferences.defaultDestinationDurations
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.presentationMode = presentationMode
        self.dockBadgeStyle = dockBadgeStyle
        self.enableDockTileGraphics = enableDockTileGraphics
        self.dailyFlightGoalMinutes = dailyFlightGoalMinutes
        self.selectedMissionRole = selectedMissionRole
        self.launchAtLogin = launchAtLogin
        self.destinationDurations = destinationDurations
    }

    public enum CodingKeys: String, CodingKey {
        case hasCompletedOnboarding
        case presentationMode
        case dockBadgeStyle
        case enableDockTileGraphics
        case dailyFlightGoalMinutes
        case selectedMissionRole
        case launchAtLogin
        case destinationDurations
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
        self.presentationMode = try container.decodeIfPresent(AppPresentationMode.self, forKey: .presentationMode) ?? .standardDock
        self.dockBadgeStyle = try container.decodeIfPresent(DockBadgeStyle.self, forKey: .dockBadgeStyle) ?? .timeRemaining
        self.enableDockTileGraphics = try container.decodeIfPresent(Bool.self, forKey: .enableDockTileGraphics) ?? true
        self.dailyFlightGoalMinutes = try container.decodeIfPresent(Int.self, forKey: .dailyFlightGoalMinutes) ?? 240
        self.selectedMissionRole = try container.decodeIfPresent(PilotRoleMission.self, forKey: .selectedMissionRole) ?? .developer
        self.launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        self.destinationDurations = try container.decodeIfPresent([String: Int].self, forKey: .destinationDurations) ?? KaruPreferences.defaultDestinationDurations
    }

    public func targetDurationMinutes(for destinationCode: String) -> Int {
        destinationDurations[destinationCode.uppercased()] ?? Self.defaultDestinationDurations[destinationCode.uppercased()] ?? 25
    }

    public mutating func setTargetDurationMinutes(_ minutes: Int, for destinationCode: String) {
        destinationDurations[destinationCode.uppercased()] = max(5, minutes)
    }
}
