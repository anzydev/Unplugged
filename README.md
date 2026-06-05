# 🔌 Unplugged

**A lightweight, native macOS menu bar utility that automatically shuts down your Mac when external power is disconnected.**

[![macOS 13+](https://img.shields.io/badge/macOS-13.0%2B-blue?style=flat-square&logo=apple)](https://developer.apple.com/macos/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift)](https://developer.apple.com/swift/)
[![License MIT](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)

---

## ⚡ Overview

Unplugged runs silently in the background and monitors your Mac's power source. When your charger is disconnected, it triggers a configurable countdown timer. If power is restored, the countdown cancels automatically. If the timer reaches zero, your Mac performs a graceful system shutdown.

> ⚠️ **IMPORTANT: Unsaved work may be lost.**  
> When the countdown completes, your Mac will shut down. Make sure to save your work frequently when monitoring is enabled, or click **Cancel Shutdown** in the menu bar if you unplugged on purpose.

---

## ✨ Features

- **Native Menu Bar Interface** — Stays out of the way; shows a dynamic countdown when active.
- **Launch at Login** — Built-in preference to start automatically.
- **Zero CPU Waste** — Uses event-driven IOKit APIs rather than polling.
- **Configurable Timer** — Choose between 10s, 30s, 1m, or 5m countdowns.
- **Local Notifications** — Alerts you when power disconnects, when shutdown is imminent, or if power is restored.
- **Graceful Shutdown** — Executes system shutdown via Apple Events (requires non-sandboxed permission).

---

## 📦 Installation

### The Quick Way (Recommended)
1. Download `Unplugged.dmg` from the latest [GitHub Release]().
2. Double-click the DMG.
3. Drag **Unplugged.app** into the **Applications** folder shortcut.

### Building From Source
If you prefer to build the app yourself:
```bash
# 1. Generate the Xcode project
/usr/bin/ruby generate_xcodeproj.rb

# 2. Open in Xcode
open Unplugged.xcodeproj
```
*Note: Set your Development Team under **Target → Signing & Capabilities** in Xcode before running (Cmd+R).*

---

## 🔒 Permissions

To function correctly, the app requires:
1. **Automation (Required)**: On the first shutdown attempt, macOS will prompt to allow "Unplugged" to control "System Events". This is required to execute the shutdown command.
2. **Notifications (Optional)**: Requested on first launch to deliver status alerts.

---

## 🛠️ Tech Stack & Architecture

The project is built using modern Apple frameworks:
* **SwiftUI** for the menu bar popover and preferences window.
* **Combine & async/await** for reactive event routing.
* **IOKit Power Sources API** for hardware monitoring.
* **ServiceManagement (`SMAppService`)** for launching at login.
* **AppleScript (`NSAppleScript`)** for triggering the system shutdown.

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
