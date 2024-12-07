// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Observe",
	platforms: [
		.iOS(.v12),
		.macOS(.v12)
	],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Observe",
            targets: ["Observe"]),
	],
	dependencies: [
		// Add your dependencies here
		.package(
			url: "https://github.com/piyush-2450/Collections.git",
			branch: "main"
		)
	],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Observe",
		dependencies: ["Collections"]),
        .testTarget(
            name: "ObserveTests",
            dependencies: ["Observe"]
        ),
    ]
)
