// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DNSWidget",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "DNSWidget",
            path: "Sources",
            exclude: [
                "Widget",
                "App/Info.plist",
                "App/DNSWidget.entitlements",
                "Widget/Info.plist",
                "Widget/DNSWidgetExtension.entitlements",
            ]
        )
    ]
)
