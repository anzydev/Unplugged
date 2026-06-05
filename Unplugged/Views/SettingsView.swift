// SettingsView.swift
// Unplugged
//
// Settings window with three tabs: General, Shutdown, Notifications.
// Uses native SwiftUI Form + Section — no custom controls.
// All state is persisted via @AppStorage / AppViewModel @Published vars.

import SwiftUI
import ServiceManagement

// MARK: - SettingsView

struct SettingsView: View {

    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        TabView {
            GeneralTab(viewModel: viewModel)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(0)

            ShutdownTab(viewModel: viewModel)
                .tabItem {
                    Label("Shutdown", systemImage: "power")
                }
                .tag(1)

            NotificationsTab(viewModel: viewModel)
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
                .tag(2)
        }
        .frame(width: 420, height: 280)
    }
}

// MARK: - General Tab

private struct GeneralTab: View {

    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch at Login")
                            .font(.body)
                        Text("Start Unplugged automatically when you log in.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: launchAtLoginBinding)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Monitoring")
                            .font(.body)
                        Text("Unplugged watches for charger disconnects when enabled.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $viewModel.monitoringEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            } header: {
                Text("General")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // Bridges LoginItemManager → Toggle binding
    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { viewModel.loginItemManager.isEnabled },
            set: { newValue in
                let result = viewModel.loginItemManager.setEnabled(newValue)
                if case .failure(let msg) = result {
                    print("[Settings] Launch at Login toggle failed: \(msg)")
                }
            }
        )
    }
}

// MARK: - Shutdown Tab

private struct ShutdownTab: View {

    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Countdown Duration")
                            .font(.body)
                        Text("Time before shutdown when charger is disconnected.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("", selection: countdownDurationBinding) {
                        ForEach(CountdownDuration.allCases) { duration in
                            Text(duration.displayLabel)
                                .tag(duration)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 120)
                }
            } header: {
                Text("Shutdown Timer")
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Label {
                        Text("Unsaved work may be lost when a shutdown countdown completes.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
            } header: {
                Text("Safety Warning")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var countdownDurationBinding: Binding<CountdownDuration> {
        Binding(
            get: { viewModel.countdownDuration },
            set: { viewModel.countdownDurationRaw = $0.rawValue }
        )
    }
}

// MARK: - Notifications Tab

private struct NotificationsTab: View {

    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        Form {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Notifications")
                            .font(.body)
                        Text("Show banners for power connect and disconnect events.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $viewModel.notificationsEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Countdown Notifications")
                            .font(.body)
                        Text("Send a notification as shutdown approaches.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $viewModel.countdownNotificationsEnabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .disabled(!viewModel.notificationsEnabled)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Play Sound Before Shutdown")
                            .font(.body)
                        Text("Play a system alert sound in the final \(AppConstants.imminentShutdownThreshold) seconds.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $viewModel.playSoundBeforeShutdown)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .disabled(!viewModel.notificationsEnabled)
                }
            } header: {
                Text("Notifications")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
