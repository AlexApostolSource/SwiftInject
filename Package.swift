// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftInject",
    platforms: [.macOS(.v11), .iOS(.v15), .tvOS(.v15), .watchOS(.v9)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftInject",
            targets: ["SwiftInject"]
        )
    ],
    targets: [
        // --- SwiftLint Plugin ---
        // Disabled for PRODUCTION builds (avoid forcing consumers to run SwiftLint).
        // Enable this block only for DEVELOPMENT if you want linting during builds.
        /*
         .plugin(
         name: "SwiftInjectSwiftLintBuildToolPlugin",
         capability: .buildTool(),
         path: "Plugins/SwiftInjectSwiftLintBuildToolPlugin"
         ),
         */

        .target(
            name: "SwiftInject"
            // , plugins: [
            //     // SwiftLint plugin attached to this target.
            //     // Disabled for PRODUCTION — enable in DEVELOPMENT only.
            //     .plugin(name: "SwiftInjectSwiftLintBuildToolPlugin")
            // ]
        ),
        .testTarget(
            name: "SwiftInjectTests",
            dependencies: ["SwiftInject"]
            // , plugins: [
            //     // SwiftLint plugin attached to tests.
            //     // Disabled for PRODUCTION — enable in DEVELOPMENT only.
            //     .plugin(name: "SwiftInjectSwiftLintBuildToolPlugin")
            // ]
        )
    ]
)

