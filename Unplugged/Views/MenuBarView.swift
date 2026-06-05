// MenuBarView.swift
// Unplugged
//
// The primary user interface displayed inside the MenuBarExtra popover.
// Follows Apple HIG for menu bar utility content: compact, scannable,
// action-oriented, with no decorative chrome.

import SwiftUI

// MARK: - MenuBarView

struct MenuBarView: View {

    @ObservedObject var viewModel: AppViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ─────────────────────────────────────────────────────
            headerSection
            Divider()

            // ── Countdown (conditional) ────────────────────────────────────
            if viewModel.shutdownManager.isCountdownActive {
                countdownSection
                Divider()
            }

            // ── Actions ────────────────────────────────────────────────────
            actionsSection
            Divider()

            // ── App actions ────────────────────────────────────────────────
            appActionsSection
        }
        .frame(width: 260)
        // Alert for shutdown execution errors
        .alert(
            "Shutdown Failed",
            isPresented: Binding(
                get: { viewModel.shutdownError != nil },
                set: { if !$0 { viewModel.shutdownError = nil } }
            ),
            presenting: viewModel.shutdownError
        ) { _ in
            Button("OK", role: .cancel) {
                viewModel.shutdownError = nil
            }
        } message: { error in
            Text(error)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            // Power source icon
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconBackgroundColor)
                    .frame(width: 36, height: 36)
                Image(systemName: viewModel.menuBarIconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconForegroundColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.statusSummary)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Text(viewModel.powerMonitor.powerState.powerSourceDescription)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    if let level = viewModel.powerMonitor.powerState.batteryLevel {
                        Text("·")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Text("\(level)%")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Countdown Section

    private var countdownSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.orange)
                Text("Shutdown Countdown")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text(viewModel.formatTime(viewModel.shutdownManager.remainingSeconds))
                    .font(.system(size: 12, weight: .bold).monospacedDigit())
                    .foregroundStyle(.orange)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.orange.opacity(0.2))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color.orange)
                        .frame(
                            width: geo.size.width * (1.0 - viewModel.shutdownManager.countdownProgress),
                            height: 4
                        )
                        .animation(.linear(duration: 0.9), value: viewModel.shutdownManager.remainingSeconds)
                }
            }
            .frame(height: 4)

            // Cancel button
            Button(action: { viewModel.cancelShutdown() }) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Cancel Shutdown")
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.orange, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.06))
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 0) {
            menuRow(
                icon: viewModel.monitoringEnabled ? "pause.circle" : "play.circle",
                label: viewModel.monitoringEnabled ? "Disable Monitoring" : "Enable Monitoring",
                action: { viewModel.toggleMonitoring() }
            )

            if viewModel.shutdownManager.isCountdownActive {
                menuRow(
                    icon: "xmark.circle",
                    label: "Cancel Shutdown",
                    iconColor: .orange,
                    action: { viewModel.cancelShutdown() }
                )
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - App Actions Section

    private var appActionsSection: some View {
        VStack(spacing: 0) {
            menuRow(icon: "gear", label: "Settings…") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: AppConstants.WindowID.settings)
            }
            menuRow(icon: "info.circle", label: "About Unplugged") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: AppConstants.WindowID.about)
            }
            menuRow(icon: "power", label: "Quit Unplugged", iconColor: .secondary) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Reusable Row

    private func menuRow(
        icon: String,
        label: String,
        iconColor: Color = .primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(iconColor)
                    .frame(width: 16, alignment: .center)
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(MenuRowButtonStyle())
    }

    // MARK: - Derived Colors

    private var iconBackgroundColor: Color {
        if viewModel.shutdownManager.isCountdownActive { return .orange.opacity(0.12) }
        return viewModel.powerMonitor.powerState.isPluggedIn
            ? .green.opacity(0.12)
            : .secondary.opacity(0.1)
    }

    private var iconForegroundColor: Color {
        if viewModel.shutdownManager.isCountdownActive { return .orange }
        return viewModel.powerMonitor.powerState.isPluggedIn ? .green : .secondary
    }
}

// MARK: - MenuRowButtonStyle

/// A button style matching native macOS menu item hover behaviour.
struct MenuRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? Color.accentColor.opacity(0.15)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 5, style: .continuous)
            )
    }
}
