import ProjectDescription

let project = Project(
  name: "SWAPI",
  settings: .settings(
    base: [
      "SWIFT_VERSION": "6.0"
    ]
  ),
  targets: [
    .target(
      name: "SwiftUI",
      destinations: .init(arrayLiteral: .iPad, .iPad, .mac, .appleVision),
      product: .app,
      bundleId: "dev.tuist.SWAPI-SwiftUI",
      infoPlist: .extendingDefault(
        with: [
          "UILaunchScreen": [
            "UIColorName": "",
            "UIImageName": "",
          ]
        ]
      ),
      buildableFolders: [
        "SwiftUI/Sources",
        "SwiftUI/Resources",
      ],
      dependencies: [
        .target(name: "API"),
        .target(name: "Persistence"),
      ]
    ),
    .target(
      name: "SwiftUI-Tests",
      destinations: .init(arrayLiteral: .iPad, .iPad, .mac, .appleVision),
      product: .unitTests,
      bundleId: "dev.tuist.SwiftUI-Tests",
      infoPlist: .default,
      buildableFolders: [
        "SwiftUI/Tests"
      ],
      dependencies: [.target(name: "SwiftUI")]
    ),
    .target(
      name: "API",
      destinations: .init(arrayLiteral: .iPad, .iPad, .mac, .appleVision),
      product: .framework,
      bundleId: "dev.tuist.API",
      infoPlist: .default,
      buildableFolders: [
        "API/Sources",
        "API/Resources",
      ],
      dependencies: []
    ),
    .target(
      name: "APITests",
      destinations: .init(arrayLiteral: .iPad, .iPad, .mac, .appleVision),
      product: .unitTests,
      bundleId: "dev.tuist.APITests",
      infoPlist: .default,
      buildableFolders: [
        "API/Tests"
      ],
      dependencies: [.target(name: "API")]
    ),
    .target(
      name: "Persistence",
      destinations: .init(arrayLiteral: .iPad, .iPad, .mac, .appleVision),
      product: .framework,
      bundleId: "dev.tuist.Persistence",
      infoPlist: .default,
      buildableFolders: [
        "Persistence/Sources",
        "Persistence/Resources",
      ],
      dependencies: [
        .external(name: "SQLiteData"),
        .target(name: "API"),
      ]
    ),
    .target(
      name: "PersistenceTests",
      destinations: .init(arrayLiteral: .iPad, .iPad, .mac, .appleVision),
      product: .unitTests,
      bundleId: "dev.tuist.PersistenceTests",
      infoPlist: .default,
      buildableFolders: [
        "Persistence/Tests"
      ],
      dependencies: [.target(name: "Persistence")]
    ),
  ]
)
