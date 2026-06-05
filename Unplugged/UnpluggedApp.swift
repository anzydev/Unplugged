// UnpluggedApp.swift
// Unplugged
//
// Application entry point.
// Declares the MenuBarExtra and auxiliary windows (Settings, About).
// The app runs as a background agent (LSUIElement = true in Info.plist),
// so there is no Dock icon or standard menu bar menu.

import SwiftUI

@main
struct UnpluggedApp: App {

    // Single ViewModel shared across all scenes.
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {

        // ── Menu Bar Extra ─────────────────────────────────────────────────
        // The title shows the countdown timer when active; otherwise it's empty
        // and only the icon is visible (matching Apple first-party utilities).
        MenuBarExtra {
            MenuBarView(viewModel: viewModel)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)

        // ── Settings Window ────────────────────────────────────────────────
        Window("Settings", id: AppConstants.WindowID.settings) {
            SettingsView(viewModel: viewModel)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        // ── About Window ───────────────────────────────────────────────────
        Window("About Unplugged", id: AppConstants.WindowID.about) {
            AboutView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    // MARK: - Menu Bar Label

    /// Dynamic label that shows the appropriate SF Symbol and optional countdown text.
    @ViewBuilder
    private var menuBarLabel: some View {
        if let countdownText = viewModel.menuBarCountdownText {
            // Show icon + remaining time during active countdown.
            HStack(spacing: 3) {
                Image(systemName: viewModel.menuBarIconName)
                    .font(.system(size: 12, weight: .medium))
                Text(countdownText)
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
            }
        } else {
            // Standard icon-only appearance.
            Image(systemName: viewModel.menuBarIconName)
                .font(.system(size: 14, weight: .medium))
        }
    }
}
