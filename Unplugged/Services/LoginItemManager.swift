// LoginItemManager.swift
// Unplugged
//
// Manages "Launch at Login" registration using the modern ServiceManagement
// framework (macOS 13+). Reads actual system state from SMAppService rather
// than relying solely on local UserDefaults.

import Foundation
import ServiceManagement

// MARK: - LoginItemManager

/// Registers and unregisters the app as a login item via `SMAppService`.
///
/// The actual enabled/disabled status is authoritative from `SMAppService.mainApp.status`,
/// not from any local flag — the user can disable the login item via System Settings
/// independently of the app's UI.
@MainActor
final class LoginItemManager: ObservableObject {

    // MARK: - Published State

    /// The current registration status of the app as a login item.
    @Published private(set) var status: SMAppService.Status = .notRegistered

    // MARK: - Init

    init() {
        refreshStatus()
    }

    // MARK: - Public Interface

    /// Whether the app is currently registered to launch at login.
    var isEnabled: Bool {
        status == .enabled
    }

    /// Enables or disables launch-at-login.
    ///
    /// - Parameter enabled: `true` to register, `false` to unregister.
    /// - Returns: A `LoginItemResult` indicating success or failure with a message.
    @discardableResult
    func setEnabled(_ enabled: Bool) -> LoginItemResult {
        let service = SMAppService.mainApp
        do {
            if enabled {
                // Guard against registering when already registered to avoid
                // redundant system calls that could surface confusing errors.
                guard service.status != .enabled else {
                    refreshStatus()
                    return .success
                }
                try service.register()
            } else {
                guard service.status != .notRegistered else {
                    refreshStatus()
                    return .success
                }
                try service.unregister()
            }
            refreshStatus()
            return .success
        } catch {
            refreshStatus()
            return .failure(error.localizedDescription)
        }
    }

    /// Opens the Login Items panel in System Settings so the user can manage items manually.
    func openSystemSettingsLoginItems() {
        SMAppService.openSystemSettingsLoginItems()
    }

    // MARK: - Private

    private func refreshStatus() {
        status = SMAppService.mainApp.status
    }
}

// MARK: - LoginItemResult

/// The result of a login item registration/unregistration attempt.
enum LoginItemResult {
    case success
    case failure(String)
}
