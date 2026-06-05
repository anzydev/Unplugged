// PowerState.swift
// Unplugged
//
// Data models representing the current power state of the system
// and the available countdown duration options.

import Foundation

// MARK: - PowerState

/// A value type representing a snapshot of the system's current power state.
struct PowerState: Equatable {
    /// Whether the battery is actively charging.
    let isCharging: Bool

    /// Whether an external power source (AC adapter) is connected.
    let isPluggedIn: Bool

    /// Battery level as a percentage (0–100). Nil if battery info is unavailable.
    let batteryLevel: Int?

    /// Human-readable description of the current power source (e.g., "AC Power", "Battery Power").
    let powerSourceDescription: String

    // MARK: - Defaults

    /// A sensible initial state before the first IOKit reading arrives.
    static let unknown = PowerState(
        isCharging: false,
        isPluggedIn: false,
        batteryLevel: nil,
        powerSourceDescription: "Unknown"
    )
}

// MARK: - CountdownDuration

/// The configurable durations available for the shutdown countdown timer.
enum CountdownDuration: Int, CaseIterable, Identifiable {
    case tenSeconds = 10
    case thirtySeconds = 30
    case sixtySeconds = 60
    case fiveMinutes = 300

    // MARK: - Identifiable
    var id: Int { rawValue }

    // MARK: - Display

    /// The user-facing label shown in the Settings picker and menu.
    var displayLabel: String {
        switch self {
        case .tenSeconds:    return "10 Seconds"
        case .thirtySeconds: return "30 Seconds"
        case .sixtySeconds:  return "1 Minute"
        case .fiveMinutes:   return "5 Minutes"
        }
    }

    /// The underlying duration as a `TimeInterval`.
    var timeInterval: TimeInterval {
        TimeInterval(rawValue)
    }

    /// The default duration used on first launch.
    static let defaultDuration: CountdownDuration = .thirtySeconds

    /// Safely initialises from a raw `Int`, falling back to the default.
    static func fromRawValue(_ value: Int) -> CountdownDuration {
        CountdownDuration(rawValue: value) ?? .defaultDuration
    }
}
