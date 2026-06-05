// swift-tools-version: 5.9
// Package.swift
// Unplugged
//
// NOTE: This Package.swift is provided for IDE support (syntax highlighting,
// code completion, SwiftLint integration). The canonical build target is the
// Xcode project (Unplugged.xcodeproj). See BUILD_INSTRUCTIONS.md for details.
//
// To open in Xcode via SPM: File → Open → select this Package.swift.
// To build the proper macOS app bundle (with Info.plist, entitlements, etc.),
// use the Xcode project instead.

import PackageDescription

let package = Package(
    name: "Unplugged",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Unplugged", targets: ["Unplugged"])
    ],
    targets: [
        .executableTarget(
            name: "Unplugged",
            path: "Unplugged",
            // Exclude Xcode-only files — not valid SPM resources.
            exclude: [
                "Info.plist",
                "Unplugged.entitlements"
            ],
            // Explicitly list all source directories so SPM finds them.
            sources: [
                "UnpluggedApp.swift",
                "Models",
                "ViewModels",
                "Views",
                "Services",
                "Utilities"
            ],
            swiftSettings: [
                .unsafeFlags(["-strict-concurrency=complete"])
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("UserNotifications")
            ]
        )
    ]
)
