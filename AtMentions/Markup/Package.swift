// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Markup",
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "Markup",
      targets: ["Markup"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-markdown", .upToNextMajor(from: "0.7.1"))
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "Markup",
      dependencies: [
        .product(name: "Markdown", package: "swift-markdown")
      ]
    ),
    .testTarget(
      name: "MarkupTests",
      dependencies: ["Markup"]
    ),
  ]
)
