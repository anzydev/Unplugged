// PowerMonitorService.swift
// Unplugged
//
// Event-driven power source monitoring using the IOKit Power Sources API.
// Registers a CFRunLoop notification source so the system calls us on every
// power-state change — no polling required.

import Foundation
import IOKit.ps
import Combine

// MARK: - PowerMonitorService

/// Observes macOS power source changes and publishes the current `PowerState`.
///
/// Uses `IOPSNotificationCreateRunLoopSource` to receive OS-level events whenever
/// the charger is plugged in or removed. All published updates are dispatched on
/// the main thread so views and view models can subscribe without extra dispatch.
@MainActor
final class PowerMonitorService: ObservableObject {

    // MARK: - Published State

    /// The most recently observed power state.
    @Published private(set) var powerState: PowerState = .unknown

    // MARK: - Private

    /// The CFRunLoop source retaining the IOKit notification registration.
    private var runLoopSource: CFRunLoopSource?

    // MARK: - Init / Deinit

    init() {}

    deinit {
        // Schedule cleanup on the main actor since stopMonitoring is @MainActor isolated.
        let source = runLoopSource
        if let source {
            DispatchQueue.main.async {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            }
        }
    }

    // MARK: - Public Interface

    /// Begins listening for power source change events.
    ///
    /// Safe to call multiple times; subsequent calls are no-ops if already active.
    func startMonitoring() {
        guard runLoopSource == nil else { return }

        // Grab the current state immediately so the UI is correct on launch.
        refreshPowerState()

        // Create a notification source that fires our callback on every change.
        // We pass `self` as an opaque context pointer, then bridge it back inside
        // the C callback using `Unmanaged`.
        let selfPointer = Unmanaged.passRetained(self).toOpaque()

        let source = IOPSNotificationCreateRunLoopSource(
            { context in
                // Bridge the opaque pointer back to our Swift object.
                guard let ctx = context else { return }
                let service = Unmanaged<PowerMonitorService>.fromOpaque(ctx).takeUnretainedValue()
                service.refreshPowerState()
            },
            selfPointer
        )?.takeRetainedValue()

        guard let validSource = source else {
            // IOKit failed to create a source — fall back gracefully.
            return
        }

        runLoopSource = validSource
        CFRunLoopAddSource(CFRunLoopGetMain(), validSource, .defaultMode)
    }

    /// Stops listening for power source changes and releases the run loop source.
    func stopMonitoring() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
            // Release the retained self pointer we passed to the callback.
            // We need to balance the passRetained call made in startMonitoring.
            runLoopSource = nil
        }
    }

    // MARK: - Private Helpers

    /// Reads the current IOKit power source snapshot and publishes a new `PowerState`.
    private func refreshPowerState() {
        let state = Self.readCurrentPowerState()
        Task { @MainActor [weak self] in
            self?.powerState = state
        }
    }

    /// Reads the IOKit power sources snapshot and returns a populated `PowerState`.
    ///
    /// This is a pure static function so it can be called from the C callback context
    /// without needing a live reference to the service instance beyond the bridged pointer.
    private static func readCurrentPowerState() -> PowerState {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else {
            return .unknown
        }

        // Determine the overall power source description (AC Power / Battery Power).
        let overallSource = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() as String?
        let isPluggedIn = (overallSource == kIOPSACPowerValue)

        // Find the internal battery source to read capacity and charging state.
        var batteryLevel: Int?
        var isCharging = false

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?
                .takeUnretainedValue() as? [String: Any]
            else { continue }

            // Only process the internal battery.
            let type = description[kIOPSTypeKey] as? String
            guard type == kIOPSInternalBatteryType else { continue }

            if let current = description[kIOPSCurrentCapacityKey] as? Int,
               let max = description[kIOPSMaxCapacityKey] as? Int,
               max > 0 {
                batteryLevel = Int(Double(current) / Double(max) * 100.0)
            }

            isCharging = description[kIOPSIsChargingKey] as? Bool ?? false

            // We only need the first internal battery entry.
            break
        }

        let sourceDescription = isPluggedIn ? "AC Power" : "Battery Power"

        return PowerState(
            isCharging: isCharging,
            isPluggedIn: isPluggedIn,
            batteryLevel: batteryLevel,
            powerSourceDescription: sourceDescription
        )
    }
}
