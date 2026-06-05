// ShutdownManager.swift
// Unplugged
//
// Manages the shutdown countdown timer and executes the system shutdown.
// All state mutations are confined to the main actor to guarantee thread safety
// and seamless integration with SwiftUI's observation system.

import Foundation
import AppKit

// MARK: - ShutdownManager

/// Coordinates the countdown timer and system shutdown logic.
///
/// The manager is intentionally decoupled from the power monitor — it receives
/// explicit `startCountdown` / `cancelCountdown` calls from `AppViewModel`, which
/// acts as the orchestration layer.
@MainActor
final class ShutdownManager: ObservableObject {

    // MARK: - Published State

    /// `true` while the shutdown countdown is in progress.
    @Published private(set) var isCountdownActive: Bool = false

    /// Remaining seconds in the active countdown. `0` when idle.
    @Published private(set) var remainingSeconds: Int = 0

    // MARK: - Private

    private var timer: Timer?
    /// The full duration of the current (or most-recent) countdown, used to compute progress.
    private(set) var totalDuration: Int = 0

    // MARK: - Init / Deinit

    init() {}

    deinit {
        // Timer.invalidate() is documented as thread-safe.
        // We dispatch to main to stay consistent with the @MainActor class isolation.
        let t = timer
        DispatchQueue.main.async { t?.invalidate() }
    }

    // MARK: - Public Interface

    /// Starts a shutdown countdown of the specified duration.
    ///
    /// If a countdown is already in progress, this call is a no-op to prevent
    /// duplicate timers from racing against each other.
    ///
    /// - Parameter duration: The `CountdownDuration` selected by the user in Settings.
    /// - Parameter onTick: Optional closure called on every second tick, receiving remaining seconds.
    /// - Parameter onComplete: Closure called when the countdown reaches zero.
    func startCountdown(
        duration: CountdownDuration,
        onTick: (@Sendable (Int) -> Void)? = nil,
        onComplete: @Sendable @escaping () -> Void
    ) {
        guard !isCountdownActive else { return }

        totalDuration = duration.rawValue
        remainingSeconds = duration.rawValue
        isCountdownActive = true

        timer = Timer.scheduledTimer(
            withTimeInterval: AppConstants.countdownTickInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.remainingSeconds -= 1
                onTick?(self.remainingSeconds)

                if self.remainingSeconds <= 0 {
                    self.stopTimer()
                    onComplete()
                }
            }
        }
        // Ensure the timer fires even when the run loop is processing menu events.
        RunLoop.main.add(timer!, forMode: .common)
    }

    /// Cancels an in-progress countdown.
    ///
    /// Safe to call when no countdown is active (is a no-op).
    func cancelCountdown() {
        stopTimer()
    }

    // MARK: - Shutdown Execution

    /// Executes a graceful macOS shutdown via AppleScript.
    ///
    /// Uses `System Events` (preferred over `Finder`) for system-level operations.
    /// The app must be non-sandboxed and the user must have granted Automation permission.
    ///
    /// - Returns: A `ShutdownResult` indicating success or a descriptive failure.
    func executeShutdown() -> ShutdownResult {
        let source = "tell application \"System Events\" to shut down"
        guard let script = NSAppleScript(source: source) else {
            return .failure("Failed to construct AppleScript for shutdown.")
        }

        var errorDict: NSDictionary?
        script.executeAndReturnError(&errorDict)

        if let error = errorDict {
            let message = error[NSAppleScript.errorMessage] as? String
                ?? error[NSAppleScript.errorNumber].map { "Error \($0)" }
                ?? "Unknown AppleScript error."
            return .failure(message)
        }

        return .success
    }

    // MARK: - Computed Properties

    /// Progress from 0.0 (full countdown) to 1.0 (expired), used for progress indicators.
    var countdownProgress: Double {
        guard totalDuration > 0 else { return 0 }
        let elapsed = totalDuration - remainingSeconds
        return min(1.0, Double(elapsed) / Double(totalDuration))
    }

    // MARK: - Private Helpers

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isCountdownActive = false
        remainingSeconds = 0
        totalDuration = 0
    }
}

// MARK: - ShutdownResult

/// The result of a shutdown execution attempt.
enum ShutdownResult {
    case success
    case failure(String)

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .failure(let msg) = self { return msg }
        return nil
    }
}
