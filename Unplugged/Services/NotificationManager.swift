// NotificationManager.swift
// Unplugged
//
// Sends and manages local macOS notifications through UNUserNotificationCenter.
// Isolated to @MainActor so all published-state mutations are safely confined
// to the main thread without manual DispatchQueue dispatch.

import Foundation
@preconcurrency import UserNotifications
import AppKit

// MARK: - NotificationManager

/// Centralises all `UNUserNotificationCenter` interactions.
///
/// Call `requestAuthorization()` once on app launch. After that, use the
/// convenience `send*` methods to fire notifications without needing to
/// assemble `UNNotificationRequest` objects at the call site.
@MainActor
final class NotificationManager: NSObject, ObservableObject {

    // MARK: - Center

    private let center = UNUserNotificationCenter.current()

    // MARK: - Published State

    /// `true` if the user has granted notification permission.
    @Published private(set) var isAuthorised: Bool = false

    // MARK: - Init

    override init() {
        super.init()
        center.delegate = self
        refreshAuthorizationStatus()
    }

    // MARK: - Authorization

    /// Requests notification permission from the user.
    ///
    /// Should be called once early in the app lifecycle. If already granted,
    /// this is a lightweight no-op (the system handles the guard).
    func requestAuthorization() {
        Task {
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                self.isAuthorised = granted
            } catch {
                // Non-fatal — the app works without notifications.
                print("[NotificationManager] Authorization error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Send Helpers

    /// Sends a notification with the given title and body.
    ///
    /// - Parameters:
    ///   - title: The bold top line of the notification banner.
    ///   - body: The secondary descriptive line.
    ///   - identifier: A stable string used to deduplicate or cancel the notification.
    ///   - sound: Whether to play the default alert sound. Defaults to `false`.
    func sendNotification(
        title: String,
        body: String,
        identifier: String,
        sound: Bool = false
    ) {
        guard isAuthorised else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if sound {
            content.sound = .default
        }

        // Deliver immediately (trigger = nil fires at the next run loop opportunity).
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        Task {
            do {
                try await center.add(request)
            } catch {
                print("[NotificationManager] Failed to schedule '\(identifier)': \(error.localizedDescription)")
            }
        }
    }

    /// Notifies the user that external power was disconnected and a countdown has started.
    func sendPowerDisconnectedNotification(countdownSeconds: Int) {
        sendNotification(
            title: "External Power Disconnected",
            body: "Shutdown in \(formattedDuration(countdownSeconds)).",
            identifier: AppConstants.NotificationID.powerDisconnected,
            sound: true
        )
    }

    /// Notifies the user that power has been restored and the shutdown is cancelled.
    func sendPowerRestoredNotification() {
        sendNotification(
            title: "Power Restored",
            body: "Shutdown cancelled.",
            identifier: AppConstants.NotificationID.powerRestored
        )
        // Remove the earlier "disconnected" banner if it is still visible.
        center.removeDeliveredNotifications(withIdentifiers: [
            AppConstants.NotificationID.powerDisconnected,
            AppConstants.NotificationID.countdownUpdate
        ])
    }

    /// Sends a countdown-tick notification, updating the user on remaining time.
    ///
    /// Replaces the previous countdown notification to avoid spamming the
    /// Notification Centre with many banners.
    func sendCountdownNotification(remainingSeconds: Int, playSound: Bool = false) {
        sendNotification(
            title: "Shutdown Imminent",
            body: "System will shut down in \(formattedDuration(remainingSeconds)).",
            identifier: AppConstants.NotificationID.countdownUpdate,
            sound: playSound
        )
    }

    /// Notifies the user that monitoring has been enabled.
    func sendMonitoringEnabledNotification() {
        sendNotification(
            title: AppConstants.appName,
            body: "Power monitoring enabled.",
            identifier: AppConstants.NotificationID.monitoringEnabled
        )
    }

    /// Notifies the user that monitoring has been disabled.
    func sendMonitoringDisabledNotification() {
        sendNotification(
            title: AppConstants.appName,
            body: "Power monitoring disabled.",
            identifier: AppConstants.NotificationID.monitoringDisabled
        )
    }

    // MARK: - Cleanup

    /// Removes all pending (not yet delivered) notifications.
    func removeAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    /// Removes all delivered notifications from Notification Centre.
    func removeAllDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
    }

    // MARK: - Private Helpers

    private func refreshAuthorizationStatus() {
        Task {
            let settings = await center.notificationSettings()
            self.isAuthorised = settings.authorizationStatus == .authorized
        }
    }

    private func formattedDuration(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            let secs = seconds % 60
            if secs == 0 {
                return "\(minutes) minute\(minutes == 1 ? "" : "s")"
            }
            return "\(minutes)m \(secs)s"
        }
        return "\(seconds) second\(seconds == 1 ? "" : "s")"
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Allows notifications to be shown even when the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
