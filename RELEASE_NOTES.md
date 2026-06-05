# 🚀 Unplugged v1.0.0 — Initial Release

Welcome to the initial release of **Unplugged**! 

Unplugged is a native macOS menu bar utility that monitors your Mac's power source and automatically shuts down the system when external power is disconnected. This is particularly useful for headless servers, shared workstations, or Mac minis/studios on UPS systems.

---

## 🌟 Key Features

* **Set-and-Forget Monitoring**: Automatically starts monitoring on launch and runs cleanly in the macOS menu bar.
* **Smart Countdown & Cancel**: Configurable countdown (10s, 30s, 1m, 5m). Reconnecting power or clicking "Cancel Shutdown" stops the process instantly.
* **Low System Footprint**: Event-driven hardware observation using native IOKit APIs (no constant CPU polling).
* **Launch at Login**: Simple toggle to register as a system service.
* **Rich Notifications**: Native banner updates for power status changes, imminent shutdowns, and restored states.

---

## 📦 How to Install

1. Download the attached **`Unplugged.dmg`** below.
2. Double-click the downloaded file to mount it.
3. Drag the **Unplugged** icon into your **Applications** folder shortcut.
4. Launch **Unplugged** from your Applications folder.

---

## 🔒 Setup & Permissions

* **Automation**: The first time a shutdown is triggered, macOS will ask for permission to allow Unplugged to control "System Events". This is required to execute a graceful system shutdown.
* **Notifications**: Click "Allow" when prompted on launch to receive visual updates.

---

## 🛠️ Build Details
* Built for macOS 13.0+ (Ventura, Sonoma, Sequoia)
* Supports Apple Silicon (M1/M2/M3/M4) and Intel (x86_64) architectures.
