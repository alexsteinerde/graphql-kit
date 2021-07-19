// swift-tools-version:5.2

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
        .package(url: "https://github.com/GraphQLSwift/Graphiti.git", from: "0.24.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
    ],
    targets: [
        .target(name: "GraphQLKit",
                dependencies: [
                    .product(name: "Vapor", package: "vapor"),
                    .product(name: "Graphiti", package: "Graphiti"),
                    .product(name: "Fluent", package: "fluent")
                ]
        ),
        .testTarget(name: "GraphQLKitTests",
                    dependencies: [
                        .target(name: "GraphQLKit"),
                        .product(name: "XCTVapor", package: "vapor")
                    ]
        ),
    ]
)
