// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "AINotesCore",
    platforms: [
        .iOS("26.0"),
        .macOS("26.0"),
        .watchOS("26.0"),
        .tvOS("26.0")
    ],
    products: [
        .library(
            name: "AINotesCore",
            targets: ["AINotesCore"]),
    ],
    dependencies: [
        .package(path: "../NUSModsClient")
    ],
    targets: [
        .target(
            name: "AINotesCore",
            dependencies: ["NUSModsClient"])
    ]
)
