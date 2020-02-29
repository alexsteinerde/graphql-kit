// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "GraphQLKit",
    products: [
        .library(
            name: "GraphQLKit",
            targets: ["GraphQLKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/alexsteinerde/Graphiti.git", from: "0.12.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "3.0.0"),
    ],
    targets: [
        .target(name: "GraphQLKit", dependencies: ["Vapor", "Graphiti", "Fluent"]),
        .testTarget(name: "GraphQLKitTests",dependencies: ["GraphQLKit"]),
    ]
)
