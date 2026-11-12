// swift-tools-version:5.9
// Core domain package used for fast unit tests (`swift test`, including on Linux/Docker).
// The iOS app target compiles the same `Core` sources directly (see project.yml).
import PackageDescription

let package = Package(
    name: "P100Core",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "P100Core", targets: ["P100Core"])],
    targets: [
        .target(name: "P100Core", path: "Core"),
        .testTarget(name: "P100CoreTests", dependencies: ["P100Core"], path: "CoreTests")
    ]
)
