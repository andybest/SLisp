// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "SLisp",
    targets: [
        Target(name: "SLisp", dependencies: ["SLispCore"]),
        Target(name: "SLispCore")
    ]
)
