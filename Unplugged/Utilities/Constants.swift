// Constants.swift
// Unplugged
//
// Central place for all app-wide constants.
// No magic strings should appear elsewhere in the codebase.

import Foundation

/// App-wide constants namespace.
enum AppConstants {
    // MARK: - App Identity
    static let bundleIdentifier = "com.anzydev.unplugged"
    static let appName = "Unplugged"
    static let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let appBuild: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    static let copyrightYear = "2024"
    static let githubURL = "https://github.com/anzydev/unplugged"

    // MARK: - Window Identifiers
    enum WindowID {
        static let settings = "settings-window"
        static let about = "about-window"
    }

    // MARK: - Notification Identifiers
    enum NotificationID {
        static let powerDisconnected = "com.anzydev.unplugged.powerDisconnected"
        static let powerRestored = "com.anzydev.unplugged.powerRestored"
        static let countdownUpdate = "com.anzydev.unplugged.countdownUpdate"
        static let shutdownImminent = "com.anzydev.unplugged.shutdownImminent"
        static let monitoringEnabled = "com.anzydev.unplugged.monitoringEnabled"
        static let monitoringDisabled = "com.anzydev.unplugged.monitoringDisabled"
    }

    // MARK: - Notification Category
    static let notificationCategoryID = "com.anzydev.unplugged.category"

    // MARK: - UserDefaults Keys
    enum DefaultsKey {
        static let launchAtLogin = "launchAtLogin"
        static let monitoringEnabled = "monitoringEnabled"
        static let countdownDuration = "countdownDuration"
        static let notificationsEnabled = "notificationsEnabled"
        static let countdownNotificationsEnabled = "countdownNotificationsEnabled"
        static let playSoundBeforeShutdown = "playSoundBeforeShutdown"
    }

    // MARK: - Timings
    /// The interval at which the countdown timer fires (1 second).
    static let countdownTickInterval: TimeInterval = 1.0

    /// Seconds remaining when the "shutdown imminent" notification fires.
    static let imminentShutdownThreshold = 10
}
