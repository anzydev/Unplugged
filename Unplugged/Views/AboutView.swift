// AboutView.swift
// Unplugged
//
// Minimal About window matching the style of native macOS About panels.

import SwiftUI

// MARK: - AboutView

struct AboutView: View {

    var body: some View {
        VStack(spacing: 0) {
            // Icon area
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(nsColor: .controlAccentColor).opacity(0.8), Color(nsColor: .controlAccentColor)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                    Image(systemName: "bolt.slash.fill")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 4) {
                    Text(AppConstants.appName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("Version \(AppConstants.appVersion) (\(AppConstants.appBuild))")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 32)
            .padding(.bottom, 20)

            Divider()
                .padding(.horizontal, 20)

            // Description
            VStack(spacing: 8) {
                Text("Unplugged monitors your Mac's power source and automatically shuts it down when external power is disconnected.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)

                Text("Copyright © \(AppConstants.copyrightYear) Unplugged Contributors")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 16)

            Divider()
                .padding(.horizontal, 20)

            // Links
            HStack(spacing: 16) {
                Link(destination: URL(string: AppConstants.githubURL)!) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11))
                        Text("GitHub")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(Color.accentColor)
                }

                Text("·")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 12))

                Link(destination: URL(string: "\(AppConstants.githubURL)/blob/main/LICENSE")!) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 11))
                        Text("MIT License")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 14)
        }
        .frame(width: 320)
        .fixedSize()
    }
}
