# Build Instructions — Unplugged

Complete step-by-step build instructions for developers.

---

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| macOS | 13.0+ (Ventura) | System update |
| Xcode | 15.0+ | [Mac App Store](https://apps.apple.com/app/xcode/id497799835) |
| Apple Developer Account | Free or paid | [developer.apple.com](https://developer.apple.com) |

---

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/anzydev/unplugged.git
cd unplugged

# 2. Generate the Xcode project
/usr/bin/ruby generate_xcodeproj.rb

# 3. Open in Xcode
open Unplugged.xcodeproj
```

Then in Xcode:
1. Set your **Team** in Target → Signing & Capabilities
2. Press **Cmd+R** to build and run

---

## Project Structure

```
battery saver/
├── Unplugged/                      # All Swift source files
│   ├── UnpluggedApp.swift          # App entry point
│   ├── Info.plist                  # Bundle configuration
│   ├── Unplugged.entitlements      # App entitlements
│   ├── Models/                     # Data models
│   ├── ViewModels/                 # MVVM ViewModels
│   ├── Views/                      # SwiftUI Views
│   ├── Services/                   # Core services
│   └── Utilities/                  # Shared utilities
├── Unplugged.xcodeproj/            # Generated Xcode project (DO NOT edit manually)
├── generate_xcodeproj.rb           # Project regeneration script
├── Package.swift                   # SPM file for IDE support
├── project.yml                     # XcodeGen config (alternative)
├── README.md
└── LICENSE
```

---

## Regenerating the Xcode Project

If you add or remove Swift files, regenerate the project:

```bash
/usr/bin/ruby generate_xcodeproj.rb
```

> **Note:** The `Unplugged.xcodeproj` file is generated — do not edit `project.pbxproj` manually. Re-run the script instead.

---

## Build Configurations

| Configuration | Optimization | Debug Info | Use case |
|---|---|---|---|
| **Debug** | None (`-Onone`) | DWARF | Development, debugging |
| **Release** | Full (`-O`) | DWARF + dSYM | Distribution |

---

## Build Settings Reference

Key build settings configured in the generated project:

| Setting | Value |
|---|---|
| `BUNDLE_IDENTIFIER` | `com.anzydev.unplugged` |
| `MACOSX_DEPLOYMENT_TARGET` | `13.0` |
| `ARCHS` | `arm64 x86_64` |
| `SWIFT_VERSION` | `5.9` |
| `ENABLE_APP_SANDBOX` | `NO` |
| `ENABLE_HARDENED_RUNTIME` | `YES` |
| `CODE_SIGN_ENTITLEMENTS` | `Unplugged/Unplugged.entitlements` |
| `OTHER_LDFLAGS` | `-framework IOKit -framework ServiceManagement -framework UserNotifications` |
| `SWIFT_STRICT_CONCURRENCY` | `complete` |

---

## Entitlements

The app is non-sandboxed by design. The entitlements file contains:

| Entitlement | Value | Purpose |
|---|---|---|
| `com.apple.security.app-sandbox` | `false` | Non-sandboxed execution |
| `com.apple.security.automation.apple-events` | `true` | AppleScript shutdown via System Events |

---

## Required Permissions at Runtime

| Permission | When Requested | Required? |
|---|---|---|
| Automation → System Events | First shutdown attempt | **Yes** — without it, shutdown cannot execute |
| Notifications | App first launch | No — app works without notifications |

---

## Frameworks Used

| Framework | Usage |
|---|---|
| `SwiftUI` | All views, `MenuBarExtra`, `Window` scenes |
| `AppKit` | `NSAppleScript` (shutdown), `NSSound` (beep) |
| `IOKit.ps` | Power source change notifications and state reads |
| `ServiceManagement` | `SMAppService` launch-at-login |
| `UserNotifications` | `UNUserNotificationCenter` local notifications |
| `Combine` | Reactive bindings in `AppViewModel` |
| `Foundation` | `UserDefaults`, `Timer`, `Process` |

---

## Troubleshooting

### Build fails with "Missing entitlement"
Ensure the entitlements file path in Build Settings matches exactly:
```
CODE_SIGN_ENTITLEMENTS = Unplugged/Unplugged.entitlements
```

### Shutdown doesn't work
1. Check System Settings → Privacy & Security → Automation
2. Ensure "Unplugged" has access to "System Events"
3. If missing, delete the entry and re-run the app to trigger the prompt again

### Notifications don't appear
1. Check System Settings → Notifications → Unplugged
2. Ensure "Allow Notifications" is enabled
3. In the app Settings, ensure "Enable Notifications" is toggled on

### Menu bar icon doesn't appear
The app runs as `LSUIElement = true` (background agent with no Dock icon). The menu bar icon should appear immediately after launch. If it doesn't, check the Console app for crash logs with the identifier `com.anzydev.unplugged`.

### "No developer tools were found" when running generate_xcodeproj.rb
Use the full path to Ruby:
```bash
/usr/bin/ruby generate_xcodeproj.rb
```

---

## Distribution

Unplugged is intended for direct distribution (GitHub releases, Homebrew Cask). It is **not** App Store compatible due to its non-sandboxed entitlements.

For notarisation (recommended for distribution):
```bash
# Archive in Xcode: Product → Archive
# Then: Organizer → Distribute App → Developer ID → Notarize
```

---

## Contributing

See [README.md](README.md) for contributing guidelines.
