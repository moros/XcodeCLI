// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CLI",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "CLI", targets: ["CLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tadija/AEXML.git", .upToNextMinor(from: "4.7.0")),
        .package(url: "https://github.com/orchetect/PListKit.git", from: "2.0.0"),
        .package(path: "../XcodeProj"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "CLI", dependencies: [
            .product(name: "AEXML", package: "AEXML"),
            .product(name: "PListKit", package: "PListKit"),
            .product(name: "XcodeProj", package: "XcodeProj"),
        ]),
        .testTarget(name: "CLITests", dependencies: ["CLI"]),
    ]
)
