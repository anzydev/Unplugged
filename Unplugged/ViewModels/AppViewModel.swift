// AppViewModel.swift
// Unplugged
//
// Central orchestration layer for the application.
// Owns all services, wires power-state changes to countdown logic, and
// exposes derived state that views consume directly.

import Foundation
import Combine
import AppKit

// MARK: - AppViewModel

/// The single source of truth for application state.
///
/// `AppViewModel` coordinates between `PowerMonitorService`, `ShutdownManager`,
/// `NotificationManager`, and `LoginItemManager`. It reacts to power-state
/// changes and translates them into countdown lifecycle calls, notifications,
/// and updated menu bar presentation data.
///
/// Isolated to `@MainActor` because every property it touches is read by SwiftUI.
@MainActor
final class AppViewModel: ObservableObject {

    // MARK: - Services (injected / owned)

    let powerMonitor = PowerMonitorService()
    let shutdownManager = ShutdownManager()
    let notificationManager = NotificationManager()
    let loginItemManager = LoginItemManager()

    // MARK: - Persisted Settings (@AppStorage)
    // These are the canonical settings values; views bind to them directly.

    @Published var monitoringEnabled: Bool {
        didSet {
            UserDefaults.standard.set(monitoringEnabled, forKey: AppConstants.DefaultsKey.monitoringEnabled)
            if monitoringEnabled {
                powerMonitor.startMonitoring()
                if notificationsEnabled {
                    notificationManager.sendMonitoringEnabledNotification()
                }
            } else {
                // Cancel any active countdown when monitoring is switched off.
                if shutdownManager.isCountdownActive {
                    shutdownManager.cancelCountdown()
                }
                powerMonitor.stopMonitoring()
                if notificationsEnabled {
                    notificationManager.sendMonitoringDisabledNotification()
                }
            }
        }
    }

    @Published var countdownDurationRaw: Int {
        didSet {
            UserDefaults.standard.set(countdownDurationRaw, forKey: AppConstants.DefaultsKey.countdownDuration)
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: AppConstants.DefaultsKey.notificationsEnabled)
        }
    }

    @Published var countdownNotificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(countdownNotificationsEnabled, forKey: AppConstants.DefaultsKey.countdownNotificationsEnabled)
        }
    }

    @Published var playSoundBeforeShutdown: Bool {
        didSet {
            UserDefaults.standard.set(playSoundBeforeShutdown, forKey: AppConstants.DefaultsKey.playSoundBeforeShutdown)
        }
    }

    // MARK: - Derived / Transient State

    /// The last known `isPluggedIn` state — used to detect transitions.
    private var previouslyPluggedIn: Bool? = nil

    /// Tracks whether a shutdown error alert needs to be shown.
    @Published var shutdownError: String? = nil

    // MARK: - Combine

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        // Load persisted settings from UserDefaults (with defaults on first launch).
        let defaults = UserDefaults.standard
        monitoringEnabled = defaults.object(forKey: AppConstants.DefaultsKey.monitoringEnabled) as? Bool
            ?? AppSettingsDefaults.monitoringEnabled
        countdownDurationRaw = defaults.object(forKey: AppConstants.DefaultsKey.countdownDuration) as? Int
            ?? AppSettingsDefaults.countdownDuration
        notificationsEnabled = defaults.object(forKey: AppConstants.DefaultsKey.notificationsEnabled) as? Bool
            ?? AppSettingsDefaults.notificationsEnabled
        countdownNotificationsEnabled = defaults.object(forKey: AppConstants.DefaultsKey.countdownNotificationsEnabled) as? Bool
            ?? AppSettingsDefaults.countdownNotificationsEnabled
        playSoundBeforeShutdown = defaults.object(forKey: AppConstants.DefaultsKey.playSoundBeforeShutdown) as? Bool
            ?? AppSettingsDefaults.playSoundBeforeShutdown

        setupBindings()
        notificationManager.requestAuthorization()

        if monitoringEnabled {
            powerMonitor.startMonitoring()
        }
    }

    // MARK: - Computed Properties

    /// The `CountdownDuration` derived from the persisted raw integer.
    var countdownDuration: CountdownDuration {
        CountdownDuration.fromRawValue(countdownDurationRaw)
    }

    /// SF Symbol name for the menu bar icon, reflecting the current power state.
    var menuBarIconName: String {
        if shutdownManager.isCountdownActive {
            return "exclamationmark.triangle.fill"
        }
        if powerMonitor.powerState.isPluggedIn {
            return powerMonitor.powerState.isCharging ? "bolt.fill" : "bolt.badge.checkmark.fill"
        }
        return "bolt.slash.fill"
    }

    /// The formatted countdown string shown in the menu bar title when active.
    var menuBarCountdownText: String? {
        guard shutdownManager.isCountdownActive else { return nil }
        return formatTime(shutdownManager.remainingSeconds)
    }

    /// Human-readable battery level string.
    var batteryLevelText: String {
        if let level = powerMonitor.powerState.batteryLevel {
            return "\(level)%"
        }
        return "—"
    }

    /// A concise status line for display in the menu bar popover.
    var statusSummary: String {
        if shutdownManager.isCountdownActive {
            return "Shutting down in \(formatTime(shutdownManager.remainingSeconds))"
        }
        if !monitoringEnabled {
            return "Monitoring paused"
        }
        if powerMonitor.powerState.isPluggedIn {
            return powerMonitor.powerState.isCharging ? "Charging" : "Plugged in, not charging"
        }
        return "On battery power"
    }

    // MARK: - Actions

    /// Toggles power monitoring on/off.
    func toggleMonitoring() {
        monitoringEnabled.toggle()
    }

    /// Manually cancels an in-progress shutdown countdown.
    func cancelShutdown() {
        guard shutdownManager.isCountdownActive else { return }
        shutdownManager.cancelCountdown()
        notificationManager.removeAllPendingNotifications()
        if notificationsEnabled {
            notificationManager.sendPowerRestoredNotification()
        }
    }

    // MARK: - Private: Binding Setup

    private func setupBindings() {
        // React to power state changes published by the monitor service.
        powerMonitor.$powerState
            .dropFirst() // Ignore the initial `.unknown` emission on subscription.
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.handlePowerStateChange(newState)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private: Core Logic

    /// Called whenever the power source state changes.
    ///
    /// Compares the new state against the last known state to detect
    /// plug-in / plug-out *transitions*, which avoids firing duplicate
    /// countdowns when the callback fires without a real state change.
    private func handlePowerStateChange(_ newState: PowerState) {
        let nowPluggedIn = newState.isPluggedIn

        // Only act on genuine transitions, not repeated identical events.
        guard nowPluggedIn != previouslyPluggedIn else {
            previouslyPluggedIn = nowPluggedIn
            return
        }
        previouslyPluggedIn = nowPluggedIn

        if nowPluggedIn {
            // Power restored — cancel any running countdown.
            if shutdownManager.isCountdownActive {
                shutdownManager.cancelCountdown()
                notificationManager.removeAllPendingNotifications()
                if notificationsEnabled {
                    notificationManager.sendPowerRestoredNotification()
                }
            }
        } else {
            // Power removed — start the shutdown countdown if monitoring is enabled.
            guard monitoringEnabled else { return }

            if notificationsEnabled {
                notificationManager.sendPowerDisconnectedNotification(
                    countdownSeconds: countdownDuration.rawValue
                )
            }

            shutdownManager.startCountdown(
                duration: countdownDuration,
                onTick: { @Sendable [weak self] remaining in
                    Task { @MainActor [weak self] in
                        self?.handleCountdownTick(remaining: remaining)
                    }
                },
                onComplete: { @Sendable [weak self] in
                    Task { @MainActor [weak self] in
                        self?.handleCountdownComplete()
                    }
                }
            )
        }
    }

    /// Called every second during an active countdown.
    private func handleCountdownTick(remaining: Int) {
        // Send countdown notification at the imminent-shutdown threshold.
        if remaining == AppConstants.imminentShutdownThreshold {
            if notificationsEnabled && countdownNotificationsEnabled {
                notificationManager.sendCountdownNotification(
                    remainingSeconds: remaining,
                    playSound: playSoundBeforeShutdown
                )
            }
            if playSoundBeforeShutdown {
                NSSound.beep()
            }
        }
    }

    /// Called when the countdown reaches zero — executes the system shutdown.
    private func handleCountdownComplete() {
        let result = shutdownManager.executeShutdown()
        if case .failure(let message) = result {
            // Surface the error so the UI can display an alert.
            shutdownError = message
        }
    }

    // MARK: - Utilities

    /// Formats a duration in seconds into a human-readable MM:SS or seconds string.
    func formatTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            let secs = seconds % 60
            return String(format: "%d:%02d", minutes, secs)
        }
        return "\(seconds)s"
    }
}
