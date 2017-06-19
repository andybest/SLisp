// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "SLisp",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SLispCore",
            targets: ["SLispCore"]),
        .executable(
            name: "SLisp",
            targets: ["SLisp"]),
    ],
    dependencies: [
        .package(url: "https://github.com/andybest/linenoise-swift", from: "0.0.1")
    ],
    targets: [
        .target(
            name: "SLisp",
            dependencies: ["SLispCore"]),
        .target(
            name: "SLispCore",
            dependencies: ["LineNoise"]),
        .testTarget(
            name: "SLispCoreTests")
    ]
)
