// AppSettings.swift
// Unplugged
//
// Centralised type-safe access to all persisted application settings.
// All @AppStorage keys live here — no string literals elsewhere.

import Foundation

/// A namespace for all UserDefaults / AppStorage key strings and their default values.
///
/// Keeping defaults here avoids scattered magic numbers and makes it trivial
/// to reason about the full settings surface area of the app.
enum AppSettingsDefaults {
    /// Whether the app should be registered as a Login Item on first launch.
    static let launchAtLogin: Bool = false

    /// Whether power monitoring is active on launch.
    static let monitoringEnabled: Bool = true

    /// Raw integer value corresponding to `CountdownDuration.rawValue`.
    static let countdownDuration: Int = CountdownDuration.defaultDuration.rawValue

    /// Whether user-facing notifications (power connect/disconnect) are enabled.
    static let notificationsEnabled: Bool = true

    /// Whether intermediate countdown-tick notifications are sent.
    static let countdownNotificationsEnabled: Bool = true

    /// Whether a system alert sound plays in the final seconds before shutdown.
    static let playSoundBeforeShutdown: Bool = true
}
