// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftInject",
    platforms: [.macOS(.v11), .iOS(.v15), .tvOS(.v15), .watchOS(.v9)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftInject",
            targets: ["SwiftInject"])
    ],
    targets: [
        .plugin(
            name: "SwiftInjectSwiftLintBuildToolPlugin",
            capability: .buildTool(),
            path: "Plugins/SwiftInjectSwiftLintBuildToolPlugin"
        ),
        .target(
            name: "SwiftInject", plugins: [
                .plugin(name: "SwiftInjectSwiftLintBuildToolPlugin")
            ]),
        .testTarget(
            name: "SwiftInjectTests",
            dependencies: ["SwiftInject"],
            plugins: [
                .plugin(name: "SwiftInjectSwiftLintBuildToolPlugin")
            ]
        )
    ]
)
