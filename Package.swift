// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "GraphQLKit",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "GraphQLKit",
            targets: ["GraphQLKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/alexsteinerde/Graphiti.git", from: "0.22.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
//        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0-beta"),
    ],
    targets: [
        .target(name: "GraphQLKit", dependencies: ["Vapor", "Graphiti"]),
        .testTarget(name: "GraphQLKitTests",dependencies: ["GraphQLKit", "XCTVapor"]),
    ]
)
