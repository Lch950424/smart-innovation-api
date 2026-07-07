// swift-tools-version: 5.6
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "AdminApp",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "AdminApp",
            targets: ["App"],
            bundleIdentifier: "com.lch.AdminApp",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(paper: .regular),
            accentColor: .presetColor(.indigo),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "App",
            path: "App"
        )
    ]
)
